rootUrl = Meteor.absoluteUrl()
if rootUrl[rootUrl.length-1] == '/'
  rootUrl = rootUrl.substr(0, rootUrl.length-1)
fromEmail = Meteor.settings.email?.fromEmail || "triagebot@as.uky.edu"
fromDomain = fromEmail.split('@').pop()

makeMessageID = (ticketId) ->
  '<'+Date.now()+'.'+ticketId+'@'+fromDomain+'>'

# Sends notifications to users about ticket updates.
class @NotificationJob extends Job
  handleJob: ->
    ticketNumber = Tickets.findOne(@params.ticketId).ticketNumber
    html = @params.html + "<br><br><a href='#{rootUrl}/ticket/#{ticketNumber}'>View the ticket here.</a>"
    if @params.to or @params.bcc.length > 0
      Email.send
        from: @params.fromEmail || fromEmail
        to: @params.toEmail
        bcc: @params.bcc
        subject: @params.subject
        html: html
        headers:
          'Message-ID': makeMessageID @params.ticketId


class @WarrantyLookupJob extends Job
  handleJob: ->
    item = Inventory.findOne @params.inventoryId
    if item.model.toLowerCase().startsWith('dell ')
      res = HTTP.get "https://sandbox.api.dell.com/support/assetinfo/v4/getassetwarranty/#{item.serialNo}",
        headers:
          accept: 'application/json'
          apikey: Meteor.settings.apiKeys.dellWarranty
      console.log "Got warranty info for #{item.model} (#{item.serialNo})...", res.data
      Inventory.update item._id,
        $set:
          warrantyInfo: res.data

