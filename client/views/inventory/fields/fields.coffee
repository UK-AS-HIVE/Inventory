
Template.shipDateField.helpers
  parsedTime: -> moment(@value).format('MMM D, YYYY')
  fullTime: -> moment(@value).format('MMMM Do YYYY, h:mm:ss a')

Template.inventoryBadges.helpers
  item: -> Inventory.findOne(@documentId)
  noteCount: -> if @notes?.length then @notes.length # just to prevent 0-count badges from showing

Template.inventoryBadges.events
  'change input': (e, tpl) ->
    items = Session.get('selected') || []
    if tpl.$('input').is(':checked')
      items.push @_id
    else
      items = _.without items, @_id
    Session.set 'selected', _.uniq(items)

Template.attachmentField.helpers
  file: ->
    FileRegistry.findOne(@fileId)

Template.attachmentField.events
  'click a[data-action=showAttachmentModal]': (e, tpl) ->
    e.stopPropagation()
    Iron.query.set 'attachmentId', @fileId

  'click a[data-action=uploadFile]': (e, tpl) ->
    e.stopPropagation()
    id = @documentId
    options =
      immediate: true
      attributes:
        multiple: null
    Media.pickLocalFile options, (fileId) ->
      Blaze.renderWithData Template.attachmentTypeModal, { inventoryId: id, fileId: fileId }, $('body').get(0)
      $("#attachmentTypeModal").modal('show')
    tpl.$('.dropdown-toggle').dropdown('toggle')

  'click a[data-action=takePicture]': (e, tpl) ->
    id = @documentId
    Media.capturePhoto (fileId) ->
      Blaze.renderWithData Template.attachmentTypeModal, { inventoryId: id, fileId: fileId }, $('body').get(0)
      $("#attachmentTypeModal").modal('show')

Template.inventoryActionsField.helpers
  isAdmin: -> Roles.userIsInRole Meteor.userId(), 'admin'
  delivered: -> Inventory.findOne(@documentId).delivered

Template.inventoryActionsField.events
  'click button[data-toggle=modal]': (e, tpl) ->
    modal = tpl.$(e.currentTarget).data('modal')
    Blaze.renderWithData Template[modal], { docId: @documentId }, $('body').get(0)
    $("##{modal}").modal('show')
