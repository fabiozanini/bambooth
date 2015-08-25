# Functions to communicate with the NoteStore
# via main electron process and main React App
class NoteStore
  constructor: ->
    process.on "message", (message) =>
      switch message.action
        when "get all notes"
          if message.error
            @getNotesCallback(message.error, null)
          else
            @getNotesCallback(null, message.notes)
        when "put all notes"
          if message.error
            @saveNotesCallback(message.error)
          else
            @saveNotesCallback(null)

  getNotes: (callback) ->
    @getNotesCallback = callback
    process.send {
      target: "renderer"
      message: {
        action: "get all notes"
      }
    }

  saveNotes: (notes, callback) ->
    @saveNotesCallback = callback
    process.send {
      target: "renderer"
      message: {
        action: "put all notes"
        notes: notes
      }
    }

module.exports = NoteStore
