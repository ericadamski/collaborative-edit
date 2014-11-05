utils =
  {
    isEmpty: (op) ->
        return true if op is undefined
        return true if op.length is 0
        return false

    getOpPosition: (op) ->
      return undefined if utils.isEmpty op
      if op.length > 1
        if op[0] isnt undefined
          return op[0]
      return undefined

    getOpData: (op) ->
      return undefined if utils.isEmpty op
      if utils.getOpPosition(op) isnt undefined
        if op[1] isnt undefined
          return op[1]
      else
        if op[0] isnt undefined
          return op[0]
      return undefined

    isTheSame: (currentOp, prevOp) ->
      return true if ( utils.isEmpty currentOp and utils.isEmpty prevOp )

      crOpData = utils.getOpData currentOp
      crOpPos = utils.getOpPosition currentOp

      prevOpData = utils.getOpData prevOp
      prevOpPos = utils.getOpPosition prevOp

      return true if ( (crOpData is prevOpData) and (crOpPos is prevOpPos) )

      return false
  }

module.exports = utils
