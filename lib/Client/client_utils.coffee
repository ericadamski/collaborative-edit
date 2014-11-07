OpIndex = 0

Buffer = undefined

noOp = false

handlePositionChangeOp = (position) ->
  #handle store next op position
  console.log "Editing OpIndex : #{position}"
  @OpIndex = position

handleInsertOp = (string) ->
  # Insert
  noOp = true
  setTimeout(
    (->
      console.log Buffer
      console.log @OpIndex
      position = Buffer.positionForCharacterIndex(@OpIndex)
      console.log position
      Buffer.insert(position, string)
      @OpIndex += string.length
    ), 500)

handleDeleteOp = (toDelete) ->
  # toDelete is a number of chars to remove,
  # we shall have to see is forward or back
  noOp = true
  setTimeout(
    (->
      from = Buffer.positionForCharacterIndex(@OpIndex)
      to = Buffer.positionForCharacterIndex(@OpIndex + toDelete)
      console.log "Deleting from #{from} to #{to}"
      Buffer.delete([from, to])
    ), 500)

utils =
  {
    setOpIndex: (index) ->
      OpIndex = index

    getOpIndex: ->
      return OpIndex

    getBuffer: ->
      return Buffer

    setBuffer: (buffer) ->
      Buffer = buffer

    getOpType: (op) ->
      type = typeof op
      console.log "operation #{op} has type #{type}"

      switch type
        when 'object'
          return 'position'
        else
          return type

    HandleOp: (operation) ->
      return [] if utils.isOpEmpty(operation)

      for op in operation
        type = utils.getOpType(op)

        switch type
          when 'number'
            # '#' is position eg. op = [1531]
            handlePositionChangeOp op
          when 'string'
            # str is insert string
            handleInsertOp op
          when 'position'
            # {d:N} is delete N characters
            handleDeleteOp op.d

      @OpIndex = 0

    isOpEmpty: (op) ->
        return true if op is undefined
        return true if op.length is 0
        return false

    getOpPosition: (op) ->
      return undefined if utils.isOpEmpty op
      if op.length > 1
        if op[0] isnt undefined
          return op[0]
      return undefined

    getOpData: (op) ->
      return undefined if utils.isOpEmpty op
      if utils.getOpPosition(op) isnt undefined
        if op[1] isnt undefined
          return op[1]
      else
        if op[0] isnt undefined
          return op[0]
      return undefined

    isOpTheSame: (currentOp, prevOp) ->
      return true if ( utils.isOpEmpty currentOp and utils.isOpEmpty prevOp )

      _areDeleteOps = (utils.isDeleteOp(currentOp) and utils.isDeleteOp(prevOp))

      crOpData = utils.getOpData currentOp
      crOpPos = utils.getOpPosition currentOp

      prevOpData = utils.getOpData prevOp
      prevOpPos = utils.getOpPosition prevOp

      console.log "Checking to see if operations are the same."
      console.log "currentOp Position : #{crOpPos} prevOp Position : #{prevOpPos}
                   currentOp Data : #{crOpData} prevOp Data : #{prevOpData}"

      if not _areDeleteOps
        return true if ( (crOpData is prevOpData) and (crOpPos is prevOpPos) )
      else if _areDeleteOps
        return true if ( (crOpData.d is prevOpData.d) and
          (crOpPos is prevOpPos) )

      return false

    isDeleteOp: (op) ->
      return false if utils.isOpEmpty op

      if op.length is 1
        console.log op[0].d
        return true if op[0].d isnt undefined
      else
        console.log op[1].d
        return true if op[1].d isnt undefined

      return false

    getDeleteOpLength: (op) ->
      if utils.isDeleteOp op
        if op.length is 1
          return op[0].d if op[0].d isnt undefined
        else
          return op[1].d if op[1].d isnt undefined

    doneRemoteOp: ->
      return noOp

    updateDoneRemoteOp: ->
      noOp = (not noOp)
  }

module.exports = utils
