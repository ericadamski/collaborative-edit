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

UpdateTitle = (title) ->
  ##  will be a little more complicated to handle
  ## I am not sure how to do it yet

UpdateText = ->
  ## use the current text editor
  ## could use markers for this
  ## this is local only
  console.log "Updating local text"
  editorPosition = LocalEditor.getCursorBufferPosition()
  currentText = LocalEditor.getTextInBufferRange([CursorPosition,
    editorPosition]
  )
  console.log GlobalContext
  if editorPosition < CursorPosition
    #Delete
    GlobalContext.remove(DocumentPosition, 1)
  else
    #insert
    GlobalContext.insert(DocumentPosition, currentText)

UpdateCursorPosition = (event) ->
  ## figure out the positioning of cursor in doc
  ## if text changed update text??
  oldPos = Buffer.characterIndexForPosition(event.oldBufferPosition)
  newPos = Buffer.characterIndexForPosition(event.newBufferPosition)
  if ((not event.textChanged) and ( oldPos isnt newPos + 1))
    CursorPosition = event.newBufferPosition
    DocumentPosition = Buffer.characterIndexForPosition(CursorPosition)
    console.log "DocumentPosition new: #{DocumentPosition} old: #{event.oldBufferPosition}, CursorPosition : #{CursorPosition}"


UpdateSelectionRange = ->
  ## highlighing

UpdateDestroy = ->
  ## if the file is deleted
  for handler in onChange
    handler.displose()
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
          clearInterval(intervalid)),
      500
    )
  else
    LocalEditor = CurrentTextEditor

  Buffer = LocalEditor.buffer
  setupFileHandlers()

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        share = new sharejs.client.Connection(ws)

        share.debug = true

        CurrentDocument = share.get("Sharing", docName)

        CurrentDocument.on('op', (op, local) ->
          console.log op
          console.log local
        )

        CurrentDocument.on('after op', (op, local) ->
          ## only for remote operations
          console.log local
          console.log "op is : #{op}, Previous op is : #{PreviousOperation}"
          if local is false
            console.log "Remote Operation"
          remoteUpdateDocumentContents op if local is false
        )

        CurrentDocument.subscribe()

        CurrentDocument.whenReady( ->
          console.log "Document is ready."

          if (not CurrentDocument.type)
            haveNewFile CurrentDocument
          else
            GlobalContext = CurrentDocument.createContext()
            Buffer.setTextViaDiff(CurrentDocument.getSnapshot())

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
  }

haveNewFile = (doc) ->
  doc.create('text')
  text = Buffer.getText()
  GlobalContext = doc.createContext()
  GlobalContext.insert(0, text)
  DocumentPosition =
    Buffer.characterIndexForPosition(CursorPosition)

setupFileHandlers = ->
  onChange.push Buffer.onDidStopChanging( UpdateText )
  onChange.push Buffer.onDidDestroy( UpdateDestroy )
  onChange.push LocalEditor.onDidChangeCursorPosition( UpdateCursorPosition )

remoteUpdateDocumentContents = (op) ->
  if not utils.isTheSame(op, PreviousOperation)
    if utils.isDelete(op)
      # Backspace
      position = utils.getOpPosition(PreviousOperation)
      if position isnt undefined
        startDel = Buffer.positionForCharacterIndex(position)
        endDel = Buffer.positionForCharacterIndex(position - utils.getDeleteLength(op))
        Buffer.delete([startDel, endDel])
    else
      # Insert
      position = utils.getOpPosition(op)
      text = utils.getOpData(op)
      setTimeout(
        (->
          if position isnt undefined
            index = Buffer.positionForCharacterIndex(position)
            textIndex = Buffer.positionForCharacterIndex(position + text.length)
            console.log Buffer.setTextInRange([index, textIndex],
              text)
        ), 500)
  PreviousOperation = op


module.exports = client
