React = require 'react'
ReactLabel = require './components/react-label'
PolymerLabel = require './components/polymer-label'


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
