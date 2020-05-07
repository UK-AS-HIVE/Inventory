Inventory.addLinks
  enteredByUser:
    type: 'one'
    collection: Meteor.users
    field: 'enteredByUserId'
  checkouts:
    type: 'many'
    collection: Checkouts
    inversedBy: 'asset'
  attachmentFiles:
    type: 'many'
    collection: FileRegistry
    field: 'attachments'
    metadata: true

FileRegistry.addLinks
  asset:
    collection: Inventory
    inversedBy: 'attachmentFiles'

Changelog.addLinks
  item:
    type: 'one'
    collection: Inventory
    field: 'itemId'

Checkouts.addLinks
  asset:
    type: 'one'
    collection: Inventory
    field: 'assetId'
