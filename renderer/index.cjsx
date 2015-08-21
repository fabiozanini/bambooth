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
    {notes: NoteStore.getAll()}

  componentWillMount: ->
    # Toggle sidebar via menu
    ipc.on('sidebar', (msg) =>
      switch msg
        when "toggle" then (
          @refs.sidebar.toggle()
          @refs.main.toggleSidebar()
        )
        else console.log msg
    )

  componentDidMount: ->
    NoteStore.addChangeListener @_onChange

  componentWillUnmount: ->
    NoteStore.removeChangeListener @_onChange

  _onChange: ->
    # On change, we regenerate the whole view
    # (React will take care of what needs rendering via
    # its fast diff algorithm)
    @setState {notes: NoteStore.getAll()}

  render: ->
    return (
      <div>
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
