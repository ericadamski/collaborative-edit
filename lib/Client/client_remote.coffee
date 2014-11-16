{allowUnsafeEval} = require 'loophole'
utils   = require '../Utils/utils'

NO_OP_TIMEOUT = 60*1000 ## If no operations for 60 seconds, sync documents ##
buffer = undefined
noop = false
opindex = 0

gettime = ->
  return (allowUnsafeEval -> Date.now())

handlepositionchangeop = (position) ->
  utils.debug "Editing OpIndex : #{position}"
  @opindex = position

handleinsertop = (string) ->
  noop = true
  position = buffer.positionForCharacterIndex @opindex
  buffer.insert(position, string)
  @opindex += string.length

handledeleteop = (todelete) ->
  noop = true
  from = buffer.positionForCharacterIndex @opindex
  to = buffer.positionForCharacterIndex(@opindex + todelete)
  buffer.delete [from, to]

remote =
  {
    setopindex: (index) ->
      opindex = index

    getopindex: ->
      return opindex
      
    getbuffer: ->
      return buffer

    setbuffer: (buf) ->
      buffer = buf

    getoptype: (op) ->
      type = typeof op

      switch type
        when 'object'
          return 'position'
        else
          return type

    handleop: (operation) ->
      return [] if remote.isopempty operation

      for op in operation
        type = remote.getoptype op

        switch type
          when 'number'
            # '#' is position eg. op = [1531]
            handlepositionchangeop op
          when 'string'
            # str is insert string
            handleinsertop op
          when 'position'
            # {d:N} is delete N characters
            handledeleteop op.d

      #remote.updateSynch()

    isopempty: (op) ->
      return true if op is undefined
      return true if op.length is 0
      return false

    getopposition: (op) ->
      return undefined if remote.isopempty op
      if op.length > 1
        return op[0] if op[0] isnt undefined
      return undefined

    getopdata: (op) ->
      return undefined if remote.isopempty op
      if remote.getopposition(op) isnt undefined
        return op[1] if op[1] isnt undefined
      else
        return op[0] if op[0] isnt undefined
      return undefined

    isopthesame: (currentop, prevop) ->
      return true if ( remote.isopempty currentop and remote.isopempty prevop )

      _aredeleteops = ( remote.isdeleteop currentop and remote.isdeleteop prevop )

      cropdata = remote.getopdata currentop
      croppos = remote.getopposition currentop

      prevopdata = remote.getopdata prevop
      prevoppos = remote.getopposition prevop

      if not _aredeleteops
        return true if ( (cropdata is prevopdata) and (croppos is prevoppos) )
      else if _aredeleteops
        return true if ( (cropdata.d is prevopdata.d) and
          (croppos is prevoppos) )

      return false

    isdeleteop: (op) ->
      return false if remote.isopempty op

      if op.length is 1
        if op[0] isnt undefined
          return true if op[0].d isnt undefined
      else
        if op[1] isnt undefined
          return true if op[1].d isnt undefined

      return false

    getdeleteoplength: (op) ->
      if remote.isdeleteop op
        if op.length is 1
          return op[0].d
        else
          return op[1].d

    doneremoteop: ->
      return noop

    updatedoneremoteop: (bool) ->
      noop = bool

    startsynchronize: (sharejsdoccontext) ->
      remote.synch = getTime() if synch is 0
      remote.synchid = setInterval(
        (-> remote.synchronize(sharejsdoccontext)),
        NO_OP_TIMEOUT
      )

    stopsynchronize: ->
      clearInterval(remote.synchid)

    synchronize: (context) ->
      timenow = gettime()
      timediff = timenow - @synch

      if timediff > 5000
        noop = true
        buffer.setTextViaDiff context.get()

      remote.synch = timenow

    updatesynch: ->
      remote.synch = gettime()

  }

module.exports = remote
