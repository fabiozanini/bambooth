React = require 'react'
Actions = require '../actions'

RemoveButton = React.createClass {
  getInitialState: ->
    {isHovering: false}

  render: ->
    divStyle = {
      top: @props.top
    }
    return (
      <div className="remove-note-btn"
           style={divStyle}
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
