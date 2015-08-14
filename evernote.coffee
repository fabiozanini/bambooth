BrowserWindow = require 'browser-window'

config = (require './config').evernoteConfig

class EvernoteSync
  constructor: ->
    if not ('accessToken' of config)
      @openWindow()
    else
      console.log 'accessToken:' + config.accessToken

  openWindow: ->
    @window = new BrowserWindow {
      width: 400
      height: 300
      resizable: false
    }

    if process.platform != 'darwin'
      @window.setMenu null

    @window.loadUrl "file://"+__dirname+"/renderer/about.html"
    

module.exports = EvernoteSync
