Dispatcher = require './dispatcher'

Actions = {
  createNote: (note) ->
    Dispatcher.dispatch {
      actionType: "NOTE_CREATE"
      note: note
    }

  updateNote: (id, updates) ->
    Dispatcher.dispatch {
      actionType: "NOTE_UPDATE"
      id: id
      updates: updates
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

  putNotes: (notes) ->
    Dispatcher.dispatch {
      actionType: "NOTE_PUTALL"
      notes: notes
    }
}

module.exports = Actions
