React = require 'react'
Actions = require '../actions'
RemoveButton = require './remove-button'

Note = React.createClass {
  getInitialState: ->
    {
      editable: false
      content: @props.noteContent
      position: null
    }

  componentDidMount: ->
    @rect = React.findDOMNode(@refs.content).getBoundingClientRect()

  componentDidUpdate: ->
    @rect = React.findDOMNode(@refs.content).getBoundingClientRect()

  edit: ->
    @setState {editable: true}

  lock: ->
    # NOTE: this does NOT trigger a double update
    # are we sure?
    @setState {editable: false}
    Actions.updateNote @props.noteId, {content: @state.content}

  toggleEdit: ->
    if @state.editable then @lock() else @edit()

  handleChange: (event) ->
    @setState {content: event.target.value}

  _removeNote: ->
    Actions.destroyNote @props.noteId

  parseContent: (content) ->
    # TODO: make a better parser :-)
    content

  render: ->
    if not @state.editable
      return (
        <div onMouseEnter={@edit}
             onMouseLeave={@lock}
        >
          <div className="note"
               ref="content"
          >
          {@parseContent @state.content}
          </div>
        </div>
      )
    else
      return (
        <div onMouseEnter={@edit}
             onMouseLeave={@lock}
        >
          <textarea className="note"
               ref="content"
               type="text"
               value={@state.content}
               onChange={@handleChange}
          />
          <RemoveButton ref="removeButton"
                        top={@rect.top}
                        removeNote={@_removeNote}
          />
        </div>
      )
}

module.exports = Note
