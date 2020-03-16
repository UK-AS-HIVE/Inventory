fields = [ 'name', 'propertyTag', 'serialNo', 'model', 'department', 'roomNumber', 'building', 'owner', 'shipDate', 'deviceType' ]
Template.editAssetModal.helpers
  item: -> Inventory.findOne(@docId)
  file: -> FileRegistry.findOne(@fileId)
  departments: -> _.map departments, (v) -> { label: v, value: v }
  deviceTypes: -> _.map deviceTypes, (v) -> { label: v, value: v }
  formatDate: (date) -> moment(date).format('MMM D, YYYY')

Template.editAssetModal.rendered = ->
  tpl = @
  @.$('.datepicker').datepicker({
    endDate: "0d"
    autoclose: true  
    todayHighlight: true
    orientation: "up" # up is down
  })

Template.editAssetModal.events
  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length)
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index',  zIndex-1).addClass('modal-stack')
    , 10

  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $(document.body).addClass('modal-open')

  'click button[data-action=attachFile]': (e, tpl) ->
     Media.pickLocalFile (fileId) =>
       Inventory.update @_id, { $addToSet: { attachments: { fileId: fileId , purpose: 'Other' } } }
  'click a[data-action=removeAttachment]': (e, tpl) ->
    Blaze.renderWithData Template.removeAttachmentModal, { attachmentId: @fileId, itemId: tpl.data.docId }, $('body').get(0)
    $('#removeAttachmentModal').modal('show')

  'click a[data-action=showAttachmentModal]': (e, tpl) ->
    Iron.query.set 'attachmentId', @fileId

  'click button[data-action=submit]': (e, tpl) ->
    obj = {}
    _.each fields, (f) ->
      unless tpl.$("[data-schema-key=#{f}]").is(':disabled')
        obj[f] = tpl.$("[data-schema-key=#{f}]").val()
    checkUsername tpl
    obj['checkout'] = tpl.$('[data-schema-key=checkout]').is(':checked')
    obj['enteredIntoEbars'] = tpl.$('[data-schema-key=enteredIntoEbars]').is(':checked')
    obj['isPartOfReplacementCycle'] = tpl.$('[data-schema-key=isPartOfReplacementCycle]').is(':checked')
    obj['archived'] = tpl.$('[data-schema-key=archived]').is(':checked')
    Inventory.update tpl.data.docId, { $set: obj }, (err, success) ->
      if (err)
        Inventory.simpleSchema().namedContext('assetForm').addInvalidKeys err.invalidKeys
      else
        $('#editAssetModal').modal('hide')

  'click button[data-action=getWarrantyInfo]': (e, tpl) ->
    Blaze.renderWithData Template.warrantyInfoModal, this, $('body').get(0)
    $('#warrantyInfoModal').modal('show')

  'click button[data-action=delete]': (e, tpl) ->
    Blaze.renderWithData Template.confirmDeleteModal, this, $('body').get(0)
    $('#editAssetModal').modal('hide')
    $('#confirmDeleteModal').modal('show')

  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

  'click button[data-action=checkUsername]': (e, tpl) ->
    checkUsername tpl

  'click button[data-action=lookupShipDate]': (e, tpl)->
    lookupShipDate tpl 

  'click button[data-action=recordNewDelivery]': (e, tpl) ->
    Blaze.renderWithData Template.pickupModal, { docId: tpl.data.docId }, $('body').get(0)
    $('#pickupModal').modal('show')

  'click button[data-action=deliverWithoutUser]': (e, tpl) ->
    Meteor.call 'recordItemDeliveryWithoutUser', tpl.data.docId

Template.editAssetModal.created = ->
  @subscribe 'buildings'
  @subscribe 'item', @data.docId

checkUsername = (tpl, winCb, failCb) ->
  # A check username function for this template only.
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

lookupShipDate = (tpl) ->
  modelVal = tpl.$('input[data-schema-key=model]').val()
  serialVal = tpl.$('input[data-schema-key=serialNo]').val()
  Meteor.call 'lookupShipDate', serialVal, modelVal, (err, res) -> 
    if res
      tpl.$('input[data-schema-key=shipDate]').val(moment(res).format('L'))
      tpl.$('.datepicker').datepicker('update', moment(res).format('L'))
    else
      alert('Ship date could not be found.  Ship date lookup is only available for Dell devices.')
  

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