Migrations.add
  version: 1
  up: ->
    Inventory.find().forEach (i) ->
      if i.location
        [ roomNumber, building ] = separateLocation(i.location)
        if roomNumber or building
          Inventory.update i._id, { $set: { building: building, roomNumber: roomNumber } }
          Buildings.upsert { building: building }, { $set: lastUse: new Date() }

Migrations.add
  version: 2
  up: ->
    Inventory.find().forEach (i) ->
      Job.push new WarrantyLookupJob
        inventoryId: i._id

Migrations.add
  version: 3
  up: ->
    Inventory.update { isPartOfReplacementCycle: { $exists: false }}, { $set: { isPartOfReplacementCycle: false }}, { multi: true }

Migrations.add
  version: 4
  up: ->
    # Kinda wacky, but this is how it was implemented so far...
    # Gotta keep bug-feature compatibility until we can correct it
    aWeekAgo = moment().subtract(1, 'weeks').toDate()
    today = moment().hours(0).minutes(0).seconds(0).toDate()

    Checkouts.find({
        approval: {$exists: false}
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
      }).forEach (c) ->
      Inventory.update c.assetId,
        $set:
          awaitingApproval: true
  down: ->
    Inventory.update {}, {$unset: {awaitingApproval: true}}, {multi: true}
 
Meteor.startup ->
  Migrations.migrateTo(4)
