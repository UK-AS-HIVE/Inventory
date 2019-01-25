Meteor.startup ->
  Inventory._ensureIndex {
    keyNumber: "text"
    keyType: "text"
    owner: "text"
    roomNumber: "text"
    building: "text"
    department: "text"
  }, { name: "invTextIndex" }
