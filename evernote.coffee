BrowserWindow = require 'browser-window'
Evernote = (require 'evernote').Evernote

API_CONSUMER_KEY = "iosonofabio"
API_CONSUMER_SECRET = "7d342d169af0515e"
API_APPLICATION_NAME = "zen"
REQUEST_CALLBACK_URL = "file://"+__dirname+"/renderer/about.html"

config = require './config'


class EvernoteSync
  constructor: ->
    if not ('oauthAccessToken' of config.evernoteConfig)
      @requestToken()

    else
      console.log 'accessToken:' + config.evernoteConfig.oauthAccessToken

      @client = new Evernote.Client {
        token: config.evernoteConfig.oauthAccessToken
      }

      @noteStore = @client.getNoteStore()

      console.log @noteStore
      @noteStore.listNotebooks (error, notebooks) ->
        if error
          console.log error
        else
          console.log notebooks.length


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
    

module.exports = EvernoteSync
