# NOTE: the JS Evernote API is asynchronous. All documented functions on:
# https://dev.evernote.com/doc/reference/
# do NOT require the oauthToken as a first argument, but they DO require
# an additional callback function as a last argument.
Evernote = (require 'evernote').Evernote
config = require '../config'
fs = require 'fs'


# Functions to communicate with the NoteStore
# via main electron process and main React App
class NoteStore
  constructor: ->
    process.on "message", (message) =>
      switch message.action
        when "put all notes"
          @getNotesCallback(message.notes)

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

  saveNotes: (notes) ->
    process.send {
      target: "renderer"
      message: {
        action: "put all notes"
        notes: notes
      }
    }


class EvernoteSync
  constructor: ->
    @storeLocal = new NoteStore()
    @access()
    @syncNotes()

  exit: ->
    console.log "child: killing process"
    process.exit(0)

  saveSyncAndExit: ->
    #FIXME
    #@saveSyncToFile()
    @exit()

  finalize: (missing) ->
    console.log "child: finalize: missing: "+missing
    if missing == 0
      @storeLocal.getNotes (notes) =>
        @notes = notes
        @saveSyncAndExit()
      
  failure: (message, exit=false) ->
    console.log "sync failed, reason: "+message
    if exit
      @exit()

  getSyncFromFile: ->
    console.log "child: get sync from file"
    @sync = JSON.parse fs.readFileSync config.syncFile, 'utf8'

  saveSyncToFile: ->
    console.log "child: save sync from file"
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

  access: ->
      @client = new Evernote.Client {
        token: config.evernoteConfig.oauthAccessToken
        sandbox: true
      }

      # In theory, we do not need to repeat the noteStoreUrl,
      # but in practice it does not work without
      noteStoreUrl = config.evernoteConfig.edamNoteStoreUrl
      @storeRemote = @client.getNoteStore(noteStoreUrl)
      # FIXME: we should check that we get really access

  syncNotes: ->
    console.log "child: sync notes"
    @storeLocal.getNotes =>
      if not config.hasSyncFile()
        @syncNotesFirst()
      else
        @syncNotesFull()

  syncNotesFirst: ->
    console.log "child: sync notes first"
    # Download all and upload all, fully parallel
    @status = {
      upload: {
        success: 0
        failure: 0
        done: false
      }
      download: {
        success: 0
        failure: 0
        done: false
      }
      done: false
    }
    @downloadAll()
    @uploadAll()

  syncNotesFirstCallback: ->
    console.log "child: checking status for finalize"
    console.log @status
    if @status.upload.done and @status.download.done
      @status.done = true
      console.log "child: checking status, going to finalize"
      @finalize 0

  syncNotesFull: ->
    console.log "child: sync notes full"
    @getSyncFromFile()
    #@compareFull()

  downloadAll: ->
    console.log "child: download all notes"
    nFilter = new Evernote.NoteFilter {}
    rSpec = new Evernote.NotesMetadataResultSpec {}
    @storeRemote.findNotesMetadata nFilter, 0, 100, rSpec, (error, nList) =>
      if error
        console.log error
        @failure('download list of notes')

      else
        notes = nList.notes
        @status.download.total = notes.length
        @status.download.missing = notes.length

      @downloadNote note.guid for note in notes

  downloadNote: (guid) ->
    console.log "child: download note: "+guid
    @storeRemote.getNote guid, true, false, false, false, (error, note) =>
      if error
        console.log error
        @status.download.failure += 1
        @failure('download note: '+guid)

      else
        @status.download.success += 1
        @storeLocal.createNote note

      @status.download.missing -= 1
      if @status.download.missing == 0
        @status.download.done = true
        @syncNotesFirstCallback()

  uploadAll: ->
    console.log "child: upload all notes"
    @status.upload.done = true
    @syncNotesFirstCallback()

#    # Upload local notes, so they get an evernote Guid
#    @uploadStatus = {
#      'total': Object.keys(@notesLocal).length
#      'missing': Object.keys(@notesLocal).length
#      'success': 0
#      'failure': 0
#    }
#    for id, note of @notesLocal
#      @uploadNote note
#
#  uploadNote: (note) ->
#    noteUp = new Evernote.Note {
#      title: note.title
#      content: note.content
#    }
#    @noteStore.createNote noteUp, (error, noteRemote) =>
#      if error
#        console.log error
#        @uploadStatus.failure += 1
#        @failure("note upload failed: "+note.id)
#      else
#        @actions.updateNote note.id, {
#          evernoteGuid: noteRemote.guid
#        }
#        @uploadStatus.success += 1
#
#      @uploadStatus.missing -= 1
#      @finalize @uploadStatus.missing
#
#
#  compareFull: ->
#    nFilter = new Evernote.NoteFilter {}
#    rSpec = new Evernote.NotesMetadataResultSpec {}
#    @noteStore.findNotesMetadata nFilter, 0, 100, rSpec, (error, nList) =>
#      if error
#        @failure('download list of notes')
#      else
#        @notesRemote = {}
#        for note in nList.notes
#          @notesRemote[note.guid] = note
#
#        @compareStatus = {
#          'total': nList.totalNotes + Object.keys(@notesLocal).length
#          'missing': nList.totalNotes + Object.keys(@notesLocal).length
#          'success': 0
#          'failure': 0
#        }
#
#        # There are several cases
#        createLocal = []
#        createRemote = []
#        destroyLocal = []
#        destroyRemote = []
#        updateLocal = []
#        updateRemote = []
#        for id, note of @notesLocal
#          # Local note without a guid, it has never seen evernote
#          if not ('evernoteGuid' of note)
#            createRemote.push note
#
#          # Local note has seen evernote, is it still there?
#          # If not, it was deleted remotely
#          else if not (note.evernoteGuid of @notesRemote)
#            destroyLocal.push note
#
#          # Still there, update
#          else
#            noteRemote = @notesRemote[note.evernoteGuid]
#            if note.updated > noteRemote.updated
#              updateRemote.push note
#            else
#              noteRemote.id = note.id
#              updateLocal.push noteRemote
#
#        guids = (note.evernoteGuid for note in @notesLocal when 'evernoteGuid' of note)
#        for guid, note of @notesRemote
#          # Guid not present locally, was it there last time?
#          if guid.indexOf(guid) == -1
#            # not present last time either, it is new
#            if @sync.noteGuids.indexOf(guid) == -1
#              createLocal.push note
#
#            # present last time, it is gone: in theory, one should
#            # compare local delete time with remote update one;
#            # in practice, if it got deleted we do not want it anymore
#            else
#              destroyRemote.push note
#
#          # If the guid is present both online and local, we have listed
#          # it already when looping over the local notes
#        
#        # Carry out tasks asynchronously
#        console.log "missing: "+@compareStatus.missing
#        console.log "update remotes: "+updateRemote.length
#        console.log "create remotes: "+createRemote.length
#        console.log "destroy remotes: "+destroyRemote.length
#        console.log "update locals: "+updateLocal.length
#        console.log "create locals: "+createLocal.length
#        console.log "destroy locals: "+destroyLocal.length
#        @updateRemote note for note in updateRemote
#        @createRemote note for note in createRemote
#        @destroyRemote note for note in destroyRemote
#        @updateLocal note for note in updateLocal
#        @createLocal note for note in createLocal
#        @destroyLocal note for note in destroyLocal
#
#  updateRemote: (note) ->
#    console.log "update remotely note: "+note.id
#    noteUp = new Evernote.Note {
#      guid: note.evernoteGuid
#      title: note.title
#      updated: note.updated
#      content: note.content
#    }
#    @noteStore.updateNote noteUp, (error, updated) =>
#      if error
#        console.log error
#        @compareStatus.failure += 2
#        @failure("update remote: "+note.id)
#      else
#        @compareStatus.success += 2
#      @compareStatus.missing -= 2
#      @finalize @compareStatus.missing
#
#  createRemote: (note) ->
#    console.log "create remotely note: "+note.id
#    noteUp = new Evernote.Note {
#      title: note.title
#      content: note.content
#    }
#    @noteStore.createNote noteUp, (error, noteRemote) =>
#      if error
#        console.log error
#        @compareStatus.failure += 1
#        @failure("note upload failed: "+note.id)
#      else
#        @actions.updateNote note.id, {
#          evernoteGuid: noteRemote.guid
#        }
#        @compareStatus.success += 1
#
#      @compareStatus.missing -= 1
#      @finalize @compareStatus.missing
#
#  destroyRemote: (note) ->
#    console.log "destroy remotely note: "+note.guid
#    @noteStore.deleteNote note.guid, (error, updateSequenceNumber) =>
#      if error
#        console.log error
#        @compareStatus.failure += 1
#        @failure("delete remote: "+note.id)
#      else
#        @compareStatus.success += 1
#      @compareStatus.missing -= 1
#      @finalize @compareStatus.missing
#
#  updateLocal: (note) ->
#    console.log "update locally note: "+id
#    @actions.updateNote id, {
#      content: note.content
#    }
#    @compareStatus.success += 2
#    @compareStatus.missing -= 2
#    @finalize @compareStatus.missing
#
#  createLocal: (note) ->
#    guid = note.guid
#    console.log "create locally note: "+guid
#    @noteStore.getNote guid, true, false, false, false, (error, note) =>
#      if error
#        console.log error
#        @compareStatus.failure += 1
#        @failure('download note: '+guid)
#      else
#        @compareStatus.success += 1
#        @actions.createNote note
#      @compareStatus.missing -= 1
#      @finalize @compareStatus.missing
#
#  destroyLocal: (note) ->
#    console.log "destroy locally note: "+note.id
#    @actions.destroyNote note.id
#    @compareStatus.success += 1
#    @compareStatus.missing -= 1
#    @finalize @compareStatus.missing


module.exports = new EvernoteSync()
