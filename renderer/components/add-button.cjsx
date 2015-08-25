React = require 'react'
Actions = require '../actions'

AddButton = React.createClass {
  render: ->
    return (
      <div id="new-note-btn">
        <img id="new-note-btn-img"
             src={"./images/plus.png"}
             onClick={@_addNote}
        >
        </img>
      </div>
    )

  _addNote: ->
    d = Date.now()
    Actions.createNote {
      title: "new note"
      content: "new note"
      created: d
      updated: d
    }
}

module.exports = AddButton
