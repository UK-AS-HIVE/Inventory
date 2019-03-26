checkoutFilters = ->
  startDate = null
  endDate = null
  if Iron.query.get('startDate')
    startDate = new Date Iron.query.get('startDate')
  if Iron.query.get('endDate')
    endDate = new Date Iron.query.get('endDate')
  {
    $or: [
      { $and: [
        { 'schedule.timeReserved': { $gte: startDate } }
        { 'schedule.timeReserved': { $lte: endDate } }
      ] },
      { $and: [
        { 'schedule.expectedReturn': { $gte: startDate } }
        { 'schedule.expectedReturn': { $lt: endDate } }
      ] }
    ]
  }

inventoryFilters = ->
  filters = {
    deviceType: Iron.query.get 'deviceType'
  }

  for k,v of filters
    if _.isUndefined(v) then delete filters[k]
  return filters

Template.checkoutsAdmin.onCreated ->
  @subscribe 'upcomingItems'
  @subscribe 'overdueItems'

Template.checkoutsAdmin.helpers
  overdueItemsCount: ->
    today = moment().hours(0).minutes(0).seconds(0).toDate()
    Checkouts.find({
      'schedule.expectedReturn': { $lt: today }
      'schedule.timeReturned': { $exists: false }
      'schedule.timeCheckedOut': { $exists: true }
    }).count()
  upcomingItemsCount: ->
    # Count published checkouts between yesterday and a week from today for display.
    yesterday = moment().add(-1, 'days').hours(0).minutes(0).seconds(0).toDate()
    weekFromNow = moment().add(7, 'days').hours(23).minutes(59).seconds(59).toDate()
    checkoutFilter = {
      'schedule.timeReturned': { $exists: false } # Don't count already returned items.
      $or: [
        'schedule.timeReserved': { $gte: yesterday, $lte: weekFromNow }
        'schedule.expectedReturn': { $gte: yesterday, $lte: weekFromNow }
      ]
    }
    Checkouts.find(checkoutFilter).count()
  settings: ->
    {
      fields: ['name', 'model',
        { key: 'checkedOutTo', label: 'Checked Out To', tpl: Template.checkedOutToField, sortable: false }
        { key: 'status', label: 'Status', tpl: Template.checkoutStatusField, sortable: false }
        { key: 'actions', label: 'Actions', tpl: Template.checkoutActionsAdminField, sortable: false }
      ]
      inventoryFilters: inventoryFilters
      checkoutFilters: checkoutFilters
    }

