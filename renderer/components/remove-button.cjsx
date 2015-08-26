React = require 'react'
Actions = require '../actions'

RemoveButton = React.createClass {
  getInitialState: ->
    {isHovering: false}

  render: ->
    return (
      <div className="remove-note-btn"
      >
        <img className="remove-note-btn-img"
             src="./images/minus.png"
             onClick={@props.removeNote}
        >
        </img>
      </div>
    )
}

module.exports = RemoveButton
