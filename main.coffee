app = require 'app'
BrowserWindow = require 'browser-window'

# report crashes to the Electron project
require('crash-reporter').start()

# prevent window being GC'd
mainWindow = null

main = ->
  app.on 'window-all-closed', ->
    if process.platform != 'darwin'
      app.quit()
  
  app.on 'ready', ->
    mainWindow = new BrowserWindow {
      width: 1200,
      height: 600,
      resizable: true
    }
    
    # WARN: Inspect window should be opened before loading URL
    mainWindow.openDevTools()
  
    mainWindow.loadUrl "file://"+__dirname+"/index.html"

    mainWindow.on 'closed', ->
      # deref the window
      # for multiple windows store them in an array
      mainWindow = null

module?.exports = main
