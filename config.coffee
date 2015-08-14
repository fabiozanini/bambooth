osenv = require 'osenv'
fs = require 'fs'

getConfigFolder = ->
  fn = osenv.home() + '/.config/bambooth'

getConfigFile = ->
  fn = getConfigFolder() + '/config'

getDataFolder = ->
  fn = osenv.home() + '/.local/share/bambooth'
  # Create data folder if not present
  if not fs.existsSync(fn)
    fs.mkdirSync(fn)
  return fn

getNotesFile = ->
  getDataFolder() + '/notes.json'



class Config
  configFile: getConfigFile()
  dataFolder: getDataFolder()
  notesFile: getNotesFile()
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
    if not fs.existsSync(getConfigFolder())
      fs.mkdirSync(getConfigFolder())
    fs.writeFile(@configFile,
                 (JSON.stringify config, null, 2)
                 {'encoding': 'utf8'})


module.exports = new Config()
