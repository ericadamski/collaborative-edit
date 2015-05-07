utils = require '../Utils/utils'
less = require 'less'
{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share').client

#
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

    if not current_text_editor?
      current_text_editor = atom.workspace.open @document_name
      if current_text_editor.inspect().state isnt "pending"
        @editor = current_text_editor.inspect().value
    else
      @editor = current_text_editor

    @buffer = @editor.buffer

    addr = atom.config.get 'collaborative-edit.ServerAddress'
    port = atom.config.get 'collaborative-edit.ServerPort'

    console.log "Attempting to connect on ws://#{addr}:#{port}/"

    @share_instance = new sharejs.Connection(
      new WebSocket("ws://#{addr}:#{port}"))

    @status = @share_instanse?.state or 'connecting'
    @_document = undefined

    if @share_instance.socket.readyState is WebSocket.OPEN
      console.log "Here"
      @status = 'connected'
      @share_instance.debug = true#atom.config.get 'collaborative-edit.Debug'
      @_document = @share_instance.get "Sharing", @document_name
    else
      that = this

      socketConnectionInterval = setInterval(
        (->
          if that.share_instance.socket.readyState is WebSocket.OPEN
            console.log "Or there"
            that.status = 'connected'
            that.share_instance.debug = true
            #atom.config.get 'collaborative-edit.Debug'
            that._document = that.share_instance.get("Sharing",
              that.document_name)
            clearInterval socketConnectionInterval
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
      utils.debug "Doing Update becuase "+
        "oldPos is : #{oldposition} and newPos is : #{newposition}"

      if event is undefined
        @cursor_position = @editor.getCursorBufferPosition()
      else
        @cursor_position = event.newBufferPosition

      @document_position = @buffer.characterIndexForPosition @cursor_position
    #local.sendcursorposition @_document_position

  update: (change) ->
    console.log "Updating text"
    console.log change
    new_start =
      @buffer.characterIndexForPosition(change.newRange.start)
    new_end = @buffer.characterIndexForPosition(change.newRange.end)

    old_start =
      @buffer.characterIndexForPosition(change.oldRange.start)
    old_end = @buffer.characterIndexForPosition(change.oldRange.end)

    if change isnt @previous_change.remote?
      @previous_change = change
      utils.debug "Updating local text"
      if change.oldText is ""
        # just do insert
        utils.debug "Doing Insert"
        @context.insert(old_start, change.newText)
      else if change.newText is ""
        # just do delete
        utils.debug "Doing Delete"
        @context.remove(old_start, change.oldText.length)
      else if (change.oldText.length > 0 and change.newText.length > 0)
        # old text is something and new text is something
        utils.debug "Doing Replace"
        @context.remove(old_start, change.oldText.length)
        @context.insert(old_start, change.newText)

    #local._updatecursorposition()

  destroy: ->
    for handler in @change_handlers
      handler?.dispose()
    for cursor_location in @cursors
      cursor_location.marker?.getMarker()?.destroy()
    @_document?.destroy()
    #@socket.close() if local.socket?.readyState is WebSocket.OPEN

  set_editor: (editor) ->
    utils.debug "Setting Editor and Buffer locally."
    @editor = editor

  get_editor: ->
    @editor

  get_buffer: ->
    @buffer

  set_context: (context) ->
    utils.debug "Setting local context : #{context}"
    @context = context
    @buffer.setTextViaDiff @_document.getSnapshot()

  get_context: ->
    @context

  set_previous_operation: (operation) ->
    utils.debug "Setting Previous Op : #{operation}"
    @previous_operation = operation

  get_previous_operation: ->
    @previous_operation

  get_document_position: ->
    @document_position

  set_document_position: (position) ->
    utils.debug "Setting Doc Position : #{position}"
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
