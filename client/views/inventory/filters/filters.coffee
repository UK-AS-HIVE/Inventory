Template.inventoryFilters.events
  'keyup input[name=search], click button[name=search]': (e, tpl) ->
    if e.keyCode is 13 or !e.keyCode
      Iron.query.set 'search', tpl.$('input[name=search]').val()

  'keyup input[name=mobile-search], click button[name=mobile-search]': (e, tpl) ->
    if e.keyCode is 13 or !e.keyCode
      Iron.query.set 'search', tpl.$('input[name=mobile-search]').val()

  'change input.filter-archived': (e, tpl) ->
    Iron.query.set 'archived', $(e.target).prop('checked')

  'change input.filter-isPartOfReplacementCycle': (e, tpl) ->
    Iron.query.set 'isPartOfReplacementCycle', $(e.target).prop('checked')

Template.inventoryFilters.helpers
  facetKeys: ->
    ###
    if Facets.findOne()
      _.keys(Facets.findOne().facets)
    ###
    
    # If we don't hard code these in, they'll flicker whenever we filter.
    [
      { key: 'department', label: 'Department' }
      { key: 'owner', label: 'Owner' }
      { key: 'building', label: 'Building' }
      { key: 'model', label: 'Model' }
      { key: 'attachmentPurposes', label: 'Attachment Type' }
    ]
  value: ->
    key = @key
    active = Iron.query.get(key)?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.facets[key], (f) -> -f.count), (l) ->
      if !l.name?.length then l.name = '(none)'
      _.extend l,
        key: key
        checked: if l.name in active then 'checked'

  selection: -> Iron.query.get(@key) || "Any"
  archiveFilterChecked: -> if Iron.query.get('archived') then "checked" else ""
  isPartOfReplacementCycleFilterChecked: -> if Iron.query.get('isPartOfReplacementCycle') then "checked" else ""

Template.facetCheckbox.events
  'change input:checkbox': (e, tpl) ->
    cur = Iron.query.get(@key)?.split(',') || []
    if $(e.target).is(':checked')
      cur.push @name
    else
      cur = _.without cur, @name

    Iron.query.set @key, _.uniq(cur).join()
