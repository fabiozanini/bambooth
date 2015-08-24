Dispatcher = require '../dispatcher'
EventEmitter = require('events').EventEmitter
assign = require('object-assign')

Data = require('remote').require('./data')

_notes = {}

loadAll = ->
  _notes = JSON.parse Data.loadNotes()

putAll = (notes) ->
  _notes = {}
  for note in notes
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
  _notes[id] = note
  saveAllToFile()
  return id

update = (id, updates) ->
  for key, value of updates
    _notes[id][key] = value
  _notes[id].updated = Date.now()
  saveAllToFile()

destroy = (id) ->
  delete _notes[id]
  saveAllToFile()


NoteStore = assign({}, EventEmitter.prototype, {

  getAll: (copy=false) ->
    console.log "NoteStore: get all notes"
    if not copy
      return _notes
    else
      notes = {}
      for id, _note of _notes
        note = {}
        for key, value of _note
          note[key] = value
        notes[id] = note
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

loadAll()
module.exports = NoteStore
