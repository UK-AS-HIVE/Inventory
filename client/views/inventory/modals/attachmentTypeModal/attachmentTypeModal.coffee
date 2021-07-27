Template.attachmentTypeModal.onCreated ->
  console.log 'subscribing to pendingAttachment', @, @inventoryId, @fileId
  @subscribe 'pendingAttachment', @data.inventoryId, @data.fileId

Template.attachmentTypeModal.helpers
  attachment: -> FileRegistry.findOne(@fileId)
  assetDescription: ->
    asset = Inventory.findOne(@inventoryId)
    asset.name || "#{asset.model} (#{asset.serialNo})"
  attachmentPurposes: (e, tpl) ->
    Inventory.simpleSchema()._schema['attachments.$.purpose'].allowedValues
  checkedIf: (a, b) -> if a == b then "checked" else null
  pct: (num, den) -> Math.round((num*100)/den)
  eq: (a, b) -> a == b

Template.attachmentTypeModal.events
  'click button[data-action=confirmAttachmentPurpose]': (e, tpl) ->
    console.log @
    #TODO: This isn't very good if we ever allow for an actual purpose...
    purpose = tpl.$('input[type=radio]:checked').val()
    Inventory.update @inventoryId, { $addToSet: { attachments: { fileId: @fileId, purpose: purpose } } }
    $('#attachmentTypeModal').modal('hide')


  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length)
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack')
    , 0

  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $('body').addClass('modal-open')
