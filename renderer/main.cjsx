# Communication with the main electron process
ipc = require 'ipc'

# React components
React = require 'react'
SidebarItem = require './components/sidebar-item'
Sidebar = (require './components/sidebar').Sidebar
Main = (require './components/sidebar').Main
AddButton = require './components/add-button'

ReactLabel = require './components/react-label'
PolymerLabel = require './components/polymer-label'



# Main component
App = React.createClass {
  componentWillMount: ->
    ipc.on('sidebar', (msg) =>
      switch msg
        when "toggle" then (
          @refs.sidebar.toggle()
          @refs.main.toggle()
        )
        else console.log msg
    )


  componentDidMount: ->
    @refs.addButton.setState {
      "clickCallback": -> console.log "changed!"
    }

  render: ->
    return (
      <div>
        <div>
          <Sidebar ref="sidebar">
            <SidebarItem hash="first-notebook">My Notebook</SidebarItem>
          </Sidebar>
          <Main ref="main">
            <header>
              <h1>Bambooth</h1>
            </header>
            <section>
              <div id="react-container"></div>
              <div id="polymer-container"></div>
            </section>
            <footer></footer>
          </Main>
        </div>
        <AddButton ref="addButton"/>
      </div>
    )
}

React.render <App />, document.getElementById 'app'



# Timer
start = new Date().getTime()
setInterval ->

  React.render(
    <ReactLabel elapsed={new Date().getTime() - start} />,
    document.getElementById 'react-container'
  )

  React.render(
    <PolymerLabel elapsed={new Date().getTime() - start} />,
    document.getElementById 'polymer-container'
  )
, 50
