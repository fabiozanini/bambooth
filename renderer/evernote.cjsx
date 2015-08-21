# Communication with the main electron process
ipc = require 'ipc'

NoteStore = require './stores/notes'
Actions = require './actions'

main = ->
  ipc.on 'evernote', (msg) =>
    switch msg.action
      when "reload notes"
        Actions.reloadNotes()
      when "get all notes"
        ipc.send "evernote", {
          action: "put all notes"
          notes: NoteStore.getAll()
        }
      when "put all notes"
        Actions.putNotes msg.notes
      when "new note"
        Actions.createNote msg.note
      when "update note"
        Actions.updateNote msg.id, msg.updates
      when "delete note"
        Actions.destroyNote msg.id

module.exports = main()
