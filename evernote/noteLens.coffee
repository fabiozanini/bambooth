# Conversion tool from the evernote markup language (ENML)
# to something that Bambooth can digest
class NoteLens

  @ENMLToBambooth: (content) ->
    startTag = '<en-note>'
    endTag = '</en-note>'
    content.slice content.indexOf(startTag)+startTag.length,
                  content.indexOf(endTag)

  @BamboothToENML: (content) ->
    enPre = '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">'
    enPre+'<en-note>'+content+'</en-note>'

module.exports = NoteLens
