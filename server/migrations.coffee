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
    return

Migrations.add
  version: 3
  up: ->
    Inventory.update { isPartOfReplacementCycle: { $exists: false }}, { $set: { isPartOfReplacementCycle: false }}, { multi: true }
 
Meteor.startup ->
  Migrations.migrateTo(3)
