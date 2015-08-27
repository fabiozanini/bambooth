React = require 'react'
ImageButton = require './image-button'
RemoveButton = require './remove-button'


NoteButtons = React.createClass
  componentWillMount: ->
    @buttons = @props.buttons.split(',')
    @buttonDivs = []
    if @buttons.indexOf('insert-image') != -1
      @buttonDivs.push <ImageButton key="insert-image"
                                    insertImage=@props.insertImage />
    if @buttons.indexOf('remove') != -1
      @buttonDivs.push <RemoveButton key="remove"
                                     removeNote=@props.removeNote />


  render: ->
    return (
      <div className="note-buttons">
       {@buttonDivs}
      </div>
    )



module.exports = NoteButtons
