React = require 'react'

Button = React.createClass
  render: ->
    return (
      <div className={"note-btn "+@props.classes}
      >
        <img className="note-btn-img"
             src={"./images/"+@props.icon}
             onClick={@props.callback}
        >
        </img>
      </div>
    )

module.exports = Button
