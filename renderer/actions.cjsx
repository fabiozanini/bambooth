Dispatcher = require './dispatcher'

Actions = {
  createNote: (content) ->
    Dispatcher.dispatch {
      actionType: "NOTE_CREATE"
      content: content
    }

  updateNote: (id, content) ->
    Dispatcher.dispatch {
      actionType: "NOTE_UPDATE"
      id: id
      content: content
    }

  destroyNote: (id) ->
    Dispatcher.dispatch {
      actionType: "NOTE_DESTROY"
      id: id
    }

  reloadNotes: ->
    Dispatcher.dispatch {
      actionType: "NOTE_LOADALL"
    }
}

module.exports = Actions
