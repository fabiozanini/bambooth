ipc = require 'ipc'
fork = (require 'child_process').fork
BrowserWindow = require 'browser-window'
Evernote = (require 'evernote').Evernote

config = require '../config'

API_CONSUMER_KEY = "iosonofabio"
API_CONSUMER_SECRET = "7d342d169af0515e"
API_APPLICATION_NAME = "zen"
REQUEST_CALLBACK_URL = "file://"+__dirname+"/renderer/about.html"



class EvernoteSync
  constructor: ->

  hasToken: ->
    ('oauthAccessToken' of config.evernoteConfig)

  tryAccess: ->
    if not @hasToken()
      @requestToken()

    # FIXME: we should check whether the token is too old
    #else if tokenTooOld(config.evernoteConfig.oauthAccessToken)
    #  @doSomething()

    else
      @access()

  access: (force=false) ->
    # NOTE: we need to do the synchronization in a child process.
    # It is a good idea, but why does it not work otherwise?
    if 'child' of this
      console.log "parent evernote has child attribute"
      if force
        @destroyGateway()
        @child.kill()
        delete @child
        @access()

    else
      console.log "evernote parent: forking child"
      @child = fork('child.js',
                    [],
                    {cwd: __dirname, silent: false})

      @child.on 'exit', =>
        console.log "evernote parent: child exited"
        @destroyGateway()
        delete @child

      @createGateway()

  createGateway: ->
    console.log "evernote parent: creating gateway"
    @child.on "message", @childToRendererGateway
    ipc.on "evernote", @rendererToChildGateway

  destroyGateway: ->
    console.log "evernote parent: destroying gateway"
    @child.removeListener("message", @childToRendererGateway)
    ipc.removeListener("evernote", @rendererToChildGateway)

  childToRendererGateway: (msg) =>
    if msg.target == "renderer"
      console.log "evernote parent: message to renderer:"
      console.log msg.message
      @mainWindow.webContents.send "evernote", msg.message
    else
      console.log msg.message

  rendererToChildGateway: (event, message) =>
    if message == "kill"
      @killChildProcess()
    else
      console.log "evernote parent: message to child:"
      console.log message
      @child.send message

  killChildProcess: ->
    if @child
      @child.kill()
      delete @child
      console.log @child

  requestToken: ->
    @client = new Evernote.Client {
      consumerKey: API_CONSUMER_KEY
      consumerSecret: API_CONSUMER_SECRET
      sandbox: true
    }

    @client.getRequestToken(REQUEST_CALLBACK_URL,
                            @requestTokenCallback)

  requestTokenCallback: (error, oauthToken, oauthTokenSecret, results) =>
    if error
      console.log JSON.stringify error
      @openWindow {url: "file://"+__dirname+"/renderer/requestTokenFailed.html"}

    else
      @oauthToken = oauthToken
      @oauthTokenSecret = oauthTokenSecret
      
      @openWindow {
        url: @client.getAuthorizeUrl oauthToken
        title: "Allow Account Access"
      }

      @window.webContents.on 'did-get-redirect-request', @catchVerifier

  catchVerifier: (event, oldUrl, newUrl) =>
    event.preventDefault()

    spliceUrl = (url) ->
      urlData = {}
      for datum in url.split "&"
        do (datum, urlData) ->
          [key, values...] = datum.split "="
          if values
            urlData[key] = decodeURIComponent values[0]
      return urlData

    [urlBase, urlParams, other...] = newUrl.split "?"
    if urlBase != REQUEST_CALLBACK_URL
      console.log "wrong callback url from authorize: " + urlBase
      console.log "expected: " + REQUEST_CALLBACK_URL
    else
      urlData = spliceUrl urlParams
      @oauthVerifier = urlData.oauth_verifier
      @oauthAccessToken = urlData.oauth_token
      @oauthAccessSecret = urlData.oauth_token_secret

      @requestFinalToken()

  requestFinalToken: ->
    @client.getAccessToken(@oauthToken,
                           @oauthTokenSecret,
                           @oauthVerifier,
                           @requestFinalTokenCallback)

  requestFinalTokenCallback: (error, oauthAccessToken, oauthAccessTokenSecret, results) =>
    if error
      console.log error
      @window.loadUrl {url: "file://"+__dirname+"/renderer/requestFinalTokenFailed.html"}

    else
      cf = config.evernoteConfig
      cf.oauthAccessToken = oauthAccessToken
      cf.oauthAccessTokenSecret = oauthAccessTokenSecret
      cf.edamShard = results.edam_shard
      cf.edamUserId = results.edam_userId
      cf.edamExpires = results.edam_expires
      cf.edamNoteStoreUrl = results.edam_noteStoreUrl
      cf.edamWebApiUrlPrefix = results.edam_webApiUrlPrefix

      config.writeToFile()

      @window.close()

      @tryAccess()

  openWindow: (options) ->
    if options and ("title" of options)
      title = options.title
    else
      title = "Evernote Sync"

    @window = new BrowserWindow {
      width: 400
      height: 300
      resizable: false
      title: title
    }

    if process.platform != 'darwin'
      @window.setMenu null

    if options and ("url" of options)
      @window.loadUrl options.url
    

module.exports = new EvernoteSync()
