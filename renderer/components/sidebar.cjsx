React = require 'react'
Note = require './note'

Sidebar = React.createClass {
  getInitialState: ->
    return {visible: true}

  show: ->
    @setState {visible: true}

  hide: ->
    @setState {visible: false}

  toggle: ->
    if @state.visible then @hide() else @show()

  render: ->
    return (
      <div className="sidebar">
        <div className={(if @state.visible then "visible " else "") + "left"}>{@props.children}</div>
      </div>
    )
}

Main = React.createClass {
  getInitialState: ->
    return {
      shrunk: true
      notes: [
        {"content": "ciao ciao", "id": 0}
      ]

    }

  shrink: ->
    @setState {shrunk: true}

  widen: ->
    @setState {shrunk: false}

  toggleSidebar: ->
    if @state.shrunk then @widen() else @shrink()

  addNote: ->
    notes = @state.notes
    notes.push {"id": notes.length, "content": "hej!"}
    @setState {"notes": notes}

  render: ->
    return (
      <div className="main">
        <div className={(if @state.shrunk then "shrunk" else "")}>
          <section>
            {@state.notes.map (note) ->
              <Note key=note.id content=note.content />
            }
          </section>
          <footer></footer>
        </div>
      </div>
    )
}

module.exports =
  "Sidebar": Sidebar
  "Main": Main
