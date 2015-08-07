React = require 'react'

SidebarItem = React.createClass {
  render: ->
    return <div className="menu-item">{@props.children}</div>
}

module.exports = SidebarItem
