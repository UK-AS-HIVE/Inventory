Meteor.methods
  checkUsername: (username) ->
    # If our user is already in Meteor.users, cool. If not, query LDAP and insert into Meteor.users.
    user = Meteor.users.findOne {username: username.toLowerCase()}
    if user?
      return user._id
    else
      client = LDAP.createClient Meteor.settings.ldap.serverUrl
      LDAP.bind client, Meteor.settings.ldapDummy.username, Meteor.settings.ldapDummy.password
      userObj = LDAP.search client, username
      unless userObj?
        return false
      else
        user = Meteor.users.findOne {username: username.toLowerCase()}
        if user
          userId = user._id
          Meteor.users.update(userId, {$set: userObj})
        else
          userId = Meteor.users.insert(userObj)
        return userId

  checkPassword: (username, password) ->
    # Check a username and password against LDAP without Meteor login.
    client = LDAP.createClient Meteor.settings.ldap.serverUrl
    LDAP.bind client, username, password
    return LDAP.search(client, username)?

 
  deleteItem: (itemId) ->
    if Roles.userIsInRole @userId, 'admin'
      Inventory.remove(itemId)
      Changelog.remove { itemId: itemId }
      Checkouts.remove { assetId: itemId }

  recordItemDelivery: (username, password, asset) ->
    if Roles.userIsInRole @userId, 'admin'
      client = LDAP.createClient Meteor.settings.ldap.serverUrl
      LDAP.bind client, username, password
      if LDAP.search(client, username)?
        unless _.isArray(asset) then asset = [ asset ]
        _.each asset, (i) =>
          Deliveries.insert {
            assetId: i
            deliveredByUserId: @userId
            deliveredTo: username
            deliveredToUserId: Meteor.users.findOne({username: username})?._id || null
            timestamp: new Date()
          }
          Inventory.update i, { $set: { delivered: true } }
      else
        throw new Meteor.Error('Invalid credentials.')

  recordItemDeliveryWithoutUser: (assetId) ->
    # Recording item as delivered without an actual user for bulk operations
    if Roles.userIsInRole @userId, 'admin'
      Deliveries.insert {
        assetId: assetId
        deliveredByUserId: @userId
        timestamp: new Date()
      }

      Inventory.update assetId, { $set: { delivered: true } }
      Changelog.insert
        itemId: assetId
        field: 'delivered'
        type: 'field'
        oldValue: 'false'
        newValue: 'true'
        timestamp: new Date()
        userId: @userId
        username: Meteor.users.findOne(@userId)?.username

  setAsNotDelivered: (assetId) ->
    # Mark an item as undelivered, so a new delivery can be recorded. Record a changelog event for the update
    if Roles.userIsInRole @userId, 'admin'
      Inventory.update assetId, { $set: { delivered: false } }
      Changelog.insert
        itemId: assetId
        field: 'delivered'
        type: 'field'
        oldValue: 'true'
        newValue: 'false'
        timestamp: new Date()
        userId: @userId
        username: Meteor.users.findOne(@userId)?.username

  cancelCheckout: (checkoutId) ->
    if Roles.userIsInRole @userId, 'admin'
      checkout = Checkouts.findOne(checkoutId)
      user = Meteor.users.findOne(checkout.assignedTo)
      item = Inventory.findOne(checkout.assetId)
      console.log "User #{@userId} cancelling reservation: #{JSON.stringify(checkout)} for #{user.username}"
      Checkouts.remove { _id: checkoutId }
      Email.send
        from: Meteor.settings.email.fromEmail
        to: user.mail
        subject: "Your checkout of item #{item?.name} has been cancelled."
        html: "Your checkout of item #{item?.name} for #{moment(checkout.schedule.timeReserved).format('LL')} has been cancelled.
        If you feel this is in error, please submit a help request."

  addInventoryNote: (inventoryId, message) ->
    if Roles.userIsInRole @userId, 'admin'
      Inventory.update inventoryId, {
        $addToSet: { notes: {
          message: message
          enteredByUserId: @userId
          enteredAtTimestamp: new Date()
        } }
      }

  importInventory: (items) ->
    if Roles.userIsInRole @userId, 'admin'
      failures = []
      console.log "#{@userId} importing #{items.length} items"
      _.each items, (i) ->
        Inventory.upsert { propertyTag: i.propertyTag }, {
          $set: i
          $setOnInsert: { enteredIntoEbars: false, checkout: false, delivered: true, archived: false, isPartOfReplacementCycle: false }
        }, (err, res) ->
          if err
            console.log err.message
            failures.push(i)
      console.log "#{failures.length} items failed to import"
      return failures
