fs = require 'fs'

Config = require './config'


class Data
  @loadNotes: ->
    notes = {}
    for fn in Config.getNotesFiles()
      note = JSON.parse fs.readFileSync fn, 'utf8'
      notes[note.id] = note
    JSON.stringify notes, null, 2

  @saveNotes: (notesString) ->
    notes = JSON.parse notesString
    for id, note of notes
      fs.writeFileSync(Config.getNoteFile(id),
                       JSON.stringify note,
                       {'encoding': 'utf8'})

  @loadNote: (id) ->
    fs.readFileSync Config.getNoteFile(id), 'utf8'


module.exports = Data
