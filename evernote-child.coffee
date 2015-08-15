Evernote = (require 'evernote').Evernote
config = require './config'


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

      # Test call
      @noteStore.listNotebooks (error, notebooks) ->
        if error
          console.log error
        else
          console.log notebooks


main = ->
  sync = new EvernoteSync()
  sync.access()


module.exports = main
