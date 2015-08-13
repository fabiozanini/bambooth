React = require 'react'
Actions = require '../actions'

AddButton = React.createClass {
  render: ->
    return (
      <div id="new-note-btn">
        <img id="new-note-btn-img"
             src={"./images/plus.png"}
             onClick={@props.addNote}
        >
        </img>
      </div>
    )

}

module.exports = AddButton
