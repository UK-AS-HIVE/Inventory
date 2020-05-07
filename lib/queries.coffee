Checkouts.queries =
  allCheckouts: Checkouts.createQuery 'allCheckouts',
    assetId: 1
    asset:
      name: 1
      deviceType: 1
    assignedTo: 1
    name: 1
    model: 1
  pagedCheckouts: Checkouts.createQuery 'pagedCheckouts',
    assetId: 1
    asset:
      name: 1
      deviceType: 1
    assignedTo: 1
    name: 1
    model: 1
    $filter: ({filters, options, params}) ->
      console.log("pagedCheckouts filter function!", arguments)
      options.limit = params.limit
      options.sort = {}
      options.sort[params.sortKey] = params.sortOrder
      options.skip = params.skip

Inventory.queries =
  inventory: Inventory.createQuery 'inventory',
    name: 1
    propertyTag: 1
    serialNo: 1
    model: 1
    department: 1
    owner: 1
    roomNumber: 1
    building: 1
    shipDate: 1
    attachments: 1
    delivered: 1
    enteredIntoEbars: 1
    checkout: 1
    isPartOfReplacementCycle: 1
    attachmentFiles:
      _id: 1
      filename: 1
      thumbnail: 1
    $filter: ({filters, options, params}) ->
      console.log 'inventory filter func!', arguments
      options.skip = params.skip
      options.limit = 20
      options.sort = {}
      options.sort[params.sortKey] = params.sortOrder
  checkouts: Inventory.createQuery 'checkouts',
    name: 1
    deviceType: 1
    model: 1
    checkouts:
      assetId: 1
      assignedTo: 1
      schedule: 1
      approval: 1
      $filter: ({filters, options, params}) ->
        console.log 'checkouts filter func, on actual Checkouts', arguments
        Object.assign filters, params.recentCheckoutsFilter
        ###
        options =
          fields:
            assignedTo: 0
            'approver.approverId': 0
        ###
    $filter: ({filters, options, params}) ->
      console.log 'checkouts filter func!', arguments
      options.skip = params.skip
      options.limit = 20
      options.sort = {}
      options.sort[params.sortKey] = params.sortOrder
    $filters:
      checkout: true
