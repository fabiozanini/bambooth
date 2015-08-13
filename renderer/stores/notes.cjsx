Dispatcher = require '../dispatcher'
EventEmitter = require('events').EventEmitter
assign = require('object-assign')

_notes = [
  {id: 0, content: "ciao ciao hej"}
]

create = (content) ->
  id = _notes.length
  _notes.push {
    "id": id
    "content": content
  }

update = (id, updates) ->
  for note in _notes
    if note.id == id
      for key, value of updates
        note[key] = value
      break

destroy = (id) ->
  delete _todos[id]


NoteStore = assign({}, EventEmitter.prototype, {

  getAll: -> _notes

  emitChange: ->
    @emit("change")

  addChangeListener: (callback) ->
    @on "change", callback

  removeChangeListener: (callback) ->
    @removeListener "change", callback

})


# Register callback to handle all updates
Dispatcher.register (action) ->
  switch(action.actionType)
    when "NOTE_CREATE"
      content = action.content
      create(content)
      NoteStore.emitChange()

    when "NOTE_UPDATE"
      content = action.content
      update(action.id, {content: content})
      NoteStore.emitChange()

    when "NOTE_DESTROY"
      destroy(action.id)
      NoteStore.emitChange()


module.exports = NoteStore
