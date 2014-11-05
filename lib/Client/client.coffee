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
CurrentDocument = undefined

UpdateTitle = (title) ->
  ##  will be a little more complicated to handle
  ## I am not sure how to do it yet

UpdateText = ->
  ## use the current text editor
  ## could use markers for this
  ## this is local only
  current = atom.workspace.getActiveTextEditor()
  currentText = current.getTextInBufferRange([CursorPosition,
    Buffer.getEndPosition()]
  )
  GlobalContext.insert(DocumentPosition, currentText)

UpdateCursorPosition = (event) ->
  ## figure out the positioning of cursor in doc
  ## if text changed update text??
  if not event.textChanged
    CursorPosition = event.newBufferPosition
    DocumentPosition = Buffer.characterIndexForPosition(CursorPosition)
    console.log "DocumentPosition : #{DocumentPosition}, CursorPosition : #{CursorPosition}"


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
          onChange.push CurrentTextEditor.inspect().value.onDidChangeCursorPosition( UpdateCursorPosition )
          Buffer = CurrentTextEditor.inspect().value.buffer
          clearInterval(intervalid)),
      500
    )
  else
    onChange.push CurrentTextEditor.onDidChangeCursorPosition( UpdateCursorPosition )
    Buffer = CurrentTextEditor.buffer

  setupFileHandlers()

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        share = new sharejs.client.Connection(ws)

        share.debug = true

        CurrentDocument = share.get("Sharing", docName)

        CurrentDocument.on('after op', (op) ->
          #console.log "Operation #{op} has just been preformed."
          position = utils.getOpPosition(op)
          text = utils.getOpData(op)
          index = Buffer.positionForCharacterIndex(position)
          setTimeout(
            (->
              if position isnt undefined
                Buffer.setTextInRange([index, text.length],
                  text)
            ), 2000)
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

module.exports = client
