{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
$ = require 'jquery'
diff = require 'diff'
utils = require './client_utils'

onChange = []

CursorPosition = [0, 0]
GlobalContext = undefined
DocumentPosition = 0 # Char position from start of document
Buffer = undefined
LocalEditor = undefined
CurrentDocument = undefined
PreviousOperation = undefined
isOperationLocal = true

_UpdateCursorPosition = (pos) ->
  #only recording local position for now
  if pos is undefined
    CursorPosition = LocalEditor.getCursorBufferPosition()
  else
    CursorPosition = pos.newBufferPosition
  DocumentPosition = Buffer.characterIndexForPosition(CursorPosition)

UpdateTitle = (title) ->
  ##  will be a little more complicated to handle
  ## I am not sure how to do it yet

UpdateText = (change) ->
  console.log change
  ## use the current text editor
  ## could use markers for this
  ## this is local only

  start = Buffer.characterIndexForPosition(change.newRange.start);
  end = Buffer.characterIndexForPosition(change.newRange.end);

  console.log start
  console.log end

  #delete old replace with new

  if not utils.doneRemoteOp()
    console.log "Updating local text"
    if change.oldText is ""
      # just do insert
      console.log "Doing Insert"
      GlobalContext.insert(start, change.newText)
    else if change.newText is ""
      # just do delete
      console.log "Doing Delete"
      GlobalContext.remove(start, Math.max 1, (end - start))
    else if (change.oldText.length > 0 and change.newText.length > 0)
      # old text is something and new text is something
      console.log "Doing Replace"
      GlobalContext.remove(start, change.oldText)
      GlobalContext.insert(start, change.newText)

  utils.updateDoneRemoteOp(false)
  _UpdateCursorPosition()

UpdateCursorPosition = (event) ->
  ## figure out the positioning of cursor in doc
  oldPos = Buffer.characterIndexForPosition(event.oldBufferPosition)
  newPos = Buffer.characterIndexForPosition(event.newBufferPosition)
  if ((not event.textChanged) and ( oldPos isnt newPos + 1))
    console.log "Doing Update becuase oldPos is : #{oldPos} and newPos is : #{newPos}"
    _UpdateCursorPosition(event)


UpdateSelectionRange = ->
  ## highlighing

UpdateDestroy = ->
  ## if the file is deleted
  for handler in onChange
    handler.displose() unless handler is undefined
  CurrentDocument.close()

_connect = (CurrentTextEditor) ->
  port = atom.config.get('collaborative-edit.Port')
  addr = atom.config.get('collaborative-edit.ServerAddress')
  docName = atom.config.get('collaborative-edit.DocumentName')

  if ( not CurrentTextEditor )
    CurrentTextEditor = atom.workspace.open(docName)
    intervalid = setInterval(
      (->
        if CurrentTextEditor.inspect().state isnt "pending"
          LocalEditor = CurrentTextEditor.inspect().value
          console.log Buffer
          console.log LocalEditor
          Buffer = LocalEditor.buffer
          clearInterval(intervalid)),
      500
    )
  else
    LocalEditor = CurrentTextEditor
    Buffer = LocalEditor.buffer

  utils.setBuffer Buffer
  console.log Buffer
  console.log LocalEditor

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        share = new sharejs.client.Connection(ws)

        share.debug = true

        CurrentDocument = share.get("Sharing", docName)

        CurrentDocument.on('after op', (op, local) ->
          ## only for remote operations
          console.log local
          console.log "op is : #{op}, Previous op is : #{PreviousOperation}"
          if local is false
            console.log "Remote Operation"
            isOperationLocal = false
            remoteUpdateDocumentContents op
        )

        CurrentDocument.subscribe()

        CurrentDocument.whenReady( ->
          console.log "Document is ready."

          if (not CurrentDocument.type)
            haveNewFile CurrentDocument
          else
            GlobalContext = CurrentDocument.createContext()
            Buffer.setTextViaDiff(CurrentDocument.getSnapshot())

          setupFileHandlers()
          _UpdateCursorPosition()

          clearInterval(interval)
        )
      catch error
        console.log error
    ),
    1000
  )

client =
  {
    connect: (CurrentTextEditor) ->
      _connect(CurrentTextEditor)

    deactivate: ->
      UpdateDestroy()
  }

haveNewFile = (doc) ->
  doc.create('text')
  text = Buffer.getText()
  GlobalContext = doc.createContext()
  GlobalContext.insert(0, text)
  DocumentPosition =
    Buffer.characterIndexForPosition(CursorPosition)

setupFileHandlers = ->
  onChange.push Buffer.onDidDestroy( UpdateDestroy )
  onChange.push LocalEditor.onDidChangeCursorPosition( UpdateCursorPosition )
  onChange.push Buffer.on('changed', UpdateText)

remoteUpdateDocumentContents = (op) ->
  if not utils.isOpTheSame(op, PreviousOperation)
    utils.HandleOp op
  console.log 'Updating Ops'
  PreviousOperation = op
  utils.updateDoneRemoteOp(false)

module.exports = client
