clearFilters = ->
  Router.go '/inventory'

getFilters = ->
  filters = {
    department: Iron.query.get 'department'
    owner: Iron.query.get 'owner'
    building: Iron.query.get 'building'
    keyType: Iron.query.get 'keyType'
    $text: { $search: Iron.query.get 'search' }
  }
  
  # Mongo really doesn't like null filter values
  for k,v of filters
    if _.isUndefined(v)
      delete filters[k]

    if v is '(none)'
      filters[k] = { $exists: false }

  if _.isUndefined filters.$text.$search
    delete filters.$text

  if Iron.query.get 'archived'
    filters.archived = true
  else
    filters.archived = {$ne: true}

  if Iron.query.get 'isPartOfReplacementCycle'
    filters.isPartOfReplacementCycle = true

  return filters

Template.inventory.helpers
  exportUrl: -> Router.current().originalUrl.replace('inventory', 'export')
  admin: -> Roles.userIsInRole Meteor.userId(), 'admin'
  pageLimit: -> Template.instance().pageLimit.get()
  tableSettings: ->
    fields =  [
      { key: 'badges', label: Spacebars.SafeString("<input type='checkbox' name='selectAll'>"), tpl: Template.inventoryBadges, sortable: false, class: 'hidden-xs' }
      'keyNumber',
      'keyType',
      { key: 'department', class: 'hidden-xs' }
      { key: 'owner', tpl: Template.ownerField },
      'roomNumber'
      'building'
      { key: 'shipDate', tpl: Template.shipDateField, sortable: true },
      { key: 'attachments', tpl: Template.attachmentField, sortable: false, class: 'hidden-xs' }
    ]
    if Roles.userIsInRole Meteor.userId(), 'admin'
      fields.push { key: 'actions', label: "Actions", tpl: Template.inventoryActionsField, sortable: false }
    return {
      fields: fields
      subscription: "inventory"
      class: "autotable table table-condensed"
      filters: getFilters
      clearFilters: clearFilters
      pageLimit: Template.instance().pageLimit.get()
    }

Template.inventory.events
  'change input[name=pageLimit]': (e, tpl) ->
    tpl.pageLimit.set Number tpl.$('input[name=pageLimit]').val()
  'change input[name=selectAll]': (e, tpl) ->
    $('input[type=checkbox][name=selectRow]').prop 'checked', tpl.$(e.target).is(':checked')
    $('input[name=selectRow]').trigger('change')


Template.inventory.onCreated ->
  @pageLimit = new ReactiveVar(20)
Template.inventory.rendered = ->
  @autorun ->
    # Render attachment modal on query parameter change.
    attachmentParam = Iron.query.get('attachmentId')
    if attachmentParam and not $('#attachmentModal').length
      Meteor.subscribe 'file', attachmentParam
      file = FileRegistry.findOne(attachmentParam)
      if file
        Blaze.renderWithData Template.attachmentModal, { attachmentId: attachmentParam }, $('body').get(0)
        $('#attachmentModal').modal('show')
      else
        $('#attachmentModal').modal('hide')
