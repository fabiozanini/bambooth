React = require 'react'
SidebarItem = require './components/sidebar-item'
Sidebar = require './components/sidebar'

ReactLabel = require './components/react-label'
PolymerLabel = require './components/polymer-label'


# React components


App = React.createClass {
  componentWillMount: ->
    require('ipc').on('sidebar', (msg) =>
      switch msg
        when "toggle" then @refs.sidebar.toggle()
        else console.log msg
    )

  render: ->
    return (
      <div>
        <Sidebar ref="sidebar">
          <SidebarItem hash="first-page">First Page</SidebarItem>
          <SidebarItem hash="second-page">Second Page</SidebarItem>
        </Sidebar>
        <div ref="main" className="container">
          <header>
            <h1>Bambooth</h1>
          </header>
          <section>
            <div id="react-container"></div>
            <div id="polymer-container"></div>
          </section>
          <footer></footer>
        </div>
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
