utils = require '../Utils/utils'

onChange = []

CursorPosition    = [0, 0]
GlobalContext     = undefined
DocumentPosition  = 0 # Char position from start of document
Buffer            = undefined
LocalEditor       = undefined
CurrentDocument   = undefined
PreviousOperation = undefined
remote            = undefined

local =
  {
    _UpdateCursorPosition: (pos) ->
      #only recording local position for now
      if pos is undefined
        CursorPosition = LocalEditor.getCursorBufferPosition()
      else
        CursorPosition = pos.newBufferPosition
      DocumentPosition = Buffer.characterIndexForPosition(CursorPosition)

    UpdateTitle: (title) ->
      ##  will be a little more complicated to handle
      ## I am not sure how to do it yet

    UpdateText: (change) ->
      ## use the current text editor
      ## could use markers for this
      ## this is local only

      start = Buffer.characterIndexForPosition(change.newRange.start);
      end = Buffer.characterIndexForPosition(change.newRange.end);

      #delete old replace with new

      if not remote.doneRemoteOp()
        utils.debug "Updating local text"
        if change.oldText is ""
          # just do insert
          utils.debug "Doing Insert"
          GlobalContext.insert(start, change.newText)
        else if change.newText is ""
          # just do delete
          utils.debug "Doing Delete"
          GlobalContext.remove(start, Math.max 1, (end - start))
        else if (change.oldText.length > 0 and change.newText.length > 0)
          # old text is something and new text is something
          utils.debug "Doing Replace"
          GlobalContext.remove(start, change.oldText)
          GlobalContext.insert(start, change.newText)

      remote.updateDoneRemoteOp(false)
      local._UpdateCursorPosition()

    UpdateCursorPosition: (event) ->
      ## figure out the positioning of cursor in doc
      oldPos = Buffer.characterIndexForPosition(event.oldBufferPosition)
      newPos = Buffer.characterIndexForPosition(event.newBufferPosition)
      if ((not event.textChanged) and ( oldPos isnt newPos + 1))
        utils.debug "Doing Update becuase oldPos is : #{oldPos} and newPos is : #{newPos}"
        local._UpdateCursorPosition(event)


    UpdateSelectionRange: ->
      ## highlighing

    UpdateDestroy: ->
      ## if the file is deleted
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
