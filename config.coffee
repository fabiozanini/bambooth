osenv = require 'osenv'
fs = require 'fs'

getDataFolder = ->
  fn = osenv.home() + '/.local/share/bambooth'
  # Create data folder if not present
  if not fs.existsSync(fn)
    fs.mkdirSync(fn)
  return fn

getNotesFile = ->
  getDataFolder() + '/notes.json'


Config = {
  dataFolder: getDataFolder()
  notesFile: getNotesFile()
}

module.exports = Config
