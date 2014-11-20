{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
remote = (allowUnsafeEval -> require './remote')
local = require './local'
utils = require '../Utils/utils'

local.setremote remote

_connect = (documentname, currenttexteditor) ->
  port = atom.config.get 'collaborative-edit.Port'
  addr = atom.config.get 'collaborative-edit.ServerAddress'
  local.documentname = documentname

  console.log currenttexteditor

  if not currenttexteditor?
    currenttexteditor = atom.workspace.open local.documentname
    intervalid = setInterval(
      (->
        if currenttexteditor.inspect().state isnt "pending"
          local.seteditor currenttexteditor.inspect().value
          clearInterval(intervalid)),
      500
    )
  else
    local.seteditor currenttexteditor

  interval = setInterval(
    ( ->
      try
        ws = new WebSocket("ws://#{addr}:#{port}")
        local.setsocket new WebSocket("ws://#{addr}:#{port}")

        local.getsocket().onopen = () ->
          ws.send "{\"istaken\": true, \"documentname\": \"#{local.documentname}\"}"
          this.send "{\"iscursorsocket\": true, \"documentname\": \"#{local.documentname}\"}"
          this.doc = local.documentname

        share = new sharejs.client.Connection(ws)

        share.debug = atom.config.get 'collaborative-edit.Debug'

        local.setcurrentdocument doc = share.get("Sharing", local.documentname)

        doc.on('after op', (op, localop) ->
          ## only for remote operations
          if not localop
            remoteupdatedocumentcontents op
        )

        doc.subscribe()

        doc.whenReady( ->
          utils.debug "Document is ready."

          local.getsocket().onmessage = (msg) ->
            try
              if this.readyState is WebSocket.OPEN
                local.updateremotecursors msg
            catch error
              console.log error

          remote.setbuffer local.getbuffer()

          if (not doc.type)
            havenewfile doc
          else
            local.setglobalcontext doc.createContext()
            local.getbuffer().setTextViaDiff doc.getSnapshot()

          #remote.startSynchronize(local.getGlobalContext())

          setupfilehandlers()
          local._updatecursorposition()

          clearInterval(interval)
        )
      catch error
        utils.debug error
    ),
    1000
  )

  return { documentname: local.documentname }

class Client
  connect: (currentdocument, currenttexteditor) ->
    info = _connect currentdocument, currenttexteditor
    this.documentname = info.documentname
    this.pane = getcurrentpane()
    return this

  deactivate: ->
    #remote.stopSynchronize()
    local.updatedestroy()

havenewfile = (doc) ->
  doc.create('text')
  text = local.getbuffer().getText()
  local.setglobalcontext(doc.createContext())
  local.getglobalcontext().insert(0, text)
  local.setdocumentposition(local.getbuffer().characterIndexForPosition(local.getcursorposition()))

getcurrentpane = ->
  for pane in atom.workspace.getPanes()
    for item in pane.getItems()
      if item.getTitle() is local.documentname
        return pane

setupfilehandlers = ->
  local.addhandler(getcurrentpane()?.onDidRemoveItem((event) ->
    console.log event
    if event.item?.getTitle() is local.documentname
      local.updatedestroy()
  ))
  local.addhandler(local.geteditor().onDidDestroy(local.updatedestroy))
  local.addhandler(local.geteditor().onDidChangeCursorPosition(local.updatecursorposition))
  local.getbuffer().on('changed', local.updatetext) # No need to dispose this

remoteupdatedocumentcontents = (op) ->
  if not remote.isopthesame op, local.getpreviousoperation()
    remote.handleop op
  local.setpreviousoperation op
  remote.updatedoneremoteop false

module.exports = () -> return new Client
