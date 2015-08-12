React = require 'react'

Note = React.createClass {
  getInitialState: ->
    {editable: false}

  edit: ->
    @setState {editable: true}

  lock: ->
    # FIXME: we should save the new content of the note, but
    # we probably want to do it via a global dispatcher because
    # notes are now props of the parent and we do not want deep
    # components to know too much:
    # dispatch main, ->
    #   updateNote @props.id, @children[0].value
    @setState {editable: false}

  toggleEdit: ->
    if @state.editable then @lock() else @edit()

  render: ->
    c = @props.content
    return (
      <div className="note"
           onMouseEnter={@edit}
           onMouseLeave={@lock}
      >
        {if @state.editable then <textarea ref="input" type="text" readOnly=false defaultValue=c /> else c}
      </div>
    )
}

module.exports = Note
