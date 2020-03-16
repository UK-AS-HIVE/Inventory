fields = [ 'serialNo', 'model', 'department', 'propertyTag', 'roomNumber', 'building', 'owner', 'name', 'shipDate', 'deviceType' ]
boolFields = [ 'checkout', 'enteredIntoEbars', 'delivered', 'isPartOfReplacementCycle' ]

Template.newAssetModal.onCreated ->
  @error = new ReactiveVar ""
  @subscribe 'models'
  @subscribe 'buildings'

Template.newAssetModal.events
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

    checkUsername tpl

    _.each boolFields, (f) ->
      obj[f] = tpl.$("[data-schema-key=#{f}]").is(':checked')
    Inventory.insert obj, (err, res) ->
      if err
        tpl.error.set err
      else
        if tpl.$('textarea').val()
          Meteor.call 'addInventoryNote', res, tpl.$('textarea').val()
        if tpl.$(e.currentTarget).attr('name') is 'close'
          $('#newAssetModal').modal('hide')
        else if tpl.$(e.currentTarget).attr('name') is 'clear'
          tpl.$('select').val('')
          tpl.$('input[type=checkbox]').attr('checked', false)
          tpl.$('input').val('')

  'click button[data-action=checkUsername]': (e, tpl) ->
    checkUsername tpl

  'click button[data-action=lookupShipDate]': (e, tpl)->
    lookupShipDate tpl  

Template.newAssetModal.rendered = ->
  tpl = @
  @.$('.datepicker').datepicker({
    endDate: "0d"
    autoclose: true
    todayHighlight: true
    orientation: "up" # up is down
  })

Template.newAssetModal.helpers
  departments: -> departments
  deviceTypes: -> deviceTypes
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
lookupShipDate = (tpl) ->
  modelVal = tpl.$('input[data-schema-key=model]').val()
  serialVal = tpl.$('input[data-schema-key=serialNo]').val()
  Meteor.call 'lookupShipDate', serialVal, modelVal, (err, res) -> 
    if res
      tpl.$('input[data-schema-key=shipDate]').val(moment(res).format('L'))
      tpl.$('.datepicker').datepicker('update', moment(res).format('L'))
    else
      alert('Ship date could not be found.  Ship date lookup is only available for Dell devices.')


checkUsername = (tpl, winCb, failCb) ->
  # A check username function for this template only.
  # TODO: Could probably do this with less jQuery and more ReactiveVars.
  val = tpl.$('input[data-schema-key=owner]').val()
  unless val.length < 1
    Meteor.call 'checkUsername', val, (err, res) ->
      if res
        tpl.$('input[data-schema-key=owner]').parent().parent().removeClass('has-error').addClass('has-success')
        tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
        tpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')
        if winCb then winCb()
      else
        tpl.$('input[data-schema-key=owner]').parent().parent().removeClass('has-success').addClass('has-error')
        tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
        tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')
        if failCb then failCb()

Template.addAssetQuickField.helpers
  isBoolean: -> Inventory.simpleSchema().schema(@name)?.type.name is "Boolean"
  label: -> Inventory.simpleSchema().label(@name)
  required: -> !Inventory.simpleSchema().schema(@name)?.optional?

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

deviceTypes = [
  'PC laptop'
  'Mac laptop'
  'iPad'
  'Webcam'
  'Headset with microphone'
  'Video Camera/Audio Recorder'
  'Projector'
  'Miscellaneous'
  'Bioinformatics laptop'
]