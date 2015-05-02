{allowUnsafeEval} = require 'loophole'
utils   = require '../Utils/utils'

NO_OP_TIMEOUT = 60*1000 ## If no operations for 60 seconds, sync documents ##

module.exports = class RemoteSession
  constructor: (current_editor)->
    @buffer = current_editor.getBuffer()
    @noop = false
    @opindex = 0

  handle_position_change_op = (position) ->
    utils.debug "Editing OpIndex : #{position}"
    @opindex = position

  handle_insert_op = (string) ->
    @noop = true
    position = @buffer.positionForCharacterIndex @opindex
    @buffer.insert(position, string)
    @opindex += string.length

  handle_delete_op = (todelete) ->
    @noop = true
    from = @buffer.positionForCharacterIndex @opindex
    to = @buffer.positionForCharacterIndex(@opindex + todelete)
    @buffer.delete([from, to])

  set_op_index: (index) ->
    @opindex = index

  get_op_index: ->
    @opindex

  get_buffer: ->
    @buffer

  set_buffer: (buf) ->
    @buffer = buf

  get_op_type: (op) ->
    type = typeof op

    switch type
      when 'object'
        return 'position'
      else
        return type

  handle_op: (operation) ->
    return [] if is_op_empty operation

    for op in operation
      type = get_op_type op

      switch type
        when 'number'
          # '#' is position eg. op = [1531]
          utils.debug "Position Change."
          handle_position_change_op op
        when 'string'
          # str is insert string
          utils.debug "Insert."
          handle_insert_op op
        when 'position'
          # {d:N} is delete N characters
          utils.debug "Delete."
          handle_delete_op op.d

    #remote.updateSynch()

  is_op_empty: (op) ->
    return true if op is undefined
    return true if op.length is 0
    return false

  get_op_position: (op) ->
    return undefined if is_op_empty op
    if op.length > 1
      return op[0] if op[0] isnt undefined
    return undefined

  get_op_data: (op) ->
    return undefined if is_op_empty op
    if get_op_position(op) isnt undefined
      return op[1] if op[1] isnt undefined
    else
      return op[0] if op[0] isnt undefined
    return undefined

  is_op_same: (current_op, previous_op) ->
    return true if ( is_op_empty current_op and is_op_empty previous_op )

    are_delete_ops = ( is_delete_op current_op and is_delete_op previous_op )

    current_op_data = get_op_data current_op
    current_op_position = get_op_position current_op

    previous_op_data = get_op_data previous_op
    previous_op_position = get_op_position previous_op

    if not are_delete_ops
      return true if (
        (current_op_data is previous_op_data) and
          (current_op_position is previous_op_position) )
    else if are_delete_ops
      return true if ( (current_op_data.d is previous_op_data.d) and
        (current_op_position is previous_op_position) )

    return false

  is_delete_op: (op) ->
    return false if is_op_empty op

    if op.length is 1
      if op[0] isnt undefined
        return true if op[0].d isnt undefined
    else
      if op[1] isnt undefined
        return true if op[1].d isnt undefined

    return false

  get_delete_op_length: (op) ->
    if is_delete_op op
      if op.length is 1
        return op[0].d
      else
        return op[1].d

  done_remote_op: ->
    @noop

  update_done_remote_op: (bool) ->
    @noop = bool
