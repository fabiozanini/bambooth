fs = require 'fs'

Config = require './config'


class Data
  @loadNotes: ->
    JSON.parse fs.readFileSync Config.notesFile, 'utf8'

  @saveNotes: (notes) ->
    fs.writeFile(Config.notesFile,
                 (JSON.stringify notes, null, 2),
                 {'encoding': 'utf8'})


module.exports = Data
