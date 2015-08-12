React = require 'react'

Note = React.createClass {
  render: ->
    return (
      <div className="note">{@props.content}</div>
    )
}

module.exports = Note
