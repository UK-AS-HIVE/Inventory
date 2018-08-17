Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
  onBeforeAction: ->
    if Meteor.isClient and not Meteor.userId()
      @render 'login'
    else
      @next()

Router.map ->
  @route 'default',
    path: '/'
    onBeforeAction: ->
      Router.go '/inventory'

  @route 'inventory',
    path: '/inventory'
    template: 'inventory'
    waitOn: ->
      Meteor.subscribe 'userData'
  
  @route 'checkouts',
    path: '/checkouts'
    template: ->
      if Roles.userIsInRole Meteor.userId(), 'admin'
        'checkoutsAdmin'
      else
        'checkoutsUser'
    waitOn: ->
      Meteor.subscribe 'userData'
  
  @route 'upcoming',
    path: '/checkouts/upcoming'
    template: 'upcoming'

  @route 'overdue',
    path: '/checkouts/overdue'
    template: 'overdue'

  @route 'import',
    path: '/import'
    template: 'import'

  @route 'userDashboard',
    path: '/my/dashboard'

  @route 'serveFile',
    path: '/file/:filename'
    where: 'server'
    action: FileRegistry.serveFile

  @route 'downloadFile',
    path: '/download/:filename'
    where: 'server'
    action: FileRegistry.serveFile
      disposition: 'attachment'

  @route 'export',
    path: '/export'
    where: 'server'
    action: ->
      cookies = {}
      _.each @request.headers?.cookie?.split(';'), (c) ->
        [cookie, value] = c.trim().split('=', 2)
        cookies[cookie] = value
      token = cookies['meteor_login_token']

      unless token? and Roles.userIsInRole Meteor.users.findOne(
        "services.resume.loginTokens.hashedToken": Accounts._hashLoginToken(token)
      )?._id, 'admin'
        @response.statusCode = 403
        @response.end 'Access denied.'
        return

      else
        filter = @params.query
        if filter.search
          filter.$text = { $search: filter.search }
          delete filter.search  
        if filter.archived
          filter.archived = true
        else
          filter.archived = {$ne: true}
        if filter.isPartOfReplacementCycle
          filter.isPartOfReplacementCycle = true

        # Mongo really doesn't like null filter values
        for k,v of filter
          if _.isUndefined(v)
            delete filter[k]
          if v is '(none)'
            filter[k] = { $exists: false }

        writeCSV.call @,
          Inventory,
          filter,
          [
            'propertyTag'
            'serialNo'
            'owner'
            'department'
            'model'
            'roomNumber'
            'building'
            'shipDate'
            'name'
            'isPartOfReplacementCycle'
            'archived'
          ],
          'inventory',
          @response
