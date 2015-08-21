app = require 'app'
BrowserWindow = require 'browser-window'
Menu = require 'menu'

# report crashes to the Electron project
require('crash-reporter').start()

# Other modules for the main process
About = require './about'
EvernoteSync = require './evernote/main'

# prevent from being GC'd
mainWindow = null

main = ->
  app.on 'window-all-closed', ->
    if process.platform != 'darwin'
      EvernoteSync.killChildProcess()
      app.quit()
  
  app.on 'ready', ->
    mainWindow = new BrowserWindow {
      width: 1200
      height: 600
      resizable: true
    }

    EvernoteSync.mainWindow = mainWindow

    Menu.setApplicationMenu Menu.buildFromTemplate [
      {
        label: "Bambooth"
        submenu: [
          {
            label: "Toggle sidebar"
            accelerator: 'CmdOrCtrl+B'
            click: ->
              mainWindow.webContents.send "sidebar", "toggle"
          },
          {
            label: "Sync with Evernote"
            accelerator: 'CmdOrCtrl+S'
            click: ->
              EvernoteSync.tryAccess()
          },
          {
            label: "About"
            click: ->
              new About()
          },
          {
            label: "Quit"
            click: ->
              EvernoteSync.killChildProcess()
              app.quit()
          }
        ]
      }
    ]
    
    # WARN: Inspect window should be opened before loading URL
    #mainWindow.openDevTools()
  
    mainWindow.loadUrl "file://"+__dirname+"/renderer/index.html"

    mainWindow.on 'closed', ->
      # deref the window
      # for multiple windows store them in an array
      mainWindow = null


module?.exports = main
