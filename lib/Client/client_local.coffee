utils = require '../Utils/utils'

onChange = [] ## A list of atom event handlers to dispose on close ##

CursorPosition    = [0, 0]    ## Cursor position ##
GlobalContext     = undefined ## ShareJS editing context ##
DocumentPosition  = 0         ## Char position from start of document ##
Buffer            = undefined ## Atom buffer of local document ##
LocalEditor       = undefined ## Atom TextEditor of local document ##
CurrentDocument   = undefined ## ShareJS Document, local copy ##
PreviousOperation = undefined ## Previously applied operation ##
remote            = undefined ## Remote Handlers ##

local =
  {
    _UpdateCursorPosition: (pos) ->
      if pos is undefined
        CursorPosition = LocalEditor.getCursorBufferPosition()
      else
        CursorPosition = pos.newBufferPosition
      DocumentPosition = Buffer.characterIndexForPosition(CursorPosition)

    UpdateText: (change) ->
      newStart = Buffer.characterIndexForPosition(change.newRange.start)
      newEnd = Buffer.characterIndexForPosition(change.newRange.end)

      oldStart = Buffer.characterIndexForPosition(change.oldRange.start);
      oldEnd = Buffer.characterIndexForPosition(change.oldRange.end);

      if not remote.doneRemoteOp()
        utils.debug "Updating local text"
        if change.oldText is ""
          # just do insert
          utils.debug "Doing Insert"
          GlobalContext.insert(oldStart, change.newText)
        else if change.newText is ""
          # just do delete
          utils.debug "Doing Delete"
          GlobalContext.remove(oldStart, change.oldText.length)
        else if (change.oldText.length > 0 and change.newText.length > 0)
          # old text is something and new text is something
          utils.debug "Doing Replace"
          GlobalContext.remove(oldStart, change.oldText)
          GlobalContext.insert(oldStart, change.newText)

      remote.updateDoneRemoteOp(false)
      local._UpdateCursorPosition()
      #remote.updateSynch()

    UpdateCursorPosition: (event) ->
      oldPos = Buffer.characterIndexForPosition(event.oldBufferPosition)
      newPos = Buffer.characterIndexForPosition(event.newBufferPosition)
      if ((not event.textChanged) and ( oldPos isnt newPos + 1))
        utils.debug "Doing Update becuase oldPos is : #{oldPos} and newPos is : #{newPos}"
        local._UpdateCursorPosition(event)

    UpdateDestroy: ->
      for handler in onChange
        handler.dispose()
      CurrentDocument.close() if not CurrentDocument is undefined

    setEditor: (editor) ->
      utils.debug "Setting Editor and Buffer locally."
      LocalEditor = editor
      Buffer = LocalEditor.buffer
      utils.debug "\tBuffer : #{Buffer}"
      utils.debug "\tEditor : #{LocalEditor}"

    getEditor: ->
      return LocalEditor

    setCurrentDocument: (doc) ->
      utils.debug "Setting Document : #{doc}"
      CurrentDocument = doc

    getCurrentDocument: ->
      return CurrentDocument

    getBuffer: ->
      return Buffer

    setGlobalContext: (context) ->
      utils.debug "Setting local context : #{context}"
      GlobalContext = context

    getGlobalContext: ->
      utils.debug "Returning Context :"
      utils.debug GlobalContext
      return GlobalContext

    setPreviousOperation: (op) ->
      utils.debug "Setting Previous Op : #{op}"
      PreviousOperation = op

    getPreviousOperation: ->
      return PreviousOperation

    getDocumentPosition: ->
      return DocumentPosition

    setDocumentPosition: (pos) ->
      utils.debug "Setting Doc Position : #{pos}"
      DocumentPosition = pos

    setRemote: (r) ->
      utils.debug "Setting remote #{r}"
      remote = r

    getCursorPosition: () ->
      return CursorPosition

    addHandler: (eventHandler) ->
      onChange.push eventHandler
  }

module.exports = local