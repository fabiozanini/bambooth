# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
config = require './config'
Data = require './data'



class EvernoteSync
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
      for guid in noteGuids
        @noteStore.getNote guid, true, false, false, false,
        (error, note) =>
          if error
            console.log error
            return null
          @mergeSingleNote(note)

  getNotesFromFile: ->
    @notesFile = Data.loadNotes()

  mergeSingleNote: (note) ->
    found = false
    for noteLocal in @notesFile
      if noteLocal.evernoteGuid == note.guid
        found = true
        break
    if not found
      @notes.push {
        id: note.guid
        evernoteGuid: note.guid
        content: note.content
      }
    @mergedNotes += 1
    if @mergedNotes == @totalNotes
      Data.saveNotes @notes

  syncNotes: ->
    @getNotesFromFile()

    @notes = @notesFile
    
    # This call is asyncronous
    @mergeNotesFromEvernote()


main = ->
  #sync = new EvernoteSync()
  #sync.access()
  #sync.syncNotes()

  process.send {
    target: "renderer"
    message: "reload notes"
  }


module.exports = main
