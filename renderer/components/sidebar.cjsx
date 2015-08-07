React = require 'react'

Sidebar = React.createClass {
  getInitialState: ->
    return {visible: true}

  show: ->
    @setState {visible: true}

  hide: ->
    @setState {visible: false}

  toggle: ->
    if @state.visible then @hide() else @show()

  render: ->
    return (
      <div className="sidebar">
        <div className={(if @state.visible then "visible " else "") + "left"}>{@props.children}</div>
      </div>
    )
}

Main = React.createClass {
  getInitialState: ->
    return {shrunk: true}

  shrink: ->
    @setState {shrunk: true}

  widen: ->
    @setState {shrunk: false}

  toggle: ->
    if @state.shrunk then @widen() else @shrink()

  render: ->
    return (
      <div className="main">
        <div className={(if @state.shrunk then "shrunk" else "")}>
          {@props.children} 
        </div>
      </div>
    )
}

module.exports =
  "Sidebar": Sidebar
  "Main": Main
