Dispatcher = require '../dispatcher'
EventEmitter = require('events').EventEmitter
assign = require('object-assign')

Data = require('remote').require('./data')

_notes = Data.loadNotes()

saveAllToFile = ->
  Data.saveNotes _notes

create = (content) ->
  # Find first unused id, to keep numbers small
  ids = (note.id for note in _notes)
  ids.sort()
  id = 0
  while ids.indexOf(id) != -1
    id += 1

  # Date.now() gives back milliseconds, easy to JSON and
  # JS can reconstruct easily with Date(<ms>)
  d = Date.now()

  _notes.push {
    "id": id
    "content": content
    "dateCreate": d
    "dateModify": d
  }
  saveAllToFile()

update = (id, updates) ->
  for note in _notes
    if note.id == id
      for key, value of updates
        note[key] = value
      note.dateModify = Date.now()
      break
  saveAllToFile()

destroy = (id) ->
  for note, i in _notes
    if note.id == id
      _notes.splice(i, 1)
      break
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
