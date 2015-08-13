Dispatcher = require '../dispatcher'
EventEmitter = require('events').EventEmitter
assign = require('object-assign')

Data = require('remote').require('./data')

_notes = Data.loadNotes()

saveAllToFile = ->
  Data.saveNotes _notes

create = (content) ->
  ids = (note.id for note in _notes)
  ids.sort()
  id = 0
  while ids.indexOf(id) != -1
    id += 1
  _notes.push {
    "id": id
    "content": content
  }
  saveAllToFile()

update = (id, updates) ->
  for note in _notes
    if note.id == id
      for key, value of updates
        note[key] = value
      break
  saveAllToFile()

destroy = (id) ->
  for note, i in _notes
    if note.id == id
      delete _notes[i]
  saveAllToFile()


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
