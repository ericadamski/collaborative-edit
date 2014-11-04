{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
$ = require 'jquery'

onChange = []

CursorPosition = [0, 0]
GlobalContext = undefined
DocumentPosition = 0 # Char position from start of document
Buffer = undefined

UpdateTitle = (title) ->
  ##  will be a little more complicated to handle
  ## I am not sure how to do it yet

UpdateText = ->
  console.log GlobalContext
  ## use the current text editor
  ## could use markers for this
  current = atom.workspace.getActiveTextEditor()
  currentCursorPosition = current.getCursorBufferPosition()
  currentText = current.getTextInBufferRange([CursorPosition,
    currentCursorPosition]
  )
  GlobalContext.insert(DocumentPosition, currentText)

UpdateCursorPosition = (event) ->
  ## figure out the positioning of cursor in doc
  ## if text changed update text??
  CursorPosition = event.newBufferPosition
  DocumentPosition = Buffer.characterIndexForPosition(client.CursorPosition)
  console.log "DocumentPosition : #{DocumentPosition}, CursorPosition : #{CursorPosition}"


UpdateSelectionRange = ->
  ## highlighing

UpdateDestroy = ->
  ## if the file is deleted
  for handler in onChange
    handler.displose()

_connect = (CurrentTextEditor) ->
  port = atom.config.get('collaborative-edit.Port')
  addr = atom.config.get('collaborative-edit.ServerAddress')
  docName = atom.config.get('collaborative-edit.DocumentName')

  if ( not CurrentTextEditor )
    CurrentTextEditor = atom.workspace.open(docName)
    intervalid = setInterval(
      (->
        if CurrentTextEditor.inspect().state isnt "pending"
          Buffer = CurrentTextEditor.inspect().value.buffer
          console.log Buffer
          clearInterval(intervalid)),
      500
    )
  else
    Buffer = CurrentTextEditor.buffer

  setupFileHandlers()

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        console.log ws

        share = new sharejs.client.Connection(ws)

        share.debug = true

        doc = share.get("Sharing", docName)

        doc.subscribe()

        doc.whenReady( ->
          console.log "Document is ready, data : #{doc.getSnapshot()}"

          if (not doc.type)
            haveNewFile doc
          else
            GlobalContext = doc.createContext()

          console.log GlobalContext
          #Update local file display#

          clearInterval(interval)
        )
      catch error
        console.log error
    ),
    5000
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
  doc.snapshot

setupFileHandlers = ->
  onChange.push Buffer.onDidStopChanging( UpdateText )
  #onChange.push Buffer.onDidChangeCursorPosition( UpdateCursorPosition )
  onChange.push Buffer.onDidDestroy( UpdateDestroy )

module.exports = client
