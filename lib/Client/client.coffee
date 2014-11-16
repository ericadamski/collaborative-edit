{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
remote = (allowUnsafeEval -> require './client_remote')
local = require './client_local'
utils = require '../Utils/utils'

local.setremote remote

_connect = (currenttexteditor) ->
  port = atom.config.get 'collaborative-edit.Port'
  addr = atom.config.get 'collaborative-edit.ServerAddress'
  docname = atom.config.get 'collaborative-edit.DocumentName'

  if not currenttexteditor
    currenttexteditor = atom.workspace.open docname
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

        share = new sharejs.client.Connection(ws)

        share.debug = atom.config.get 'collaborative-edit.Debug'

        local.setcurrentdocument doc = share.get("Sharing", docname)

        doc.on('after op', (op, localop) ->
          ## only for remote operations
          if not localop
            remoteupdatedocumentcontents op
        )

        doc.subscribe()

        doc.whenReady( ->
          utils.debug "Document is ready."

          local.getsocket().onmessage = (msg) ->
            local.updateremotecursors msg

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

client =
  {
    connect: (currenttexteditor) ->
      _connect currenttexteditor
      setTimeout((->
        for pane in atom.workspace.getPaneItems()
          if pane.getTitle?
            if pane.getTitle() is atom.config.get('collaborative-edit.DocumentName')
              client.currentpane = pane),
              1000
      )

    deactivate: ->
      #remote.stopSynchronize()
      local.updatedestroy()
      client.currentpane.destroy()
  }

havenewfile = (doc) ->
  doc.create('text')
  text = local.getbuffer().getText()
  local.setglobalcontext(doc.createContext())
  local.getglobalcontext().insert(0, text)
  local.setdocumentposition(local.getbuffer().characterIndexForPosition(local.getcursorposition()))

setupfilehandlers = ->
  local.addhandler(local.getbuffer().onDidDestroy(local.updatedestroy))
  local.addhandler(local.geteditor().onDidChangeCursorPosition(local.updatecursorposition))
  local.getbuffer().on('changed', local.updatetext) # No need to dispose this

remoteupdatedocumentcontents = (op) ->
  if not remote.isopthesame op, local.getpreviousoperation()
    remote.handleop op
  local.setpreviousoperation op
  remote.updatedoneremoteop false

module.exports = client
