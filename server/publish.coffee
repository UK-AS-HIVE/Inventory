
Meteor.publish 'userData', ->
  Meteor.users.find {_id: @userId}

Meteor.publish 'allUserData', ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1, 'physicalDeliveryOfficeName': 1, 'status.online': 1, 'status.idle': 1}}

Meteor.publish 'consumables', (filter, sortKey, sortDir, page) ->
  unless Roles.userIsInRole @userId, 'admin'
    throw new Meteor.Error(403, "Only admins may access consumables")

  sort = {}
  sort[sortKey] = sortDir
  skip = 20*page
  Counts.publish this, 'consumablesCount', Consumables.find(filter)
  Consumables.find(filter, {fields: {history: 0}, sort: sort, skip: skip, limit: 20})

Meteor.publish 'consumableHistory', (consumableId) ->
  unless Roles.userIsInRole @userId, 'admin'
    throw new Meteor.Error(403, "Only admins may access consumables")
  Consumables.find consumableId

Meteor.publishComposite 'inventory', (filter, options) ->
  filter = filter || {}
  dm = Roles.getGroupsForUser(@userId, 'departmentManager')
  if dm.length
    filter.department = dm[0]
  else unless Roles.userIsInRole @userId, 'admin'
    # Non-admin/DM users can only view their own items.
    filter.owner = Meteor.users.findOne(@userId)?.username

  # TODO: this hack is needed because Mongo lacks a "nulls first"/"nulls last" option...
  # https://jira.mongodb.org/browse/SERVER-153
  filterWithNoNull = if options.sort?.shipDate
      $and: [
        shipDate: $ne: null
        filter
      ]
    else
      filter

  [itemSet, facets] = Inventory.findWithFacets filterWithNoNull, options
  itemSet = _.pluck itemSet.fetch(), '_id'

  if itemSet.length < options.limit
    options.limit -= itemSet.length
    itemSet = itemSet.concat (_.pluck Inventory.find({$and: [filter, shipDate: null]}, options).fetch(), '_id')
  {
    find: ->
      Counts.publish this, 'inventoryCount', Inventory.find(filter), { noReady: true }
      Inventory.find { _id: { $in: itemSet } }
    children: [
      {
        find: (item) ->
          ids = _.pluck item.attachments, 'fileId' # not reactive
          FileRegistry.find { _id: { $in: ids } }
      }
      {
        find: -> facets
      }
    ]
  }

Meteor.publishComposite 'newInventory', (filter, time) ->
  if not filter then filter = {}
  _.extend filter, { enteredAtTimestamp: { $gt: time } }

  dm = Roles.getGroupsForUser(@userId, 'departmentManager')
  if dm.length
    filter.department = dm[0]
  else unless Roles.userIsInRole @userId, 'admin'
    filter.owner = Meteor.users.findOne(@userId)?.username

  {
    find: ->
      Inventory.find filter
    children: [
      {
        find: (item) ->
          ids = _.pluck item.attachments, 'fileId'
          FileRegistry.find { _id: { $in: ids } }
      }
    ]
  }


Meteor.publishComposite 'inventorySet', (set) ->
  if not set then set = []
  filter = { _id: { $in: set } }
  dm = Roles.getGroupsForUser(@userId, 'departmentManager')
  if dm.length
    filter.department = dm[0]
  else unless Roles.userIsInRole @userId, 'admin'
    filter.owner = Meteor.users.findOne(@userId).username
  {
    find: ->
      Inventory.find filter
    children: [
      {
        find: (item) ->
          ids = _.pluck item.attachments, 'fileId'
          FileRegistry.find { _id: { $in: ids } }
      }
    ]
  }

Meteor.publish 'checkoutHistory', (assetId) ->
  if Roles.userIsInRole @userId, 'admin'
    Checkouts.find { assetId: assetId }

Meteor.publishComposite 'checkouts', (checkoutFilter, inventoryFilter, options) ->
  _.extend inventoryFilter, { checkout: true }

  if checkoutFilter
    # checkoutFilter filters for *availability*, so if checkouts exist in this range, we filter the item *out*
    # might be cleaner to pass in startDate and endDate explicitly, form the filter here?
    ids = _.pluck Checkouts.find(checkoutFilter).fetch(), 'assetId'
    _.extend inventoryFilter, { _id: { $nin: ids } }

  [itemSet, facets] = Inventory.findWithFacets inventoryFilter, options
  itemSet = _.pluck itemSet.fetch(), '_id'
  aWeekAgo = moment().subtract(1, 'weeks').toDate()
  today = moment().hours(0).minutes(0).seconds(0).toDate()
  {
    find: ->
      Counts.publish this, 'checkoutCount', Inventory.find(inventoryFilter), { noReady: true }
      Inventory.find { _id: { $in: itemSet } }
    children: [

      {
        find: (item) ->
          ids = _.pluck item.attachments, 'fileId' # not reactive
          FileRegistry.find { _id: { $in: ids } }
      }

      # Checkout events after a week ago, as well as any item that has been checked out and not returned.
      # TODO: How do we view checkout history?
      {
        find: (item) ->

          fields = {}
          unless Roles.userIsInRole @userId, 'admin'
            fields = { fields: { assignedTo: 0, 'approver.approverId': 0 } }
          Checkouts.find {
            assetId: item._id
            $or: [
              { 'schedule.timeReserved': { $gte: aWeekAgo } }
              { 'schedule.expectedReturn': { $gte: aWeekAgo } }
              { $and: [
                { 'schedule.timeReserved': { $exists: true } }
                { 'schedule.expectedReturn': { $exists: false } }
              ] }
              { $and: [
                { 'schedule.timeCheckedOut': { $exists: true } }
                { 'schedule.timeReturned': { $exists: false } }
                { 'schedule.expectedReturn': { $lt: today } }
              ] }
            ]
          }, fields
      }
      # Secondary publish for non-admin users to be able to see which checkouts are their own
      {
        find: (item) ->
          Checkouts.find
            assignedTo: @userId
            assetId: item._id
            $or: [
              { 'schedule.timeReserved': { $gte: aWeekAgo } }
              { 'schedule.expectedReturn': { $gte: aWeekAgo } }
              { $and: [
                { 'schedule.timeReserved': { $exists: true } }
                { 'schedule.expectedReturn': { $exists: false } }
              ] }
              { $and: [
                { 'schedule.timeCheckedOut': { $exists: true } }
                { 'schedule.timeReturned': { $exists: false } }
                { 'schedule.expectedReturn': { $lt: today } }
              ] }
            ]
      }

      {
        find: ->
          facets
      }

    ]
  }

Meteor.publish 'item', (itemId) ->
  if Roles.userIsInRole @userId, 'admin'
    [ Inventory.find({ _id: itemId }), Changelog.find({ itemId: itemId }), Deliveries.find({assetId: itemId}) ]
  else if Inventory.findOne(itemId).owner is Meteor.users.findOne(@userId).username
    Inventory.find { _id: itemId }

Meteor.publish 'upcomingAndOverdueCounts', ->
  yesterday = moment().add(-1, 'days').hours(0).minutes(0).seconds(0).toDate()
  weekFromNow = moment().add(7, 'days').hours(23).minutes(59).seconds(59).toDate()
  upcomingCursor = Checkouts.find({
    'schedule.timeReturned': { $exists: false } # Don't count already returned items.
    $or: [
      'schedule.timeReserved': { $gte: yesterday, $lte: weekFromNow }
      'schedule.expectedReturn': { $gte: yesterday, $lte: weekFromNow }
    ]
  })
  Counts.publish this, 'upcomingCount', upcomingCursor, {noReady: true}

  today = moment().hours(0).minutes(0).seconds(0).toDate()
  overdueCursor = Checkouts.find({
    'schedule.expectedReturn': { $lt: today }
    'schedule.timeReturned': { $exists: false }
    'schedule.timeCheckedOut': { $exists: true }
  })
  Counts.publish this, 'overdueCount', overdueCursor, {noReady: true}

  return []



Meteor.publishComposite 'upcomingItems', ->
  # Publish checkouts that are either expected to be picked up between yesterday and next week, or returned in the same time frame.
  yesterday = moment().add(-1, 'days').hours(0).minutes(0).seconds(0).toDate()
  weekFromNow = moment().add(7, 'days').hours(23).minutes(59).seconds(59).toDate()
  checkoutFilter = {
    'schedule.timeReturned': { $exists: false } # No need to publish already returned items.
    $or: [
      'schedule.timeReserved': { $gte: yesterday, $lte: weekFromNow }
      'schedule.expectedReturn': { $gte: yesterday, $lte: weekFromNow }
    ]
  }
  ids = _.pluck Checkouts.find(checkoutFilter).fetch(), 'assetId'
  {
    find: ->
      Inventory.find { checkout: true }
    children: [
      {
        find: (item) ->
          newFilter = _.extend checkoutFilter, { assetId: item._id }
          Checkouts.find newFilter
      }
    ]
  }

Meteor.publishComposite 'overdueItems', ->
  # Publish checkouts that are overdue
  today = moment().hours(0).minutes(0).seconds(0).toDate()
  checkoutFilter =
    'schedule.expectedReturn': { $lt: today }
    'schedule.timeReturned': { $exists: false }
    'schedule.timeCheckedOut': { $exists: true }
  ids = _.pluck Checkouts.find(checkoutFilter).fetch(), 'assetId'
  find: ->
    Inventory.find { checkout: true, _id: {$in: ids} }
  children: [
    find: (item) ->
      newFilter = _.extend checkoutFilter, { assetId: item._id }
      Checkouts.find newFilter
  ]

Meteor.publish 'models', ->
  if Roles.userIsInRole @userId, 'admin'
    Models.find {}, { limit: 100 }
Meteor.publish 'buildings', ->
  if Roles.userIsInRole @userId, 'admin'
    Buildings.find {}, { limit: 100 }
