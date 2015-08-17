# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
config = require './config'
Data = require './data'



class EvernoteSync
  success: ->
    @saveNotesToFile()
    process.send {
      target: "renderer"
      message: "reload notes"
    }

  failure: ->
    console.log "sync failed"

  getNotesFromFile: ->
    @notesFile = Data.loadNotes()

  saveNotesToFile: ->
    Data.saveNotes @notes

  access: ->
      @client = new Evernote.Client {
        token: config.evernoteConfig.oauthAccessToken
        sandbox: true
      }

      # In theory, we do not need to repeat the noteStoreUrl,
      # but in practice it does not work without
      noteStoreUrl = config.evernoteConfig.edamNoteStoreUrl
      @noteStore = @client.getNoteStore(noteStoreUrl)
      # FIXME: we should check that we get really access

  mergeNotesFromEvernote: ->
    noteFilter = new Evernote.NoteFilter()
    options = new Evernote.NotesMetadataResultSpec {
      includeTitle: true
      includeContentLength: true
      includeCreated: true
      includeUpdated: true
      includeDeleted: true
    }

    @noteStore.findNotesMetadata noteFilter, 0, 100, options,
    (error, result) =>
      if error
        console.log error
        return null

      noteGuids = (note.guid for note in result.notes)
      @totalNotes = noteGuids.length
      @mergedNotes = 0

      if @totalNotes == 0
        @mergeNotesToEvernote()
        return

      for guid in noteGuids
        @noteStore.getNote guid, true, false, false, false,
        (error, note) =>
          if error
            console.log error
            return null
          @mergeSingleNoteFromEvernote(note)

  mergeNotesToEvernote: ->
    for note in @notesFile
      if not ('guid' of note)
        @addSingleNoteToEvernote(note)

    console.log "add missing notes"

    # FIXME: we should remove notes too...
    @success()

  mergeSingleNoteFromEvernote: (note) ->
    found = false
    for noteLocal in @notesFile
      if noteLocal.evernoteGuid == note.guid
        found = true
        break

    if not found
      @notes.push {
        id: note.guid
        evernoteGuid: note.guid
        title: note.title
        content: note.content
        created: note.created
        updated: note.updated
      }
    else
      if noteLocal.update >= note.update
        @updateSingleNoteToEvernote(noteLocal)
      else
        noteLocal.update = note.update
        noteLocal.content = note.content

    @mergedNotes += 1
    if @mergedNotes == @totalNotes
      @mergeNotesToEvernote()

  updateSingleNoteToEvernote: (note) ->
    noteUp = new Evernote.Note {
      guid: note.guid
      title: note.title
      updated: note.updated
      content: note.content
    }
    @noteStore.updateNote noteUp, (error, metadata) ->
      if error
        console.log error
      console.log "updated in evernote"
      console.log "guid: "+note.guid

  addSingleNoteToEvernote: (note) ->
    # FIXME: this is not the way to do it ;-)
    if note.content[..4] != '<?xml'
      note.content = '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">\n<en-note><div>'+note.content+'</div></en-note>'

    noteUp = new Evernote.Note {
      title: note.title
      updated: note.updated
      content: note.content
    }
    @noteStore.createNote noteUp, (error, noteRemote) =>
      if error
        console.log error
      console.log "created in evernote"
      console.log "guid: "+noteRemote.guid

      # FIXME: this does not work
      note.guid = noteRemote.guid

  syncNotes: ->
    @getNotesFromFile()

    @notes = @notesFile
    
    # This call is asyncronous
    @mergeNotesFromEvernote()


main = ->
  sync = new EvernoteSync()

  sync.access()
  sync.syncNotes()



module.exports = main
