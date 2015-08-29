# Communication with the main electron process
ipc = require 'ipc'

# React components
React = require 'react'
SidebarItem = require './components/sidebar-item'
Sidebar = require './components/sidebar'
Main = require './components/main'
AddButton = require './components/add-button'
Note = require './components/note'

# Flux components
Dispatcher = require './dispatcher'
NoteStore = require './stores/notes'
Actions = require './actions'
require './evernote'



App = React.createClass {
  getInitialState: ->
    {
      notes: NoteStore.getAll(array=true)
      curtain: false
    }

  componentDidMount: ->
    NoteStore.addChangeListener @_onChange

    # Toggle sidebar via menu
    ipc.on 'sidebar', (msg) =>
      switch msg
        when "toggle"
          if @state.curtain
            console.log "cannot change sidebar during curtain"
          else
            @refs.sidebar.toggle()
            @refs.main.toggleSidebar()
        else console.log msg
        
    ipc.on 'curtain', (msg) =>
      switch msg
        when true then @setState {curtain: true}
        when false then @setState {curtain: false}

  componentWillUnmount: ->
    NoteStore.removeChangeListener @_onChange

  _onChange: ->
    # On change, we regenerate the whole view
    # (React will take care of what needs rendering via
    # its fast diff algorithm)
    @setState {notes: NoteStore.getAll(array=true)}

  render: ->
    return (
      <div>
        <div id="curtain"
             className={if @state.curtain then "active" else ""}/>
        <div>
          <Sidebar ref="sidebar">
            <SidebarItem hash="first-notebook">My Notebook</SidebarItem>
          </Sidebar>
          <Main ref="main" notes={@state.notes}>
          </Main>
        </div>
        <AddButton ref="addButton" />
      </div>
    )

    # FIXME: we should focus on the new note, but somehow there
    # are synchronicity problems with render()

}

React.render <App />, document.getElementById 'app'
