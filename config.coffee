osenv = require 'osenv'
fs = require 'fs'

getConfigFolder = ->
  fn = osenv.home() + '/.config/bambooth'

getConfigFile = ->
  fn = getConfigFolder() + '/config'

getDataFolder = ->
  fn = osenv.home() + '/.local/share/bambooth'
  # Create folder if not present
  if not fs.existsSync(fn)
    fs.mkdirSync(fn)
  return fn

getNotesFolder = ->
  getDataFolder()

getNotesFile = ->
  fn = getNotesFolder() + '/notes.json'
  # Create if not present
  if not fs.existsSync(fn)
    fs.writeFile fn, JSON.stringify({}, null, 2), {'encoding': 'utf8'}
  return fn

getSyncFile = ->
  getDataFolder() + '/sync.json'



class Config
  configFile: getConfigFile()
  notesFolder: getNotesFolder()
  notesFile: getNotesFile()
  syncFile: getSyncFile()
  evernoteConfig: {}

  constructor: ->
    if fs.existsSync(@configFile)
      @readFromFile()

  readFromFile: ->
    config = JSON.parse fs.readFileSync @configFile, 'utf8'
    for key, value of config
      this[key] = value

  writeToFile: ->
    config = {
      notesFile: @notesFile
      evernoteConfig: @evernoteConfig
    }
    # Create config folder if not present
    if not fs.existsSync getConfigFolder()
      fs.mkdirSync getConfigFolder()
    fs.writeFile(@configFile,
                 (JSON.stringify config, null, 2)
                 {'encoding': 'utf8'})

  hasSyncFile: ->
    fs.existsSync @syncFile


module.exports = new Config()
