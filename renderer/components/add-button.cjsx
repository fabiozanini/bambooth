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
      content: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note>new note</en-note>"
      created: d
      updated: d
    }
}

module.exports = AddButton
