BrowserWindow = require 'browser-window'

class About
  constructor: ->
    @window = new BrowserWindow {
      width: 400
      height: 300
      resizable: false
    }

    if process.platform != 'darwin'
      @window.setMenu null

    @window.loadUrl "file://"+__dirname+"/renderer/about.html"
    

module.exports = About
