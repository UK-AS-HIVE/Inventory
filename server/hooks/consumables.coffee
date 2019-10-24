Consumables.before.insert (userId, doc) ->
  doc.history = [
    timestamp: new Date()
    username: Meteor.users.findOne(userId).username
  ]

Consumables.before.update (userId, doc, fieldNames, modifier, options) ->
  changes = []
  console.log 'consumables.before.update', doc, fieldNames, modifier 

  #note = modifier.$push?.history

  _.each fieldNames, (fn) =>
    oldValue = doc[fn]
    newValue = modifier.$set[fn]
    #if _.isString doc[fn]
    #  oldValue = escape(doc[fn])
    #  newValue = escape(modifier.$set[fn])
    if oldValue isnt newValue
      changes.push
        field: fn
        oldValue: oldValue
        newValue: newValue
  console.log 'changes', changes
  #console.log 'note', note
  if changes.length #or note
    credit =
      username: Meteor.users.findOne(userId).username
      timestamp: new Date()
    modifier.$push = modifier.$push || {}
    console.log 'changes', changes
    #if note
    #  changes.push note
    history = _.map changes, (c) -> _.extend c, credit
    console.log 'history', history
    modifier.$push.history =
      $each: history
    console.log modifier

