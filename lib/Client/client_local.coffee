utils = require '../Utils/utils'

changehandlers = [] ## A list of atom event handlers to dispose on close ##
cursorposition = [0, 0]
cursorlist     = []

local =
  {
    sendcursorposition: (pos) ->
      local.socket.send("{\"cursorposition\": #{pos}}") if local.socket.readyState is WebSocket.OPEN

    updateremotecursors: (msg) ->
      data = JSON.parse msg.data

      if typeof data.id is 'string'
        return

      tmpcursor = getremotecursorposition data.id
      if tmpcursor is undefined
        #create new cursor assign it to data.cursor
        cursorlist.push data
      else
        #update data.cursor
        tmpcursor.position = data.position

      console.log cursorlist

    _updatecursorposition: (position) ->
      if position is undefined
        cursorposition = local.localeditor.getCursorBufferPosition()
      else
        cursorposition = position.newBufferPosition
      local.documentposition = local.buffer.characterIndexForPosition cursorposition
      local.sendcursorposition local.documentposition

    updatetext: (change) ->
      newstart = local.buffer.characterIndexForPosition change.newRange.start
      newend = local.buffer.characterIndexForPosition change.newRange.end

      oldstart = local.buffer.characterIndexForPosition change.oldRange.start
      oldend = local.buffer.characterIndexForPosition change.oldRange.end

      if not local.remote.doneremoteop()
        utils.debug "Updating local text"
        if change.oldText is ""
          # just do insert
          utils.debug "Doing Insert"
          local.globalcontext.insert oldstart, change.newText
        else if change.newText is ""
          # just do delete
          utils.debug "Doing Delete"
          local.globalcontext.remove oldstart, change.oldText.length
        else if (change.oldText.length > 0 and change.newText.length > 0)
          # old text is something and new text is something
          utils.debug "Doing Replace"
          local.globalcontext.remove oldstart, change.oldText.length
          local.globalcontext.insert oldstart, change.newText

      local.remote.updatedoneremoteop false
      local._updatecursorposition()
      #remote.updateSynch()

    updatecursorposition: (event) ->
      oldposition = local.buffer.characterIndexForPosition event.oldBufferPosition
      newposition = local.buffer.characterIndexForPosition event.newBufferPosition
      if ((not event.textChanged) and ( oldposition isnt newposition + 1))
        utils.debug "Doing Update becuase oldPos is : #{oldposition} and newPos is : #{newposition}"
        local._updatecursorposition event

    updatedestroy: ->
      for handler in changehandlers
        handler.dispose()
      local.currentdocument?.close()
    seteditor: (editor) ->
      utils.debug "Setting Editor and Buffer locally."
      local.localeditor = editor
      local.buffer = local.localeditor.buffer

    geteditor: ->
      return local.localeditor

    setcurrentdocument: (doc) ->
      utils.debug "Setting Document : #{doc}"
      local.currentdocument = doc

    getcurrentdocument: ->
      return local.currentdocument

    getbuffer: ->
      return local.buffer

    setglobalcontext: (context) ->
      utils.debug "Setting local context : #{context}"
      local.globalcontext = context

    getglobalcontext: ->
      return local.globalcontext

    setpreviousoperation: (operation) ->
      utils.debug "Setting Previous Op : #{operation}"
      local.previousoperation = operation

    getpreviousoperation: ->
      return local.previousoperation

    getdocumentposition: ->
      return local.documentposition

    setdocumentposition: (position) ->
      utils.debug "Setting Doc Position : #{position}"
      local.documentposition = position

    setremote: (remotehandler) ->
      local.remote = remotehandler

    getcursorposition: ->
      return cursorposition

    addhandler: (eventhandler) ->
      changehandlers.push eventhandler

    setsocket: (sock) ->
      local.socket = sock

    getsocket: ->
      return local.socket
  }

getremotecursorposition = (id) ->
  for positions in cursorlist
      if positions.id is id
        return positions
  return undefined

module.exports = local
