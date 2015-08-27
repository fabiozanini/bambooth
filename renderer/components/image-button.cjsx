React = require 'react'
Actions = require '../actions'

ImageButton = React.createClass
  getInitialState: ->
    {isHovering: false}

  render: ->
    return (
      <div className="note-btn image-note-btn"
      >
        <img className="note-btn-img"
             src="./images/insert-image.png"
             onClick={@props.insertImage}
        >
        </img>
      </div>
    )

module.exports = ImageButton
