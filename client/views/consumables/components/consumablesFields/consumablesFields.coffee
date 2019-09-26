Template.consumablesActionsAdminField.events
  'click button[data-toggle=modal]': (e, tpl) ->
    modal = tpl.$(e.currentTarget).data('modal')
    Blaze.renderWithData Template[modal], { docId: tpl.data.documentId }, $('body').get(0)
    $("##{modal}").modal('show')
