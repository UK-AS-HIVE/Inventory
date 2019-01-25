# These match the export fields.
templateKeys = [ 'owner', 'department', 'keyType', 'roomNumber', 'building', 'name' ]

Template.import.onCreated ->
  @assets = new ReactiveVar []
  @failures = new ReactiveVar []
  @complete = new ReactiveVar false

Template.import.events
  'click button[data-action=importItems]': (e, tpl) ->
    tpl.failures.set []
    tpl.complete.set false
    if _.difference(_.keys(tpl.assets.get()[0]), templateKeys).length > 0
      console.log _.difference _.keys(tpl.assets.get()[0]), templateKeys
      alert('Mismatch in CSV headers. Please check template and make sure keys are correct.')
    else
      Meteor.call 'importInventory', tpl.assets.get(), (err, res) ->
        tpl.failures.set res
        unless err then tpl.complete.set true

  'change #fileUpload': (e, tpl) ->
    tpl.failures.set []
    tpl.complete.set false
    if window.File and window.FileReader and window.FileList and window.Blob
      file = e.target.files[0]
      reader = new FileReader()
      reader.readAsText file
      reader.onload = (event) ->
        csv = event.target.result
        # jQuery CSV assumes the first line of the CSV contains object keys
        data = $.csv.toObjects(csv)
        tpl.assets.set data

Template.import.helpers
  assets: -> Template.instance().assets.get()
  failures: -> Template.instance().failures.get()
  complete: -> Template.instance().complete.get()
  keys: -> _.keys Template.instance().assets.get()[0]
