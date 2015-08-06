React = require 'react'
ReactLabel = require './components/react-label'
PolymerLabel = require './components/polymer-label'


# Menu
remote = require 'remote'
app = remote.require 'app'
Menu = remote.require 'menu'
template = [
  {
    label: "Bambooth"
    type: "submenu"
    submenu: [
      {
        label: "Quit"
        click: ->
          app.quit()
      }
    ]
  }
]
menu = Menu.buildFromTemplate template
Menu.setApplicationMenu menu


# React components
start = new Date().getTime()
setInterval ->

  React.render(
    <ReactLabel elapsed={new Date().getTime() - start} />,
    document.getElementById 'react-container'
  )

  React.render(
    <PolymerLabel elapsed={new Date().getTime() - start} />,
    document.getElementById 'polymer-container'
  )
, 50
