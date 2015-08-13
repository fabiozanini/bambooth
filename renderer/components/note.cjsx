React = require 'react'
Actions = require '../actions'

Note = React.createClass {
  getInitialState: ->
    {
      editable: false
      content: @props.noteContent
    }

  edit: ->
    @setState {editable: true}

  lock: ->
    # NOTE: this does NOT trigger a double update
    # are we sure?
    @setState {editable: false}
    Actions.updateNote @props.noteId, @state.content

  toggleEdit: ->
    if @state.editable then @lock() else @edit()

  handleChange: (event) ->
    @setState {content: event.target.value}

  render: ->
    if not @state.editable
      return (
        <div>
          <div className="note"
               onMouseEnter={@edit}
               onMouseLeave={@lock}
          >
          {@state.content}
          </div>
        </div>
      )
    else
      return (
        <div>
          <textarea className="note"
               ref="input"
               onMouseEnter={@edit}
               onMouseLeave={@lock}
               type="text"
               value={@state.content}
               onChange={@handleChange}
          />
        </div>
      )
}

module.exports = Note
