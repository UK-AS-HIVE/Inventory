Meteor.users.allow
  insert: -> false
  update: (userId, doc, fields, modifier) ->
    doc._id is userId and _.intersection(['_id', 'department', 'displayName', 'employeeNumber', 'givenName', 'memberOf', 'services', 'status', 'title', 'username', 'roles'], fields).length is 0
  remove: -> false

Inventory.allow
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, 'admin')
  update: (userId, doc, fields, modifier) ->
    Roles.userIsInRole(userId, 'admin') and _.intersection(fields, [ 'notes', 'enteredByUserId', 'enteredAtTimestamp' ]).length is 0
  remove: -> false


Checkouts.allow
  insert: (userId, doc) -> !(doc.approval) or doc.approval?.approverId is (userId or null)
  update: (userId, doc, fields, modifier) ->
    if !Roles.userIsInRole userId, 'admin'
      return false
    if _.intersection(['_id', 'assetId', 'assignedTo'], fields).length
      return false
    if modifier.$set?['approval.approverId'] and modifier.$set?['approval.approverId'] isnt userId
      return false

    true
  remove: -> false

Consumables.allow
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, 'admin')
  update: (userId, doc, fields, modifier) ->
    Roles.userIsInRole(userId, 'admin')
  remove: -> false

