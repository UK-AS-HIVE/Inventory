Inventory.before.insert (userId, doc) ->
  now = new Date()
  doc.enteredAtTimestamp = now
  doc.enteredByUserId = userId
  Buildings.upsert { building: doc.building }, { $set: { lastUse: now } }
  Models.upsert { model: doc.model }, { $set: { lastUse: now } }

Inventory.before.upsert (userId, selector, modifier, options) ->
  now = new Date()
  modifier.$setOnInsert.enteredAtTimestamp = now
  modifier.$setOnInsert.enteredByUserId = userId
  if modifier.$set.building?
    Buildings.upsert { building: modifier.$set.building }, { $set: { lastUse: now } }
  if modifier.$set.model?
    Models.upsert { model: modifier.$set.model }, { $set: { lastUse: now } }

Inventory.after.insert (userId, doc) ->
  if doc
    Job.push new WarrantyLookupJob
      inventoryId: doc._id

Inventory.after.update (userId, doc, fieldNames, modifier, options) ->
  if @previous.serialNo != doc.serialNo
    Job.push new WarrantyLookupJob
      inventoryId: doc._id

  if fieldNames?.indexOf('attachments') > -1
    Inventory.direct.update doc._id,
      $set:
        attachmentPurposes: doc.attachments.map (a) -> a.purpose

Inventory.before.update (userId, doc, fieldNames, modifier, options) ->
  _.each fieldNames, (fn) ->
    if fn is 'attachments'
      otherId = modifier.$addToSet?.attachments.fileId || modifier.$pull?.attachments.fileId
      filename = FileRegistry.findOne(otherId)?.filename
      Changelog.insert
        itemId: doc._id
        field: 'attachments'
        type: 'attachment'
        otherId: otherId
        oldValue: if modifier.$pull? then filename
        newValue: if modifier.$addToSet? then filename
        timestamp: new Date()
        userId: userId
        username: Meteor.users.findOne(userId)?.username
    else
      if _.isString doc[fn]
        oldValue = escape(doc[fn])
        newValue = escape(modifier.$set[fn])
      unless oldValue is newValue
        Changelog.insert
          itemId: doc._id
          field: fn
          type: 'field'
          oldValue: oldValue
          newValue: newValue
          timestamp: new Date()
          userId: userId
          username: Meteor.users.findOne(userId)?.username

