React = require 'react'
Note = require './note'

Main = React.createClass {
  getInitialState: ->
    return {shrunk: true}

  shrink: ->
    @setState {shrunk: true}

  widen: ->
    @setState {shrunk: false}

  toggleSidebar: ->
    if @state.shrunk then @widen() else @shrink()

  render: ->
    # NOTE: key is used by react to ensure consistent UI
    # ref is used, in principle, to refer to the component from the top
    # noteId is used by the note itself
    return (
      <div className="main">
        <div className={(if @state.shrunk then "shrunk" else "")}>
          <section>
            {@props.notes.map (note) ->
              <Note ref=("note-"+note.id)
                    key=note.id
                    noteId=note.id
                    noteContent=note.content
              />
            }
          </section>
          <footer></footer>
        </div>
      </div>
    )
}

module.exports = Main
