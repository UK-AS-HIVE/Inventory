findOverdueItems = ->
  console.log "Finding overdue items"
  startOfToday = moment().hours(0).minutes(0).seconds(0).toDate()
  checkouts = Checkouts.find({
    'schedule.expectedReturn': { $lt: startOfToday },
    'schedule.timeReturned': { $exists: false },
    'schedule.timeCheckedOut': { $exists: true }
  }).fetch()
  console.log "Overdue checkouts: #{JSON.stringify(checkouts)}"

  _.each checkouts, (c) ->
    console.log 'overdue'
    user = Meteor.users.findOne(c.assignedTo)
    item = Inventory.findOne(c.assetId)
    name = item.name || item.keyType
    if item
      Email.send
        from: Meteor.settings.email.fromEmail
        to: user?.mail
        subject: "Your checkout of item #{name} is overdue"
        html: "Your checkout of item #{name} was expected to be returned on #{moment(c.schedule.expectedReturn).format('LL')}.
        By our records, it still has not been checked in. Please return the item to POT 915, 923, or 961.
        If you believe this message is in error, please submit a help request."

findDueItems = ->
  console.log "Finding due items"
  startOfToday = moment().hours(0).minutes(0).seconds(0).toDate()
  endOfToday = moment().hours(24).minutes(0).seconds(0).toDate()
  checkouts = Checkouts.find({
    'schedule.expectedReturn': { $gte: startOfToday, $lt: endOfToday },
    'schedule.timeReturned': { $exists: false },
    'schedule.timeCheckedOut': { $exists: true }
  }).fetch()
  console.log "Today's due checkouts: #{JSON.stringify(checkouts)}"

  _.each checkouts, (c) ->
    console.log 'due'
    user = Meteor.users.findOne(c.assignedTo)
    item = Inventory.findOne(c.assetId)
    name = item.name || item.keyType
    if item
      Email.send
        from: Meteor.settings.email.fromEmail
        to: user?.mail
        subject: "Your checkout of item #{name} is due today"
        html: "Your expected return date for item #{name} is #{moment(doc.schedule.expectedReturn).format('LL')}.
          Please have the item ready to return. It may be dropped off in POT 915, 923, or 961."
        

SyncedCron.add
  name: '8:00 AM reminder emails'
  schedule: (parser) -> parser.text 'at 8:00 am every weekday'
  job: ->
    # HACK: syncedCron seems to run when either local time OR utc time matches, so check that it's the right one
    if new Date().getHours() == 8
      findOverdueItems()
      findDueItems()
    else
      console.log 'it may be 8 am somewhere, but not here!'

pickupReminders = ->
  console.log "Sending day-before-pickup reminders"
  startOfTomorrow = moment().hours(24).minutes(0).seconds(0).toDate()
  endOfTomorrow = moment().hours(48).minutes(0).seconds(0).toDate()
  checkouts = Checkouts.find({
    'schedule.timeReserved': { $gte: startOfTomorrow, $lt: endOfTomorrow },
    'approval.approved': true
  }).fetch()
  console.log "Reservations for #{startOfTomorrow}: #{JSON.stringify(checkouts)}"

  _.each checkouts, (c) ->
    item = Inventory.findOne(c.assetId)
    user = Meteor.users.findOne(c.assignedTo)
    name = item.name || item.keyType # Name is preferred, but not required, so model as fallback

    if item
      Email.send
        from: Meteor.settings.email.fromEmail
        to: user.mail
        subject: "REMINDER: Your checkout of item #{name} for #{moment(c.schedule.timeReserved).format('LL')}"
        html: "This email is to remind you of your request for checkout item #{name} for dates
          #{moment(c.schedule.timeReserved).format('LL')} through #{moment(c.schedule.expectedReturn).format('LL')}.
          Please visit POT 915, 923, or 961 to pick up your item when ready."

dueSoonReminders = ->
  console.log "Sending due-soon reminders"
  daysUntilDue = 3
  dueDate =
    start: moment().hours(0).minutes(0).seconds(0).add(daysUntilDue, 'days').toDate()
    end: moment().hours(24).minutes(0).seconds(0).add(daysUntilDue, 'days').toDate()
  checkouts = Checkouts.find({
    'schedule.expectedReturn': { $gte: dueDate.start, $lt: dueDate.end },
    'schedule.timeReturned': { $exists: false },
    'schedule.timeCheckedOut': { $exists: true }
  }).fetch();
  console.log "Due-soon: #{JSON.stringify(checkouts)}"

  _.each checkouts, (c) ->
    item = Inventory.findOne(c.assetId)
    user = Meteor.users.findOne(c.assignedTo)
    name = item.name || item.keyType

    if item
      Email.send
        from: Meteor.settings.email.fromEmail
        to: user.mail
        subject: "Your checkout of item #{name} is due soon"
        html: "Your expected return date for item #{name} is #{moment(c.schedule.expectedReturn).format('LL')}. Please have the item ready to return. It may be dropped off in POT 915, 923, or 961."


SyncedCron.add
  name: '5:00 PM reminder emails'
  schedule: (parser) -> parser.text 'at 5:00 pm'
  job: ->
    # HACK: syncedCron seems to run when either local time OR utc time matches, so check that it's the right one
    if new Date().getHours == 17
      pickupReminders()
      dueSoonReminders()
    else
      console.log 'It may be 5:00 pm somewhere, but not here!'

SyncedCron.start()

