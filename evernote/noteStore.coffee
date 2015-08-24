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

  createNote: (note) ->
    console.log "action: createNote"
    noteLocal = {
      title: note.title
      content: note.content
      created: note.created
      updated: note.updated
    }
    if 'guid' of note
      noteLocal.evernoteGuid = note.guid
    process.send {
      target: "renderer"
      message: {
        "action": "new note"
        "note": noteLocal
      }
    }

  createNotes: (notes) ->
    console.log "action: createNotes"
    notesLocal = []
    for note in notes
      noteLocal = {
        title: note.title
        content: note.content
        created: note.created
        updated: note.updated
      }
      if 'guid' of note
        noteLocal.evernoteGuid = note.guid
      notesLocal.push noteLocal
    process.send {
      target: "renderer"
      message: {
        "action": "new notes"
        "notes": notesLocal
      }
    }
  
  deleteNote: (id) ->
    console.log "action: destroyNote"
    process.send {
      target: "renderer"
      message: {
        "action": "delete note"
        "id": id
      }
    }
  
  updateNote: (id, updates) ->
    console.log "action: updateNote"
    process.send {
      target: "renderer"
      message: {
        action: "update note"
        id: id
        updates: updates
      }
    }

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
