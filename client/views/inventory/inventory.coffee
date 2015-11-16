getFilters = ->
  filters = {
    department: Iron.query.get 'department'
    owner: Iron.query.get 'owner'
    building: Iron.query.get 'building'
  }

  for k,v of filters
    if _.isUndefined(v)
      delete filters[k]

  return filters

Template.inventory.helpers
  settings: ->
    {
      collection: Inventory
      fields: [
        'propertyTag',
        'deviceType',
        'serialNo',
        'manufacturer',
        'modelNo',
        'department',
        'owner',
        'building',
        'officeNo',
        { key: 'attachments', tpl: Template.attachmentField }
      ]
      addButton: false
      actionColumn: false
      class: "autotable table table-condensed"
      subscription: "inventory"
      filters: getFilters
    }
  ready: -> Session.get 'ready'

Template.inventory.events
  'click button[name=newAssetButton]': (e, tpl) ->
    Blaze.render Template.newAssetModal, $('body').get(0)
    $('#newAssetModal').modal('show')
