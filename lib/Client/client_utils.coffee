utils =
  {
    getOpPosition: (op) ->
      if op.length > 1
        if op[0] isnt undefined
          return op[0]
      return undefined

    getOpData: (op) ->
      if utils.getOpPosition(op) isnt undefined
        if op[1] isnt undefined
          return op[1]
      else
        if op[0] isnt undefined
          return op[0]
      return undefined
  }

nmodule.exports = utils
