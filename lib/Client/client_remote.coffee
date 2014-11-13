{allowUnsafeEval} = require 'loophole'
utils   = require '../Utils/utils'
OpIndex = 0
Buffer  = undefined
noOp    = false
synchId = 0
synch   = 0

NO_OP_TIMEOUT = 5000 ## If no operations for 5 seconds, sync documents ##

getTime = ->
  return (allowUnsafeEval -> Date.now())

handlePositionChangeOp = (position) ->
  utils.debug "Editing OpIndex : #{position}"
  @OpIndex = position

handleInsertOp = (string) ->
  noOp = true
  utils.debug Buffer
  utils.debug @OpIndex
  position = Buffer.positionForCharacterIndex(@OpIndex)
  utils.debug position
  Buffer.insert(position, string)
  @OpIndex += string.length
  utils.debug "Op is #{noOp}"

handleDeleteOp = (toDelete) ->
  noOp = true
  from = Buffer.positionForCharacterIndex(@OpIndex)
  to = Buffer.positionForCharacterIndex(@OpIndex + toDelete)
  utils.debug "Deleting from #{from} to #{to}"
  Buffer.delete([from, to])
  utils.debug "Op is #{noOp}"

remote =
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
      utils.debug "operation #{op} has type #{type}"

      switch type
        when 'object'
          return 'position'
        else
          return type

    HandleOp: (operation) ->
      return [] if remote.isOpEmpty(operation)

      utils.debug Buffer

      for op in operation
        type = remote.getOpType(op)

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

      remote.updateSynch()
      @OpIndex = 0

    isOpEmpty: (op) ->
        return true if op is undefined
        return true if op.length is 0
        return false

    getOpPosition: (op) ->
      return undefined if remote.isOpEmpty op
      if op.length > 1
        if op[0] isnt undefined
          return op[0]
      return undefined

    getOpData: (op) ->
      return undefined if remote.isOpEmpty op
      if remote.getOpPosition(op) isnt undefined
        if op[1] isnt undefined
          return op[1]
      else
        if op[0] isnt undefined
          return op[0]
      return undefined

    isOpTheSame: (currentOp, prevOp) ->
      return true if ( remote.isOpEmpty currentOp and remote.isOpEmpty prevOp )

      _areDeleteOps = (remote.isDeleteOp(currentOp) and remote.isDeleteOp(prevOp))

      crOpData = remote.getOpData currentOp
      crOpPos = remote.getOpPosition currentOp

      prevOpData = remote.getOpData prevOp
      prevOpPos = remote.getOpPosition prevOp

      utils.debug "Checking to see if operations are the same."
      utils.debug "currentOp Position : #{crOpPos} prevOp Position : #{prevOpPos}
                   currentOp Data : #{crOpData} prevOp Data : #{prevOpData}"

      if not _areDeleteOps
        return true if ( (crOpData is prevOpData) and (crOpPos is prevOpPos) )
      else if _areDeleteOps
        return true if ( (crOpData.d is prevOpData.d) and
          (crOpPos is prevOpPos) )

      return false

    isDeleteOp: (op) ->
      return false if remote.isOpEmpty op

      if op.length is 1
        utils.debug op[0].d
        return true if op[0].d isnt undefined
      else
        utils.debug op[1].d
        return true if op[1].d isnt undefined

      return false

    getDeleteOpLength: (op) ->
      if remote.isDeleteOp op
        if op.length is 1
          return op[0].d if op[0].d isnt undefined
        else
          return op[1].d if op[1].d isnt undefined

    doneRemoteOp: ->
      return noOp

    updateDoneRemoteOp: (bool) ->
      utils.debug "Updating 'doneRemoteOp' to #{bool}"
      noOp = bool

    startSynchronize: (shareJsDocContext) ->
      synch = getTime() if synch is 0
      synchId = setInterval(
        (-> remote.synchronize(shareJsDocContext)),
        NO_OP_TIMEOUT
      )

    stopSynchronize: ->
      clearInterval(synchId)

    synchronize: (context) ->
      timeNow = getTime()
      timeDiff = timeNow - synch

      if timeDiff > 5000
        utils.debug "Synchronizing"
        noOp = true
        Buffer.setTextViaDiff(context.get())

      synch = timeNow

    updateSynch: ->
      synch = getTime()

  }

module.exports = remote
