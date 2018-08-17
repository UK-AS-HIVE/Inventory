SimpleSchema.messages {
  locationOrOwnerRequired: "Either Owner or Room Number must be present."
  currentlyCheckedOut: "This item is currently checked out."
}

@Inventory = new Mongo.Collection 'inventory'
@Inventory.attachSchema new SimpleSchema
  name:
    optional: true
    type: String
    label: "Asset Name"
  propertyTag:
    type: String
    optional: true
    unique: true
  deviceType:
    type: String
    optional: true
  serialNo:
    type: String
    label: "Serial Number"
  enteredByUserId:
    type: String
    optional: true # Will be taken care of by the server.
  enteredAtTimestamp:
    type: new Date()
    optional: true # Will be taken care of by the server.
  model:
    type: String
  department:
    type: String
  owner:
    type: String
    optional: true
    custom: ->
      unless @isSet or @field('roomNumber')?.isSet
        "locationOrOwnerRequired"
  roomNumber:
    type: String
    optional: true
    custom: ->
      unless @isSet or @field('owner')?.isSet
        "locationOrOwnerRequired"
  building:
    type: String
    optional: true
  location:
    type: String
    optional: true
  pictureId:
    type: String
    optional: true
  attachments:
    type: [Object]
    optional: true
  'attachments.$.purpose':
    type: String
    allowedValues: [
      'ApprovedQuote'
      'PurchaseAcknowledgement'
      'PackingSlip'
      'DeliveryForm'
      'OffCampusEquipmentForm'
      'Other'
    ]
  'attachments.$.fileId':
    type: String
  enteredIntoEbars:
    label: "Entered into Ebars?"
    type: Boolean
    defaultValue: false
  barcode:
    type: String
    optional: true
  checkout:
    label: "Available for Checkout?"
    type: Boolean
    defaultValue: false
    custom: ->
      if @value == false
        if Checkouts.findOne({assetId: @docId, 'schedule.timeCheckedOut': {$exists: true}, 'schedule.timeReturned': {$exists: false}})
          "currentlyCheckedOut"
  delivered:
    label: "Delivered to User?"
    type: Boolean
    defaultValue: false
  isPartOfReplacementCycle:  
    label: "Part of Replacement Cycle"
    type: Boolean
    defaultValue: false
  archived:
    label: "Archived"
    type: Boolean
    defaultValue: false
  notes:
    type: [Object]
    optional: true
  'notes.$.message':
    type: String
    autoform:
      afFieldInput:
        type: 'textarea'
        rows: 3
  'notes.$.enteredByUserId':
    type: String
  'notes.$.enteredAtTimestamp':
    type: new Date()
  warrantyInfo:
    type: Object
    blackbox: true
    optional: true
  shipDate:
    label: "Ship Date"
    type: new Date()
    optional: true

@Changelog = new Mongo.Collection 'changelog'
@Changelog.attachSchema new SimpleSchema
  itemId:
    type: String
    label: "Item ID"
  timestamp:
    type: new Date()
  userId:
    type: String
    optional: true
  username:
    type: String
    optional: true
  type:
    type: String
    allowedValues: [ 'field', 'attachment' ]
  oldValue:
    type: String
    optional: true
  newValue:
    type: String
    optional: true
  field:
    type: String
    optional: true
  otherId:
    type: String
    optional: true

@Deliveries = new Mongo.Collection 'deliveries'
@Deliveries.attachSchema new SimpleSchema
  assetId:
    type: String
  deliveredByUserId:
    type: String
  deliveredTo:
    optional: true
    type: String
  deliveredToUserId:
    type: String
    optional: true
  recipientSignatureImageId:
    type: String
    optional: true
  timestamp:
    type:
      new Date()

@Scans = new Mongo.Collection 'scans'
@Scans.attachSchema new SimpleSchema
  latitude:
    type: Number
    decimal: true
  longitude:
    type: Number
    decimal: true
  imageId:
    type: String
    optional: true
  userId:
    type: String
  note:
    type: String
    optional: true
  timestamp:
    type: new Date()

@Checkouts = new Mongo.Collection 'checkouts'
@Checkouts.attachSchema new SimpleSchema
  assetId:
    type: String
  assignedTo:
    type: String
  schedule:
    optional: true
    type: Object
  approval:
    optional: true
    type: Object
  notes:
    optional: true
    type: [Object]
  'notes.$.authorId':
    optional: true
    type: String
  'notes.$.timestamp':
    optional: true
    type: new Date()
  'notes.$.message':
    optional: true
    type: String
  'approval.approved':
    optional: true
    type: Boolean
  'approval.approverId':
    optional: true
    type: String
  'approval.reason':
    label: "Approval/Rejection Reason"
    optional: true
    type: String
  'schedule.timeCheckedOut':
    optional: true
    type: new Date()
  'schedule.timeReturned':
    optional: true
    type: new Date()
  'schedule.timeReserved':
    optional: true
    type: new Date()
  'schedule.expectedReturn':
    optional: true
    type: new Date()
  'schedule.checkedOutBy':
    optional: true
    type: String
  'schedule.checkedInBy':
    optional: true
    type: String

Meteor.users.attachSchema new SimpleSchema
  username:
    type: String
    label: "Username"
  defaultQueue:
    type: String
    optional: true
    label: "Default Queue"
  displayName:
    type: String
    optional: true
    label: "Display Name"
  employeeNumber:
    type: String
    optional: true
    label: "Employee Number"
  mail:
    type: String
    label: "Email Address"
  emails:
    type: [String]
    optional: true
    label: "Additional Email Addresses"
  memberOf:
    type: [String]
    label: "Member Of"
  department:
    type: String
    optional: true
  physicalDeliveryOfficeName:
    type: String
    label: "Physical Delivery Office"
    optional: true
  services:
    type: Object
    optional: true
    blackbox: true
  status:
    type: Object
    optional: true
    blackbox: true
  title:
    optional: true
    type: String
    label: "Title"
  roles:
    type: Object
    optional: true
    label: "Roles"
    blackbox: true
  notificationSettings:
    type: Object
    optional: true
  'notificationSettings.notifyOnNewCheckout':
    type: Boolean
    

@Models = new Mongo.Collection 'models'
@Models.attachSchema new SimpleSchema
  # Collection storing model names for autocompleting
  model:
    type: String
  lastUse:
    type: new Date()

@Buildings = new Mongo.Collection 'buildings'
@Buildings.attachSchema new SimpleSchema
  building:
    type: String
  lastUse:
    type: new Date()
