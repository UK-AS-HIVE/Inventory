setup = ->
  context = {}
  context.ready = new ReactiveVar(false)
  context.templateData = @data
  @data.settings = @data.settings || {}
  context.schema = Inventory.simpleSchema()

  fields = @data.fields || @data.settings.fields || _.filter context.schema._firstLevelSchemaKeys, (k) ->
    context.schema._schema[k].autotable?.included
    
  fields = _.filter fields, (k) ->
    # Filter out array keys in case one was somehow left in
    if _.isString(k) then k.indexOf('.$') == -1
    else k.key.indexOf('.$') == -1

  fields = _.map fields, (f) ->
    if _.isString(f) then f = { key: f } # SimpleSchema does weird things with obj inputs
    if _.isString(f.tpl) then f.tpl = Template[f.tpl]
    {
      key: f.key
      label: f.label || context.schema?.label(f.key) || f.key
      tpl: f.tpl
      sortable: if _.isUndefined(f.sortable) then true else f.sortable
      class: f.class || null
    }

  context.fields = fields

  # If a default field to sort on is provided, sort on it. If not, use whatever field was given first.
  context.sortKey = new ReactiveVar(@data.defaultSort || @data.settings.defaultSort || fields[0].key)
  context.sortOrder = new ReactiveVar(1)

  # User defined settings
  context.class = @data.class || @data.settings.class || 'autotable table table-condensed'
  context.pageLimit = @data.pageLimit || @data.settings.pageLimit || 20
  if context.pageLimit < 1 then context.pageLimit = 1

  context.skip = new ReactiveVar(0)
  context.getFilters = @data.filters || @data.settings.filters || -> {}
  context.getFiltersForClient = =>
    # Kinda janky - if we want to have a $text filter, we have to filter it out for Minimongo.
    # There may be others we need to consider, but this is all I know of for now.
    filters = context.getFilters()
    if filters.$text then delete filters.$text
    return filters

  # Allow passing in a function to clear the result set.
  context.clearFilters = @data.clearFilters || @data.settings.clearFilters || -> null
  @context = context

Template.inventoryTable.helpers
  context: ->
    if !Template.instance().context or !_.isEqual(@, Template.instance().context.templateData)
      setup.call Template.instance()
    Template.instance().context

  ready: -> @ready.get()

  records: ->
    sort = {}
    sortKey = @sortKey.get()
    sort[sortKey] = @sortOrder.get() || -1
    filter = $and: [@getFiltersForClient(),{}]
    filter['$and'][1][sortKey] = $ne: null
    records = Inventory.find(filter, { sort: sort }).fetch()
    filter['$and'][1][sortKey] = null
    records.concat Inventory.find(filter).fetch()
    
  fieldCount: (f) ->
    (f or @).fields.length + @actionColumn

  isSortKey: ->
    parentData = Template.parentData(1)
    @key is parentData.sortKey.get()

  isAscending: ->
    parentData = Template.parentData(1)
    parentData.sortOrder.get() is 1

  getField: (doc) -> doc[@key]

  fieldCellContext: (doc) ->
    {
      fieldName: @key
      value: doc[@key]
      documentId: doc._id
    }

  firstVisibleItem: ->
    if Inventory.find(@getFiltersForClient()).count() is 0 then 0 else @skip.get() + 1
  lastVisibleItem: ->
    Math.min @skip.get() + @pageLimit, Template.instance().count.get()
  lastDisabled: ->
    if @skip.get() <= 0 then "disabled"
  nextDisabled: ->
    if @skip.get() + @pageLimit + 1 > Template.instance().count.get() then "disabled"
  itemCount: ->
    Template.instance().count.get()
    #Counts.get('inventoryCount') || Inventory.find(@getFiltersForClient()).count()

Template.inventoryTable.events
  'click span[class=inventory-table-heading]': (e) ->
    sortKey = Template.instance().context.sortKey.get()
    sortOrder = Template.instance().context.sortOrder.get()
    if sortKey is $(e.target).data('sort-key')
      Template.instance().context.sortOrder.set (-1 * sortOrder)
    else
      Template.instance().context.sortOrder.set 1
    Template.instance().context.sortKey.set $(e.target).data('sort-key')

  'click button[data-action=nextPage]': (e, tpl) ->
    context = Template.instance().context
    skip = context.skip.get()
    pageLimit = context.pageLimit
    if skip + pageLimit < tpl.count.get()
      Template.instance().context.skip.set(skip + pageLimit)

  'click button[data-action=lastPage]': (e, tpl) ->
    skip = Template.instance().context.skip.get() || 0
    pageLimit = Template.instance().context.pageLimit

    newSkip = Math.max skip - pageLimit, 0
    Template.instance().context.skip.set(newSkip)

  'click a[data-action=clearFilters]': (e, tpl) ->
    tpl.context.clearFilters()


Template.inventoryTable.onCreated ->
  @count = new ReactiveVar 0

Template.inventoryTable.onRendered ->
  @autorun =>
    context = @context
    sort = {}
    sortKey = context.sortKey.get()
    limit = context.pageLimit
    skip = context.skip.get()
    sort[sortKey] = context.sortOrder.get() || -1

    params =
      limit: context.pageLimit
      sortOrder: context.sortOrder.get() || -1
      sortKey: context.sortKey.get()
      skip: context.skip.get()
      filter: context.getFilters()
    
    console.log('subscribing to inventory with params', params);

    query = Inventory.queries.inventory.clone(params)
    handle = query.subscribe (err, res) ->
      console.log 'subscribed to inventory, subscription id:', arguments

    countQuery = Inventory.queries.inventory.clone(params)
    countHandle = countQuery.subscribeCount()
    
    @autorun =>
      if countHandle.ready()
        @count.set countQuery.getCount()

    @autorun ->
      context.ready.set handle.ready()

    ###
    Meteor.subscribe 'inventory',
      context.getFilters(),
      { limit: limit, skip: skip, sort: sort },
      onReady: ->
        context.ready.set(true)
      onStop: ->
        context.ready.set(false)
    ###
    
    # Subscription onReady callbacks sometimes don't fire on re-sub inside autorun
    # see https://github.com/meteor/meteor/issues/1173
    # Auto-set ready after 4 seconds for safety.
    setTimeout ->
      context.ready.set(true)
    , 4000

    Meteor.subscribe 'newInventory', context.getFilters(), new Date()
