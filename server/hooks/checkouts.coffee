Checkouts.after.insert (userId, doc) ->
  unless doc.approval?.approved
    users = Roles.getUsersInRole('admin').fetch()
    emails = _.pluck _.filter(users, (u) -> u.notificationSettings?.notifyOnNewCheckout), 'mail'
    item = Inventory.findOne(doc.assetId)
    requester = Meteor.users.findOne(doc.assignedTo)
    name = item.name || item.model # Name is preferred, but not required, so model as fallback
    Inventory.update doc.assetId,
      $set:
        awaitingApproval: true
    Email.send
      from: Meteor.settings.email.fromEmail
      to: emails
      subject: "New checkout request for item #{name}"
      html: "Requester #{requester.username} requested item #{name} for checkout from
      #{moment(doc.schedule.timeReserved).format('LL')} to #{moment(doc.schedule.expectedReturn).format('LL')}.
      Review checkout requests at <a href='#{Meteor.absoluteUrl()}checkouts'>#{Meteor.absoluteUrl()}checkouts</a>."

Checkouts.after.update (userId, doc, fieldNames, modifier, options) ->
  # Check if this is an update approving/rejecting a request. If so, send the appropriate email.
  if modifier.$set?.approval?.approved or modifier.$set?['approval.approved']
    item = Inventory.findOne(doc.assetId)
    name = item.name || item.model
    reason = if doc.approval.reason?.trim().length then "<br>Reason given: #{doc.approval.reason}" else ""
    Email.send
      from: Meteor.settings.email.fromEmail
      to: Meteor.users.findOne(doc.assignedTo)?.mail
      subject: "Your reservation of #{name} has been approved"
      html: "Your reservation of #{name} for #{moment(doc.schedule.timeReserved).format('LL')} has been approved.
      Please visit POT 915, 923, or 961 to pick up your item on that date when ready.#{reason}"

  else if modifier.$set?.approval?.approved is false or modifier.$set?['approval.approved'] is false
    item = Inventory.findOne(doc.assetId)
    name = item.name || item.model
    Email.send
      from: Meteor.settings.email.fromEmail
      to: Meteor.users.findOne(doc.assignedTo)?.mail
      subject: "Your reservation of #{name} has been rejected"
      html: "Your reservation of #{name} for #{moment(doc.schedule.timeReserved).format('LL')} has been rejected.<br>
      Reason given: #{doc.approval.reason}"

  # If there are no longer any pending approvals, reset it on Inventory
  if Checkouts.find({assetId: doc.assetId, approval: {$exists: false}}).count() == 0
    Inventory.update doc.assetId,
      $set:
        awaitingApproval: false
