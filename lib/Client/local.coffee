Utils = require '../Utils/Utils'
less = require 'less'
{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share').client

# object.watch polyfill
#
# 2012-04-03
#
# By Eli Grey, http://eligrey.com
# Public Domain.
# NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.
# object.watch
if !Object::watch
  Object.defineProperty Object.prototype, 'watch',
    enumerable: false
    configurable: true
    writable: false
    value: (prop, handler) ->
      oldval = @[prop]
      newval = oldval

      getter = ->
        newval

      setter = (val) ->
        oldval = newval
        newval = handler.call(this, prop, oldval, val)

      if delete @[prop]
        # can't watch constants
        Object.defineProperty this, prop,
          get: getter
          set: setter
          enumerable: true
          configurable: true
      return

# object.unwatch
if !Object::unwatch
  Object.defineProperty Object.prototype, 'unwatch',
    enumerable: false
    configurable: true
    writable: false
    value: (prop) ->
      val = @[prop]
      delete @[prop]
      # remove accessors
      @[prop] = val
      return

# ---
# generated by js2coffee 2.0.4

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

class LocalSession
  constructor: (@document_name, current_text_editor) ->
    @change_handlers = []
    @cursor_position = [0, 0]
    @cursors         = []
    @used_markers    = []
    @editor          = undefined
    @buffer          = undefined
    @share_instance  = undefined
    @_document       = undefined

    that = this

    if not current_text_editor?
      toDispose = atom.workspace.onDidOpen (event) ->
        Utils.debug event
        that.editor = event.item
        that.buffer = that.editor.getBuffer()
        event.pane.onDidDestroy that.destroy
        toDispose.dispose()
      atom.workspace.open @document_name
    else
      @editor = current_text_editor
      @buffer = @editor?.buffer

    addr = atom.config.get 'collaborative-edit.ServerAddress'
    port = atom.config.get 'collaborative-edit.ServerPort'

    console.log "Attempting to connect on ws://#{addr}:#{port}/"

    socketConnectionInterval = setInterval(
      (->
        if that.share_instance?.socket?.readyState is WebSocket.OPEN
          that.status = 'connected'
          that.share_instance.debug =
            atom.config.get 'collaborative-edit.Debug'
          that._document = that.share_instance.get "Sharing",
            that.document_name
          clearInterval socketConnectionInterval
          that.unwatch 'share_instance'
        else
          that.share_instance = new sharejs.Connection(
            new WebSocket("ws://#{addr}:#{port}"))
      ),
      1500
    )

  update_cursor_position: (event) ->
    oldposition =
     @buffer.characterIndexForPosition event.oldBufferPosition
    newposition =
     @buffer.characterIndexForPosition event.newBufferPosition

    if ((not event.textChanged) and ( oldposition isnt newposition + 1))
      Utils.debug "Doing Update becuase "+
        "oldPos is : #{oldposition} and newPos is : #{newposition}"
      if event is undefined
        @cursor_position = @editor.getCursorBufferPosition()
      else
        @cursor_position = event.newBufferPosition

      @document_position = @buffer.characterIndexForPosition @cursor_position

  update: (change) ->
    console.log "New text is length : #{change?.newText.length}"
    console.log "Updating text"
    old_start =
      @buffer.characterIndexForPosition(change.oldRange.start)
    if change isnt @previous_change and not @previous_operation?.remote
      @previous_change = change
      Utils.debug "Updating local text"
      if change.oldText is ""
        # just do insert
        Utils.debug "Doing Insert"
        @context.insert old_start, change.newText, (error, appliedOp) ->
          console.log error
          console.log appliedOp
      else if change.newText is ""
        # just do delete
        Utils.debug "Doing Delete"
        @context.remove old_start, change.oldText.length
      else if (change.oldText isnt "" and change.newText isnt "")
        # old text is something and new text is something
        Utils.debug "Doing Replace"
        @context.remove old_start, change.oldText.length
        @context.insert old_start, change.newText
    @previous_operation = {
      'remote' : false,
      'op' : undefined,
      'time_stamp' : Utils.now() }

  destroy: ->
    console.log 'Called'
    for handler in @change_handlers
      handler?.dispose()
    for cursor_location in @cursors
      cursor_location.marker?.getMarker()?.destroy()
    @_document?.destroy()

  set_context: (context) ->
    Utils.debug "Setting local context : #{context}"
    @context = context
    try
      @buffer.setTextViaDiff @_document.getSnapshot()
    catch error
      console.error error
      console.trace

  set_previous_operation: (operation) ->
    Utils.debug "Setting Previous Op : #{operation}"
    @previous_operation = operation
    console.log operation

  get_previous_operation: ->
    @previous_operation

  get_document_position: ->
    @document_position

  set_document_position: (position) ->
    Utils.debug "Setting Doc Position : #{position}"
    @document_position = position

  add_handler: (eventhandler) ->
    @change_handlers.push eventhandler

  get_cursor_position: ->
    @cursor_position

  #sendcursorposition: (pos) ->
  # send "{\"cursorposition\":#{pos}, \"documentname\":\"#{local.socket.doc}\"}"

  # update_remote_cursors: (msg) ->
  #   if msg.data is ""
  #     return
  #
  #   data = JSON.parse msg.data
  #
  #   if typeof data.id is 'string'
  #     return
  #
  #   localcursor = getremotecursorposition data.id
  #
  #   if data.position is "close"
  #     deletecursor(localcursor)
  #   else
  #     if localcursor is undefined
  #       data.marker = local.localeditor.decorateMarker(
  #         local.buffer.markPosition(
  #           local.buffer.positionForCharacterIndex(
  #             data.position)), {type: 'gutter', class: getnewmarker()})
  #       data.properties = data.marker.getProperties()
  #       cursorlist.push data
  #     else
  #       localcursor.marker.getMarker().destroy()
  #       localcursor.position = data.position
  #       localcursor.marker = local.localeditor.decorateMarker(
  #         local.buffer.markPosition(
  #           local.buffer.positionForCharacterIndex(
  #             data.position)), localcursor.properties)


  # update_cursor_position: (event) ->
  #   oldposition =
  #  local.buffer.characterIndexForPosition event.oldBufferPosition
  #   newposition =
  #  local.buffer.characterIndexForPosition event.newBufferPosition
  #   if ((not event.textChanged) and ( oldposition isnt newposition + 1))
  #     utils.debug "Doing Update becuase "+
  #       "oldPos is : #{oldposition} and newPos is : #{newposition}"
  #     local._updatecursorposition event

  # send: (string) ->
  #   local.socket.send string if local.socket?.readyState is WebSocket.OPEN

  # setsocket: (sock) ->
  #   local.socket = sock

  # getsocket: ->
  #   return local.socket

# deletecursor = (localcursor) ->
#   index = cursorlist.indexOf localcursor
#   cursorlist.splice(index, 1)
#   localcursor.marker.getMarker().destroy()

# getremotecursorposition = (id) ->
#   for positions in cursorlist
#     if positions.id is id
#       return positions
#   return undefined

# checkismarkerused = (marker) ->
#   for markers in usedmarkers
#     if markers is marker
#       return true
#
#   return false
#
# getnewmarker = ->
#   random = Math.floor Math.random() * (MARKERS.length - 1)
#   marker = MARKERS[random]
#
#   while checkismarkerused marker
#     marker = MARKERS[Math.random(0, MARKERS.length - 1)]
#
#   usedmarkers.push marker
#
#   return marker


module.exports = LocalSession
