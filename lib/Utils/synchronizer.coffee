Utils = require './utils'

module.exports = class Synchronizer
  constructor: (@local) ->
    @oneSecond = 1000

  start: ->
    @interval = window.setInterval(@synch, @oneSecond, this)

  synch: (that) ->
    diff = Utils.now() - that.local.previous_operation?.time_stamp
    if diff >= that.oneSecond and that.local.previous_operation.remote
      Utils.debug "It has been 1 second"
      Utils.debug "Is it remote? : #{that.local.previous_operation.remote}"
      that.local.buffer.setTextViaDiff that.local._document.getSnapshot()

  stop: ->
    clearInterval @interval

  restart: ->
    @stop() if @interval?
    @start()
