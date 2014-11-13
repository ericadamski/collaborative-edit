{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
remote = (allowUnsafeEval -> require './client_remote')
local = require './client_local'
utils = require '../Utils/utils'

CurrentPane = undefined

local.setRemote remote

_connect = (CurrentTextEditor) ->
  port = atom.config.get('collaborative-edit.Port')
  addr = atom.config.get('collaborative-edit.ServerAddress')
  docName = atom.config.get('collaborative-edit.DocumentName')

  if ( not CurrentTextEditor )
    CurrentTextEditor = atom.workspace.open(docName)
    intervalid = setInterval(
      (->
        if CurrentTextEditor.inspect().state isnt "pending"
          local.setEditor CurrentTextEditor.inspect().value
          clearInterval(intervalid)),
      500
    )
  else
    local.setEditor CurrentTextEditor

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        share = new sharejs.client.Connection(ws)

        share.debug = true

        local.setCurrentDocument share.get("Sharing", docName)

        doc = local.getCurrentDocument()

        doc.on('after op', (op, localOp) ->
          ## only for remote operations
          if localOp is false
            utils.debug "Remote Operation"
            remoteUpdateDocumentContents op
        )

        doc.subscribe()

        doc.whenReady( ->
          utils.debug "Document is ready."

          remote.setBuffer local.getBuffer()

          if (not doc.type)
            haveNewFile doc
          else
            local.setGlobalContext doc.createContext()
            local.getBuffer().setTextViaDiff(doc.getSnapshot())

          remote.startSynchronize(local.getGlobalContext())
          
          setupFileHandlers()
          local._UpdateCursorPosition()

          clearInterval(interval)
        )
      catch error
        utils.debug error
    ),
    1000
  )

client =
  {
    connect: (CurrentTextEditor) ->
      _connect(CurrentTextEditor)
      for pane in atom.workspace.getPaneItems()
        if pane.getTitle isnt undefined
          if pane.getTitle() is atom.config.get('collaborative-edit.DocumentName')
            CurrentPane = pane

    deactivate: ->
      remote.stopSynchronize()
      local.UpdateDestroy()
      CurrentPane.destroy()
  }

haveNewFile = (doc) ->
  doc.create('text')
  text = local.getBuffer().getText()
  local.setGlobalContext(doc.createContext())
  local.getGlobalContext().insert(0, text)
  local.setDocumentPosition(local.getBuffer()
    .characterIndexForPosition(local.getCursorPosition()))

setupFileHandlers = ->
  local.addHandler(local.getBuffer().onDidDestroy( local.UpdateDestroy ))
  local.addHandler(local.getEditor()
    .onDidChangeCursorPosition( local.UpdateCursorPosition ))
  local.getBuffer().on('changed', local.UpdateText) # No need to dispose this

remoteUpdateDocumentContents = (op) ->
  if not remote.isOpTheSame(op, local.getPreviousOperation())
    remote.HandleOp op
  local.setPreviousOperation op
  remote.updateDoneRemoteOp(false)

module.exports = client
