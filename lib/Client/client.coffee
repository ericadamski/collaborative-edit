{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
remote = (allowUnsafeEval -> require './remote')
local = require './local'
utils = require '../Utils/utils'
hat = require 'hat'
local.setremote remote

_connect = (documentName, currentTextEditor, userId) ->
  port = atom.config.get 'collaborative-edit.Port'
  addr = atom.config.get 'collaborative-edit.ServerAddress'
  local.documentname = documentName
  local.userId = userId

  if not currentTextEditor?
    currentTextEditor = atom.workspace.open local.documentname
    intervalid = setInterval(
      (->
        if currentTextEditor.inspect().state isnt "pending"
          local.seteditor currentTextEditor.inspect().value
          clearInterval(intervalid)),
      500
    )
  else
    local.seteditor currentTextEditor

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")

        share = new sharejs.client.Connection(ws)

        share.debug = atom.config.get 'collaborative-edit.Debug'

        local.setcurrentdocument(doc = share.get "Sharing", local.documentname)

        #doc.metadata.onChange (operation, property) ->
        #  console.log property

        doc.on('after op', (op, localop) ->
          ## only for remote operations
          if not localop
            remoteupdatedocumentcontents op
        )

        doc.subscribe()

        doc.whenReady( ->
          utils.debug "Document is ready."

          #local.getsocket().onmessage = (msg) ->
          #  try
          #    if this.readyState is WebSocket.OPEN
          #      local.updateremotecursors msg
          #  catch error
          #    console.log error

          remote.setbuffer local.getbuffer()

          if (not doc.type)
            havenewfile doc
          else
            local.setglobalcontext doc.createContext()
            local.getbuffer().setTextViaDiff doc.getSnapshot()

          setupfilehandlers()
          local._updatecursorposition()

          clearInterval(interval)
        )
      catch error
        utils.debug error
    ),
    1000
  )

  return { id: userId, documentname: local.documentname }

class Client
  connect: (currentDocument, currentTextEditor) ->
    info = _connect currentDocument, currentTextEditor, hat()
    this.documentname = info.documentname
    this.id = info.id
    this.pane = getcurrentpane()
    return this

  deactivate: ->
    local.updatedestroy()

havenewfile = (doc) ->
  doc.create('text')
  text = local.getbuffer().getText()
  local.setglobalcontext(doc.createContext())
  local.getglobalcontext().insert(0, text)
  local.setdocumentposition(
    local.getbuffer().characterIndexForPosition(local.getcursorposition()))

getcurrentpane = ->
  for pane in atom.workspace.getPanes()
    for item in pane.getItems()
      if item.getTitle() is local.documentname
        return pane

setupfilehandlers = ->
  local.addhandler(getcurrentpane()?.onDidRemoveItem((event) ->
    if event.item?.getTitle() is local.documentname
      local.updatedestroy()
  ))
  local.addhandler(local.geteditor().onDidDestroy(local.updatedestroy))
  local.addhandler(
    local.geteditor().onDidChangeCursorPosition(local.updatecursorposition))
  local.getbuffer().on('changed', local.updatetext) # No need to dispose this

remoteupdatedocumentcontents = (op) ->
  if not remote.isopthesame op, local.getpreviousoperation()
    remote.handleop op
  local.setpreviousoperation op
  remote.updatedoneremoteop false

module.exports = () -> return new Client
