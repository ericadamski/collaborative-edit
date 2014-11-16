utils = require '../Utils/utils'
less = require 'less'

changehandlers = [] ## A list of atom event handlers to dispose on close ##
cursorposition = [0, 0]
cursorlist     = []
usedmarkers    = []

MARKERS = [
    'AliceBlue-marker',
    'AntiqueWhite-marker',
    'Aqua-marker',
    'Aquamarine-marker',
    'Azure-marker',
    'Blue-marker',
    'BlueViolet-marker',
    'CadetBlue-marker',
    'Chartreuse-marker',
    'Coral-marker',
    'CornflowerBlue-marker',
    'Crimson-marker',
    'Cyan-marker',
    'DarkBlue-marker',
    'DarkCyan-marker',
    'DarkGoldenRod-marker',
    'DarkGreen-marker',
    'DarkMagenta-marker',
    'DarkOliveGreen-marker',
    'DarkOrange-marker',
    'DarkOrchid-marker',
    'DarkRed-marker',
    'DarkSeaGreen-marker',
    'DarkSlateBlue-marker',
    'DarkSlateGray-marker',
    'DarkTurquoise-marker',
    'DarkViolet-marker',
    'DeepPink-marker',
    'DeepSkyBlue-marker',
    'DodgerBlue-marker',
    'FireBrick-marker',
    'ForestGreen-marker',
    'Fuchsia-marker',
    'Gainsboro-marker',
    'Gold-marker',
    'GoldenRod-marker',
    'Green-marker',
    'GreenYellow-marker',
    'HoneyDew-marker',
    'HotPink-marker',
    'IndianRed-marker',
    'Indigo-marker',
    'Lavender-marker',
    'LavenderBlush-marker',
    'LawnGreen-marker',
    'LemonChiffon-marker',
    'LightBlue-marker',
    'LightCoral-marker',
    'LightGoldenRodYellow-marker',
    'LightGreen-marker',
    'LightPink-marker',
    'LightSeaGreen-marker',
    'LightSkyBlue-marker',
    'LightSteelBlue-marker',
    'LightYellow-marker',
    'Lime-marker',
    'LimeGreen-marker',
    'Magenta-marker',
    'MidnightBlue-marker',
    'MistyRose-marker',
    'Moccasin-marker',
    'Navy-marker',
    'Olive-marker',
    'Orange-marker',
    'OrangeRed-marker',
    'Orchid-marker',
    'PapayaWhip-marker',
    'PeachPuff-marker',
    'Peru-marker',
    'Pink-marker',
    'Plum-marker',
    'PowderBlue-marker',
    'Purple-marker',
    'Red-marker',
    'RosyBrown-marker',
    'RoyalBlue-marker',
    'SeaGreen-marker',
    'SeaShell-marker',
    'Sienna-marker',
    'Silver-marker',
    'SkyBlue-marker',
    'SlateBlue-marker',
    'SlateGray-marker',
    'SpringGreen-marker',
    'SteelBlue-marker',
    'Teal-marker',
    'Thistle-marker',
    'Tomato-marker',
    'Turquoise-marker',
    'Violet-marker',
    'Yellow-marker',
    'YellowGreen-marker'
  ]

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
        data.marker = local.localeditor.decorateMarker(local.buffer.markPosition(local.buffer.positionForCharacterIndex(data.position)), {type: 'gutter', class: getnewmarker()})
        data.properties = data.marker.getProperties()
        cursorlist.push data
      else
        #update data.cursor
        tmpcursor.marker.getMarker().destroy()
        tmpcursor.position = data.position
        tmpcursor.marker = local.localeditor.decorateMarker(local.buffer.markPosition(local.buffer.positionForCharacterIndex(data.position)), tmpcursor.properties)

    _updatecursorposition: (position) ->
      if position is undefined
        cursorposition = local.localeditor.getCursorBufferPosition()
      else
        cursorposition = position.newBufferPosition
      local.documentposition = local.buffer.characterIndexForPosition cursorposition
      local.sendcursorposition local.documentposition

    updatetext: (change) ->
      newstart = local.buffer.characterIndexForPosition(change.newRange.start)
      newend = local.buffer.characterIndexForPosition(change.newRange.end)

      oldstart = local.buffer.characterIndexForPosition(change.oldRange.start)
      oldend = local.buffer.characterIndexForPosition(change.oldRange.end)

      utils.debug local.remote.doneremoteop()

      if not local.remote.doneremoteop() and change isnt local.previouschange
        local.previouschange = change
        utils.debug "Updating local text"
        if change.oldText is ""
          # just do insert
          utils.debug "Doing Insert"
          local.globalcontext.insert(oldstart, change.newText)
        else if change.newText is ""
          # just do delete
          utils.debug "Doing Delete"
          local.globalcontext.remove(oldstart, change.oldText.length)
        else if (change.oldText.length > 0 and change.newText.length > 0)
          # old text is something and new text is something
          utils.debug "Doing Replace"
          local.globalcontext.remove(oldstart, change.oldText.length)
          local.globalcontext.insert(oldstart, change.newText)

      local.remote.updatedoneremoteop(false)
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
      local.currentdocument.destroy() if local.currentdocument isnt undefined
      
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

checkismarkerused = (marker) ->
  for markers in usedmarkers
    if markers is marker
      return true

  return false

getnewmarker = ->
  random = Math.floor Math.random() * (MARKERS.length - 1)
  marker = MARKERS[random]

  while checkismarkerused marker
    marker = MARKERS[Math.random(0, MARKERS.length - 1)]

  usedmarkers.push marker

  return marker


module.exports = local
