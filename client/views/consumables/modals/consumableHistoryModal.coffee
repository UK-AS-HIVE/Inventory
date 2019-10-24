Template.consumableHistoryModal.onCreated ->
  @subscribe 'consumableHistory', @data.docId

Template.consumableHistoryModal.helpers
  consumable: -> Consumables.findOne @docId
  first: (a) -> a[0]
  rest: (a) -> a.slice(1)

Template.consumableHistoryModal.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
