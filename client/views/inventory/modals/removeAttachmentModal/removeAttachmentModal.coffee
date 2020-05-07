Template.removeAttachmentModal.helpers
  attachment: -> FileRegistry.findOne(@attachmentId)

Template.removeAttachmentModal.events
  'click button[data-action=removeAttachment]': (e, tpl) ->
    console.log @
    #TODO: This isn't very good if we ever allow for an actual purpose...
    Inventory.update @itemId, { $pull: { attachments: { fileId: @attachmentId, _id: @attachmentId, purpose: 'Other' } } }
    $('#removeAttachmentModal').modal('hide')

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
