clearFilters = ->
  Router.go '/consumables'

getFilters = ->
  filters = {
    itemName: Iron.query.get 'itemName'
  }
  
  # Mongo really doesn't like null filter values
  for k,v of filters
    if _.isUndefined(v)
      delete filters[k]

    if v is '(none)'
      filters[k] = { $exists: false }

  return filters

Template.consumables.helpers
  admin: -> Roles.userIsInRole Meteor.userId(), 'admin'
  pageLimit: -> Template.instance().pageLimit.get()
  ready: -> Template.instance().ready.get()
  records: ->
    sort = {}
    sort[Template.instance().sortKey.get()] = Template.instance().sortDir.get()
    Consumables.find({}, {sort: sort}).fetch()
  fields: ->
    fields = [
      {key: 'itemName', label: 'Item', class: 'col-md-3'},
      {key: 'currentStock', label: 'Current Stock', class: 'col-md-3'}
      {key: 'note', label: 'Note', class: 'col-md-3'}
      {key: 'actions', label: 'Actions', tpl: Template.consumablesActionsAdminField, sortable: false}
    ]
    _.map fields, (f) ->
      if _.isString(f) then f = { key: f } # SimpleSchema does weird things with obj inputs
      if _.isString(f.tpl) then f.tpl = Template[f.tpl]
      {
        key: f.key
        label: f.label || context.schema?.label(f.key) || f.key
        tpl: f.tpl
        sortable: if _.isUndefined(f.sortable) then true else f.sortable
        class: f.class || null
      }
  fieldCellContext: (doc) ->
    fieldName: @key
    value: doc[@key]
    documentId: doc._id
  getField: (doc) -> doc[@key]
  firstVisibleItem: ->
    if Consumables.find({}).count() is 0 then 0 else Template.instance().page.get()*20 + 1
  lastVisibleItem: ->
    tpl = Template.instance()
    Math.min tpl.page.get()*20 + tpl.pageLimit.get(), (Counts.get('consumablesCount') || Consumables.find({}).count())
  itemCount: -> Consumables.find({}).count()
  isSortKey: ->
    @key is Template.instance().sortKey.get()
  isAscending: ->
    Template.instance().sortDir.get() is 1


  

Template.consumables.events
  'click button[data-action=addNewConsumable]': (e, tpl) ->
    Blaze.render Template.newConsumableModal, $('body').get(0)
    $('#newConsumableModal').modal('show')
  'click span[class=inventory-table-heading]': (e) ->
    sortKey = Template.instance().sortKey.get()
    sortDir = Template.instance().sortDir.get()
    if sortKey is $(e.target).data('sort-key')
      Template.instance().sortDir.set (-1 * sortDir)
    else
      Template.instance().sortDir.set 1
    Template.instance().sortKey.set $(e.target).data('sort-key')



Template.consumables.onCreated ->
  @pageLimit = new ReactiveVar(20)
  @ready = new ReactiveVar(false)
  @sortKey = new ReactiveVar 'itemName'
  @sortDir = new ReactiveVar 1
  @page = new ReactiveVar 0

  @autorun =>
    console.log 'subscribing to consumables'
    @subscribe 'consumables', {}, @sortKey.get(), @sortDir.get(), @page.get(),
      onReady: (err, res) =>
        console.log 'ready!', arguments
        @ready.set true
