Dispatcher = require '../dispatcher'
EventEmitter = require('events').EventEmitter
assign = require('object-assign')

Data = require('remote').require('./data')

_notes = {}

loadAll = ->
  _notes = JSON.parse Data.loadNotes()

putAll = (notes) ->
  _notes = {}
  for note, i in notes
    note.position = i+1
    if not ('id' of note)
      note.id = getNewId()
    _notes[note.id] = note

saveAllToFile = ->
  Data.saveNotes JSON.stringify _notes, null, 2

getNewId = ->
  crypto = require('remote').require('crypto')
  crypto.randomBytes(20).toString('hex')

create = (note) ->
  id = getNewId()
  while id of _notes
    id = getNewId()

  note.id = id
  note.position = Object.keys(_notes).length + 1
  _notes[id] = note
  saveAllToFile()
  return id

update = (id, updates) ->
  for key, value of updates
    _notes[id][key] = value
  _notes[id].updated = Date.now()
  saveAllToFile()

destroy = (id) ->
  position = _notes[id].position
  delete _notes[id]
  for id, note of _notes
    if note.position > position
      note.position -= 1
  saveAllToFile()

up = (id) ->
  note = _notes[id]
  position = note.position
  if position == 1
    return
  note.position -= 1
  for idTmp, note of _notes
    if (id != idTmp) and (note.position == position - 1)
      note.position += 1
      break

down = (id) ->
  note = _notes[id]
  position = note.position
  if position == Object.keys(_notes).length
    return
  note.position += 1
  for idTmp, note of _notes
    if (id != idTmp) and (note.position == position + 1)
      note.position -= 1
      break


NoteStore = assign({}, EventEmitter.prototype, {

  getAll: (array=false) ->
    if not array
      return _notes
    else
      notes = (note for id, note of _notes)
      notes.sort (a, b) -> if a.position > b.position then 1 else -1
      return notes


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
      create(action.note)
      NoteStore.emitChange()

    when "NOTES_CREATE"
      create(note) for note in action.notes
      NoteStore.emitChange()

    when "NOTE_UPDATE"
      update(action.id, action.updates)
      NoteStore.emitChange()

    when "NOTE_DESTROY"
      destroy(action.id)
      NoteStore.emitChange()

    when "NOTE_LOADALL"
      loadAll()
      NoteStore.emitChange()

    when "NOTE_PUTALL"
      putAll(action.notes)
      NoteStore.emitChange()

    when "NOTE_UP"
      up(action.id)
      NoteStore.emitChange()

    when "NOTE_DOWN"
      down(action.id)
      NoteStore.emitChange()

loadAll()
module.exports = NoteStore
