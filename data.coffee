fs = require 'fs'

Config = require './config'


class Data
  # NOTE: there is a problem sending objects to/from renderer
  @loadNotes: ->
    fs.readFileSync Config.notesFile, 'utf8'

  @saveNotes: (notesString) ->
    fs.writeFile(Config.notesFile,
                 notesString,
                 {'encoding': 'utf8'})

  @loadNote: (id) ->
    notes = JSON.parse fs.readFileSync Config.notesFile, 'utf8'
    JSON.stringify notes[id], null, 2


module.exports = Data
