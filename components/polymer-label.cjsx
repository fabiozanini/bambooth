React = require 'react'

module.exports = React.createClass {
  render: ->
    elapsed = Math.round this.props.elapsed  / 100
    seconds = elapsed / 10 + (if elapsed % 10 then '' else '.0')

    return <message-label data-message={seconds}></message-label>
}
