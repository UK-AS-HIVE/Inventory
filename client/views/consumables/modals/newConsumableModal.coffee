fields = [ 'itemName', 'currentStock' ]

Template.newConsumableModal.onCreated ->
  @error = new ReactiveVar ""

Template.newConsumableModal.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

  'click button[data-action=submit]': (e, tpl) ->
    obj = {}
    _.each fields, (f) ->
      $el = tpl.$("[data-schema-key=#{f}]")
      if $el.data('required')
        if !$el.val().length
          $el.closest('.form-group').addClass('has-error')
        else
          $el.closest('.form-group').removeClass('has-error')

      obj[f] = $el.val()

    Consumables.insert obj, (err, res) ->
      if err
        tpl.error.set err
      else
        if tpl.$('textarea').val()
          Meteor.call 'addInventoryNote', res, tpl.$('textarea').val()
        if tpl.$(e.currentTarget).attr('name') is 'close'
          $('#newConsumableModal').modal('hide')
        else if tpl.$(e.currentTarget).attr('name') is 'clear'
          tpl.$('select').val('')
          tpl.$('input[type=checkbox]').attr('checked', false)
          tpl.$('input').val('')

Template.newConsumableModal.rendered = ->
  tpl = @
  @.$('.datepicker').datepicker({
    endDate: "0d"
    autoclose: true
    todayHighlight: true
    orientation: "up" # up is down
  })

Template.newConsumableModal.helpers
  departments: -> departments
  error: -> Template.instance().error.get()
  modelSettings: ->
    {
      position: 'bottom'
      limit: 5
      rules: [
        token: ''
        collection: Models
        field: 'model'
        template: Template.modelPill
        matchAll: true
      ]
    }

Template.addConsumableQuickField.helpers
  isBoolean: -> Consumables.simpleSchema().schema(@name)?.type.name is "Boolean"
  label: -> Consumables.simpleSchema().label(@name)
  required: -> !Consumables.simpleSchema().schema(@name)?.optional?

# Static departments for the dropdown.
departments = [
  'AAAS'
  'Advising'
  'Air Force'
  'American Studies'
  'Anthropology'
  'Appalachian Center'
  'Army ROTC'
  'Aux Services'
  'Biology'
  'Chemistry'
  "Dean's Administration"
  'Earth and Environmental Sciences'
  'English'
  'Environmental and Sustainability Studies'
  'Center for English as a Second Language'
  'Geography'
  "Gender and Womens Studies"
  'History'
  'Hispanic Studies'
  'Hive'
  'IBU'
  'International Studies'
  'Linguistics'
  'Mathematics'
  'MCLLC'
  'OPSVAW'
  'Physics and Astronomy'
  'Philosophy'
  'Political Science'
  'Psychology'
  'Sociology'
  'Social Theory'
  'Statistics'
  'Writing, Rhetoric & Digital Studies'
  'Other/Not listed'
  'Unassigned'
]
