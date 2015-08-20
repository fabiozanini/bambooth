# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
config = require '../config'
fs = require 'fs'


# Functions to communicate with the NoteStore
# via main electron process and main React App
class NoteActions
  createNote: (note) ->
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
  
  destroyNote: (id) ->
    process.send {
      target: "renderer"
      message: {
        "action": "delete note"
        "id": id
      }
    }
  
  updateNote: (id, updates) ->
    process.send {
      target: "renderer"
      message: {
        action: "update note"
        id: id
        updates: updates
      }
    }

addListener: (actionType, callback) ->
  process.on "message", (message) ->
    switch message.action
      when actionType then callback(message)


# FIXME: try to put all process.send and process.on code outside of the class
class EvernoteSync
  constructor: ->
    @actions = new NoteActions()
    @addListeners()

  addListeners: ->
    #addListener "put all notes", (message) =>
    #  @getNotesLocal(message.notes, message.callback)

    process.on "message", (message) =>
      switch message.action
        when "put all notes"
          @getNotesLocal(message.notes, message.callback)

  finalize: (missing) ->
    console.log "missing: "+missing
    if missing == 0
      console.log "finalizing"
      @getNotesLocal null, 'saveSyncAndExit'
      
  saveSyncAndExit: ->
    @saveSyncToFile()
    @killProcess()

  killProcess: ->
    console.log "child: killing process"
    process.send {
      target: "main"
      message: {
        action: "kill child evernote"
      }
    }

  failure: (message) ->
    console.log "sync failed, reason: "+message

  getSyncFromFile: ->
    @sync = JSON.parse fs.readFileSync config.syncFile, 'utf8'

  saveSyncToFile: ->
    noteIds = []
    noteGuids = []
    for id, note of @notesLocal
      noteIds.push id
      noteGuids.push note.evernoteGuid
    sync = {
      noteIds: noteIds
      noteGuids: noteGuids
      date: Date.now()
    }
    console.log sync
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
    if not ('notesLocal' of this)
      @getNotesLocal(null, 'syncNotes')

    else
      if not config.hasSyncFile()
        @syncNotesFirst()
      else
        @syncNotesFull()

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
      if error
        console.log error
        @downloadStatus.failure += 1
        @failure('download note: '+guid)

      else
        @downloadStatus.success += 1
        @actions.createNote note

      @downloadStatus.missing -= 1
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
    noteUp = new Evernote.Note {
      title: note.title
      content: note.content
    }
    @noteStore.createNote noteUp, (error, noteRemote) =>
      if error
        console.log error
        @uploadStatus.failure += 1
        @failure("note upload failed: "+note.id)
      else
        @actions.updateNote note.id, {
          evernoteGuid: noteRemote.guid
        }
        @uploadStatus.success += 1

      @uploadStatus.missing -= 1
      @finalize @uploadStatus.missing

  syncNotesFull: ->
    @getSyncFromFile()
    @compareFull()

  compareFull: ->
    nFilter = new Evernote.NoteFilter {}
    rSpec = new Evernote.NotesMetadataResultSpec {}
    @noteStore.findNotesMetadata nFilter, 0, 100, rSpec, (error, nList) =>
      if error
        @failure('download list of notes')
      else
        @notesRemote = {}
        for note in nList.notes
          @notesRemote[note.guid] = note

        @compareStatus = {
          'total': nList.totalNotes + Object.keys(@notesLocal).length
          'missing': nList.totalNotes + Object.keys(@notesLocal).length
          'success': 0
          'failure': 0
        }

        # There are several cases
        createLocal = []
        createRemote = []
        destroyLocal = []
        destroyRemote = []
        updateLocal = []
        updateRemote = []
        for id, note of @notesLocal
          # Local note without a guid, it has never seen evernote
          if not ('evernoteGuid' of note)
            createRemote.push note

          # Local note has seen evernote, is it still there?
          # If not, it was deleted remotely
          else if not (note.evernoteGuid of @notesRemote)
            destroyLocal.push note

          # Still there, update
          else
            noteRemote = @notesRemote[note.evernoteGuid]
            if note.updated > noteRemote.updated
              updateRemote.push note
            else
              noteRemote.id = note.id
              updateLocal.push noteRemote

        guids = (note.evernoteGuid for note in @notesLocal when 'evernoteGuid' of note)
        for guid, note of @notesRemote
          # Guid not present locally, was it there last time?
          if guid.indexOf(guid) == -1
            # not present last time either, it is new
            if @sync.noteGuids.indexOf(guid) == -1
              createLocal.push note

            # present last time, it is gone: in theory, one should
            # compare local delete time with remote update one;
            # in practice, if it got deleted we do not want it anymore
            else
              destroyRemote.push note

          # If the guid is present both online and local, we have listed
          # it already when looping over the local notes
        
        # Carry out tasks asynchronously
        console.log "missing: "+@compareStatus.missing
        console.log "update remotes: "+updateRemote.length
        console.log "create remotes: "+createRemote.length
        console.log "destroy remotes: "+destroyRemote.length
        console.log "update locals: "+updateLocal.length
        console.log "create locals: "+createLocal.length
        console.log "destroy locals: "+destroyLocal.length
        @updateRemote note for note in updateRemote
        @createRemote note for note in createRemote
        @destroyRemote note for note in destroyRemote
        @updateLocal note for note in updateLocal
        @createLocal note for note in createLocal
        @destroyLocal note for note in destroyLocal

  updateRemote: (note) ->
    console.log "update remotely note: "+note.id
    noteUp = new Evernote.Note {
      guid: note.evernoteGuid
      title: note.title
      updated: note.updated
      content: note.content
    }
    @noteStore.updateNote noteUp, (error, updated) =>
      if error
        console.log error
        @compareStatus.failure += 2
        @failure("update remote: "+note.id)
      else
        @compareStatus.success += 2
      @compareStatus.missing -= 2
      @finalize @compareStatus.missing

  createRemote: (note) ->
    console.log "create remotely note: "+note.id
    noteUp = new Evernote.Note {
      title: note.title
      content: note.content
    }
    @noteStore.createNote noteUp, (error, noteRemote) =>
      if error
        console.log error
        @compareStatus.failure += 1
        @failure("note upload failed: "+note.id)
      else
        @actions.updateNote note.id, {
          evernoteGuid: noteRemote.guid
        }
        @compareStatus.success += 1

      @compareStatus.missing -= 1
      @finalize @compareStatus.missing

  destroyRemote: (note) ->
    console.log "destroy remotely note: "+note.guid
    @noteStore.deleteNote note.guid, (error, updateSequenceNumber) =>
      if error
        console.log error
        @compareStatus.failure += 1
        @failure("delete remote: "+note.id)
      else
        @compareStatus.success += 1
      @compareStatus.missing -= 1
      @finalize @compareStatus.missing

  updateLocal: (note) ->
    console.log "update locally note: "+id
    @actions.updateNote id, {
      content: note.content
    }
    @compareStatus.success += 2
    @compareStatus.missing -= 2
    @finalize @compareStatus.missing

  createLocal: (note) ->
    guid = note.guid
    console.log "create locally note: "+guid
    @noteStore.getNote guid, true, false, false, false, (error, note) =>
      if error
        console.log error
        @compareStatus.failure += 1
        @failure('download note: '+guid)
      else
        @compareStatus.success += 1
        @actions.createNote note
      @compareStatus.missing -= 1
      @finalize @compareStatus.missing

  destroyLocal: (note) ->
    console.log "destroy locally note: "+note.id
    @actions.destroyNote note.id
    @compareStatus.success += 1
    @compareStatus.missing -= 1
    @finalize @compareStatus.missing


main = ->
  sync = new EvernoteSync()
  sync.access()
  sync.syncNotes()

module.exports = main
