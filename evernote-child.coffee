# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
config = require './config'
fs = require 'fs'



class EvernoteSync
  constructor: ->
    @addListeners()
    @getNotesLocal()

  addListeners: ->
    process.on "message", (message) =>
      switch message.action
        when "put all notes"
          @getNotesLocal(message.notes, message.callback)

  finalize: ->
    @getNotesLocal(null, "saveSyncToFile")

  failure: (reason="") ->
    if reason
      console.log "sync failed, reason: "+reason
    else
      console.log "sync failed"

  getSyncFromFile: ->
    @sync = JSON.parse fs.readFileSync config.syncFile, 'utf8'

  saveSyncToFile: ->
    sync = {
      noteIds: Object.keys(@notesLocal)
      date: Date.now()
    }
    fs.writeFile(config.syncFile,
                 JSON.stringify(sync, null, 2),
                 {'encoding': 'utf8'})

  getNotesLocal: (notes=null, callback=null) ->
    if notes == null
      process.send {
        target: "renderer"
        message: {
          action: "get all notes"
          callback: callback
        }
      }
    else
      @notesLocal = notes
      if callback
        this[callback]()

  saveNotesLocal: ->
    process.send {
      target: "renderer"
      message: {
        action: "put all notes"
        notes: @notes
      }
    }

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

  syncNotes: ->
    if not config.hasSyncFile()
      @syncNotesFirst()
    else
      @syncNotesFull()

  syncNotesFull: ->
    console.log "not implemented"

  syncNotesFirst: ->
    # First download, then upload the missing ones
    # because the calls are async, follow up is there
    # (a bit of spaghetti)
    @downloadAll()

  downloadAll: ->
    nFilter = new Evernote.NoteFilter {}
    rSpec = new Evernote.NotesMetadataResultSpec {}
    @noteStore.findNotesMetadata nFilter, 0, 100, rSpec, (error, nList) =>
      if error
        console.log error
        @failure('download list of notes')

      else
        notes = nList.notes
        @downloadStatus = {
          'total': nList.totalNotes
          'missing': nList.totalNotes
          'success': 0
          'failure': 0
        }

        @downloadNote note.guid for note in notes

  downloadNote: (guid) ->
    @noteStore.getNote guid, true, false, false, false, (error, note) =>
      @downloadStatus.missing -= 1
      if error
        console.log error
        @downloadStatus.failure += 1
        @failure('download note: '+guid)

      else
        @downloadStatus.success += 1
        noteLocal = {
          title: note.title
          content: note.content
          evernoteGuid: note.guid
          created: note.created
          updated: note.updated
        }
        process.send {
          target: "renderer"
          message: {
            "action": "new note"
            "note": noteLocal
          }
        }

      if @downloadStatus.missing == 0
        @uploadAll()

  uploadAll: ->
    # Upload local notes, so they get an evernote Guid
    @uploadStatus = {
      'total': Object.keys(@notesLocal).length
      'missing': Object.keys(@notesLocal).length
      'success': 0
      'failure': 0
    }
    for id, note of @notesLocal
      @uploadNote note

  uploadNote: (note) ->
    noteUp = new Evernote.Note()
    noteUp.title = note.title
    noteUp.content = note.content
    @noteStore.createNote noteUp, (error, noteRemote) =>
      @uploadStatus.missing -= 1
      if error
        console.log error
        @uploadStatus.failure += 1
        @failure("note upload failed: "+note.id)
      else
        process.send {
          target: "renderer"
          message: {
            action: "update note"
            id: note.id
            updates: {
              evernoteGuid: noteRemote.guid
            }
          }
        }
        @uploadStatus.success += 1

      if @uploadStatus.missing == 0
        @finalize()


main = ->
  sync = new EvernoteSync()
  sync.access()
  sync.syncNotes()

module.exports = main
