React = require 'react'

AddButton = React.createClass {
  getInitialState: ->
    {
      "clickCallback": -> console.log "add note"
    }

  render: ->
    return (
      <div id="new-note-btn">
        <img id="new-note-btn-img"
             src={"./images/plus.png"}
             onClick={@state.clickCallback}
        >
        </img>
      </div>
    )
}

module.exports = AddButton
