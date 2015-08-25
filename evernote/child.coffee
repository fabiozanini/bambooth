# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
NoteStore = require './noteStore'
config = require '../config'
fs = require 'fs'


class EvernoteSync
  cases:
    'first': ['createRemote', 'createLocal']
    'full': ['createLocal', 'createRemote',
             'updateLocal', 'updateRemote',
             'deleteLocal', 'deleteRemote']

  constructor: ->
    @access()
    @syncNotes()

  access: ->
    @storeLocal = new NoteStore()

    enConfig = config.evernoteConfig
    @client = new Evernote.Client
      token: enConfig.oauthAccessToken
      sandbox: true
    @storeRemote = @client.getNoteStore enConfig.edamNoteStoreUrl

  syncNotes: ->
    console.log "child: sync notes"
    @getNotes (error) =>
      if error
        console.log error
      else
        @status =
          done: false
          sync:
            noteGuids: []
          notes: []

        if config.hasSyncFile()
          @status.syncType = 'full'
          @getSyncFromFile()
        else
          @status.syncType = 'first'

        @status.cases = @cases[@status.syncType]
        for key in @status.cases
          @status[key] =
            success: 0
            failure: 0
            done: false
            notes: []

        @syncNotesFill()

        for key in @status.cases
          @status[key].total = @status[key].notes.length
          @status[key].missing = @status[key].notes.length
          if @status[key].missing == 0
            @status[key].done = true

        # In case there is nothing to do
        @syncNotesCallback()

        for key in @status.cases
          for note in @status[key].notes
            this[key] note

  exit: ->
    console.log "child: killing process"
    process.exit(0)

  saveSyncAndExit: ->
    @saveSyncToFile()
    @exit()

  failure: (message, exit=false) ->
    console.log "sync failed, reason: "+message
    if exit
      @exit()

  getSyncFromFile: ->
    console.log "child: get sync from file"
    if not ('status' of this)
      @status = {}
    @status.oldSync = JSON.parse fs.readFileSync config.syncFile, 'utf8'

  saveSyncToFile: ->
    console.log "child: save sync to file"
    console.log @status.sync
    jsonString = JSON.stringify @status.sync, null, 2
    fs.writeFileSync config.syncFile, jsonString, {'encoding': 'utf8'}

  getNotes: (callback) ->
    @storeLocal.getNotes (error, notes) =>
      if error
        console.log "error getting local notes:"
        callback(error)
      else
        @notesLocal = notes
        nFilter = new Evernote.NoteFilter()
        rSpec = new Evernote.NotesMetadataResultSpec()
        @storeRemote.findNotesMetadata nFilter, 0, 100, rSpec, (error, noteList) =>
          if error
            console.log "error getting remote notes:"
            callback(error)
          else
            @notesRemote = {}
            for note in noteList.notes
              @notesRemote[note.guid] = note

            callback()

  syncNotesFill: ->
    if @status.syncType == 'first'
      @status.createRemote.notes = (note for id, note of @notesLocal)
      @status.createLocal.notes = (note for guid, note of @notesRemote)
    else
      for id, note of @notesLocal
        # Local note without a guid, it has never seen evernote
        if not ('evernoteGuid' of note)
          @status.createRemote.notes.push note

        # Local note has seen evernote, is it still there?
        # If not, it was deleted remotely
        else if not (note.evernoteGuid of @notesRemote)
          @status.deleteLocal.notes.push note

        # Still there, update
        else
          noteRemote = @notesRemote[note.evernoteGuid]
          if note.updated > noteRemote.updated
            @status.updateRemote.notes.push note
          else
            noteRemote.id = note.id
            @status.updateLocal.notes.push noteRemote

      guids = (note.evernoteGuid for note in @notesLocal when 'evernoteGuid' of note)
      for guid, note of @notesRemote
        # Guid not present locally, was it there last time?
        if guid.indexOf(guid) == -1
          # not present last time either, it is new
          if @status.oldSync.noteGuids.indexOf(guid) == -1
            @status.createLocal.notes.push note

          # present last time, it is gone: in theory, one should
          # compare local delete time with remote update one;
          # in practice, if it got deleted we do not want it anymore
          else
            @status.deleteRemote.notes.push note

  syncNotesCallback: ->
    console.log "child: checking status for finalize"
    console.log @status
    allDone = @status.cases.every (cas) => @status[cas].done

    if allDone
      @status.done = true
      console.log "child: checking status, going to finalize"
      @storeLocal.saveNotes @status.notes, (error) =>
        if error
          console.log error
        else
          console.log "notes saved: "
          console.log @status.notes
          @saveSyncAndExit()

  createRemote: (note) ->
    console.log "create remotely note: "+note.id
    noteUp = new Evernote.Note
      title: note.title
      content: note.content
    @storeRemote.createNote noteUp, (error, noteRemote) =>
      if error
        console.log error
        @status.createRemote.failure += 1
        @failure("note upload failed: "+note.id)
      else
        note.evernoteGuid = noteRemote.guid
        @status.notes.push note
        @status.sync.noteGuids.push note.evernoteGuid
        @status.createRemote.success += 1
      @status.createRemote.missing -= 1
      if @status.createRemote.missing == 0
        @status.createRemote.done = true
        @syncNotesCallback()

  createLocal: (noteRemote) ->
    guid = noteRemote.guid
    console.log "create locally note: "+guid
    @storeRemote.getNote guid, true, false, false, false,
    (error, noteRemote) =>
      if error
        console.log error
        @status.createLocal.failure += 1
        @failure('download note: '+guid)
      else
        note =
          title: noteRemote.title
          content: noteRemote.content
          created: noteRemote.created
          updated: noteRemote.updated
          evernoteGuid: noteRemote.guid
        @status.notes.push note
        @status.sync.noteGuids.push note.evernoteGuid
        @status.createLocal.success += 1
      @status.createLocal.missing -= 1
      if @status.createLocal.missing == 0
        @status.createLocal.done = true
        @syncNotesCallback()

  updateRemote: (note) ->
    console.log "update remotely note: "+note.id
    noteUp = new Evernote.Note
      guid: note.evernoteGuid
      title: note.title
      updated: note.updated
      content: note.content
    @storeRemote.updateNote noteUp, (error, updated) =>
      if error
        console.log error
        @status.updateRemote.failure += 1
        @failure("update remote: "+note.id)
      else
        @status.notes.push note
        @status.sync.noteGuids.push note.evernoteGuid
        @status.updateRemote.success += 1
      @status.updateRemote.missing -= 1
      if @status.updateRemote.missing == 0
        @status.updateRemote.done = true
        @syncNotesCallback()

  updateLocal: (noteRemote) ->
    guid = noteRemote.guid
    note = @notesLocal[noteRemote.id]
    console.log "update locally note: "+note.id
    @storeRemote.getNote guid, true, false, false, false,
    (error, noteRemote) =>
      if error
        console.log error
        @status.createLocal.failure += 1
        @failure('download note: '+guid)
      else
        note.content = noteRemote.content
        note.updated = noteRemote.updated
        @status.notes.push note
        @status.sync.noteGuids.push note.evernoteGuid
        @status.updateLocal.success += 1
      @status.updateLocal.missing -= 1
      if @status.updateLocal.missing == 0
        @status.updateLocal.done = true
        @syncNotesCallback()

  deleteRemote: (note) ->
    console.log "delete remotely note: "+note.guid
    @storeRemote.deleteNote note.guid, (error, updateSequenceNumber) =>
      if error
        console.log error
        @status.deleteRemote.failure += 1
        @failure("delete remote: "+note.id)
      else
        @status.deleteRemote.success += 1
      @status.deleteRemote.missing -= 1
      if @status.deleteRemote.missing == 0
        @status.deleteRemote.done = true
        @syncNotesCallback()

  deleteLocal: (note) ->
    console.log "delete locally note: "+note.id
    @status.deleteLocal.success += 1
    @status.deleteLocal.missing -= 1
    if @status.deleteLocal.missing == 0
      @status.deleteLocal.done = true
      @syncNotesCallback()


module.exports = new EvernoteSync()
