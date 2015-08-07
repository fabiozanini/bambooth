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
      <div className="menu">
        <div className={(if @state.visible then "visible " else "") + "left"}>{@props.children}</div>
      </div>
    )
}

module.exports = Sidebar
