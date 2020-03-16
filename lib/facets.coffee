@Filter =
  getFilterFromQuery: (query) ->
    q = _.omit(query, 'attachmentId')
    unless _.keys(q).length is 0
      filter = {}
      filter.$and = []

      for k,v of q
        obj = {}
        obj[k] = { $in: v.split(',') }
        filter.$and.push obj

      return filter

if Meteor.isServer
  Facets.configure Inventory,
    department: String
    owner: String
    building: String
    model: String
    deviceType: String
