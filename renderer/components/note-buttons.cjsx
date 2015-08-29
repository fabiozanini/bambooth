React = require 'react'
Button = require './note-button'


NoteButtons = React.createClass
  setButtons: ->
    @buttons = @props.buttons.split(',')
    @buttonDivs = []
    if @buttons.indexOf('save') != -1
      @buttonDivs.push <Button key="save"
                               classes="save-note-btn"
                               icon="save.png"
                               callback=@props.saveCallback />
    if @buttons.indexOf('edit') != -1
      @buttonDivs.push <Button key="edit"
                               classes="edit-note-btn"
                               icon="edit.png"
                               callback=@props.editCallback />
    if @buttons.indexOf('insert-image') != -1
      @buttonDivs.push <Button key="insert-image"
                               classes="image-note-btn"
                               icon="insert-image.png"
                               callback=@props.insertImageCallback />
    if @buttons.indexOf('remove') != -1
      @buttonDivs.push <Button key="remove"
                               classes="remove-note-btn"
                               icon="minus.png"
                               callback=@props.removeCallback />


  render: ->
    @setButtons()
    return (
      <div className="note-buttons">
       {@buttonDivs}
      </div>
    )



module.exports = NoteButtons
