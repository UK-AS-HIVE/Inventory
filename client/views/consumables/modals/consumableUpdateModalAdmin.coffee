Template.consumableUpdateModalAdmin.onCreated ->
  console.log @, arguments
  @error = new ReactiveVar null

Template.consumableUpdateModalAdmin.helpers
  currentValue: ->
    Consumables.findOne(@docId)
  error: ->
    Template.instance().error.get()

Template.consumableUpdateModalAdmin.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

  'click button[name=update]': (e, tpl) ->
    obj = {}
    fields = ['itemName', 'currentStock']
    _.each fields, (f) ->
      $el = tpl.$("[data-schema-key=#{f}]")
      if $el.data('required')
        if !$el.val().length
          $el.closest('.form-group').addClass('has-error')
        else
          $el.closest('.form-group').removeClass('has-error')

      obj[f] = $el.val()

    Consumables.update tpl.data.docId,
      $set: obj,
      (err, res) ->
        if err
          tpl.error.set err
        else
          if tpl.$('textarea').val()
            Meteor.call 'addConsumableNote', res, tpl.$('textarea').val()
          tpl.$('#consumableUpdateModalAdmin').modal('hide')

  'click button[name=cancel]': (e, tpl) ->
    return
  'click button[name=viewHistory]': (e, tpl) ->
    return
