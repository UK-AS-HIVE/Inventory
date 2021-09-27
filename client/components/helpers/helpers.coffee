UI.registerHelper 'commonDateFormatter', (date) ->
  # For short readable dates, Dec 25th, 2013
  moment(date).format('MMM Do, YYYY')

UI.registerHelper 'numeralDateFormatter', (date) ->
  # For short numeral dates, 12/25/2013
  moment(date).format('MM/DD/YYYY')

UI.registerHelper 'timestampFormatter', (timestamp) ->
  # For full timestamps, December 25, 2013 03:25 PM
  moment(timestamp).format('LLL')

UI.registerHelper 'displayName', (userId) ->
  Meteor.users.findOne(userId)?.displayName

UI.registerHelper 'usernameFromId', (userId) ->
  Meteor.users.findOne(userId)?.username

UI.registerHelper 'isCordova', ->
  Meteor.isCordova



UI.registerHelper 'arrayify', (obj) ->
  #Transforms objects with k/v pairs into arrays of objects so Handlebars can iterate over them properly.
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result

UI.registerHelper 'linkify', (text) ->
  # URLs starting with http://, https://, or ftp://
  
  text = escape(text)

  urlPattern = /\b(?:https?|ftp):\/\/[a-z0-9-+&@#\/%?=~_|!:,.;]*[a-z0-9-+&@#\/%=~_|]/gim
  pseudoUrlPattern = /(^|[^\/])(www\.[\S]+(\b|$))/gim
  emailAddressPattern = /[\w.]+@[a-zA-Z_-]+?(?:\.[a-zA-Z]{2,6})+/gim

  replacedText = text
            .replace(urlPattern, '<a href="$&" target="_blank">$&</a>')
            .replace(pseudoUrlPattern, '$1<a href="http://$2" target="_blank">$2</a>')
            .replace(emailAddressPattern, '<a href="mailto:$&">$&</a>')
 
  return Spacebars.SafeString replacedText

@Parsers = {}
#Scans a body of text for hashtags (#hashtag), returns an array of unique results.
@Parsers.getTags = (text) ->
  _.uniq(text.match(/\B#\S+\b/g)).map (x) ->
    x.replace('#', '') #Strip out hash

#Scans a body of text for user tags (@username), and then searches Meteor.users by username and returns an array of unique userIds.
@Parsers.getUserIds = (text) ->
  usertags = text.match(/\B\@\S+\b/g) || []
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return _.uniq users

@Parsers.getUsernames = (text) ->
  usernames = text.match(/\B\@\S+\b/g) || []
  return usernames.map (x) ->
    x.replace('@', '')

@Parsers.getStatuses = (text) ->
  _.uniq(text.match(/status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')/g)).map (x) ->
    x.replace('status:', '').replace(/"/g, '').replace(/'/g, '') #strip status: and all quotes.

@Parsers.validateEmail = (email) ->
  /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(email)

@Parsers.getTerms = (text) ->
  # Gets separate terms that do NOT match the other tokens.
  terms = text.match /"[^"]*"|status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')|\#\S+|\@\S+|[^\s]+/g
  _.difference terms, text.match(/status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')|#\S+|\@\S+/g)
   
