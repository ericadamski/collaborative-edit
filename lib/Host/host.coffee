{allowUnsafeEval} = require 'loophole'
sharejs           = allowUnsafeEval -> require 'share'
{Duplex}          = allowUnsafeEval -> require 'stream'
connect           = allowUnsafeEval -> require 'connect'
livedb            = allowUnsafeEval -> require 'livedb'
http              = require 'http'
utils             = require '../Utils/utils'

app               = connect()
backend           = livedb.client livedb.memory()
share             = sharejs.server.createClient {backend}
server            = http.createServer app
WebSocketServer   = require('ws').Server
wss               = new WebSocketServer {server}

wss.getclients = ->
  return this.clients

wss.on 'connection', (client) ->
  utils.debug client
  stream = new Duplex objectMode:yes

  stream._write = (chunk, encoding, callback) ->
    client.send JSON.stringify chunk
    callback()

  stream._read = ->

  stream.headers = client.upgradeReq.headers
  stream.remoteAddress = client.upgradeReq.connection.remoteAddress

  client.on 'message', (data) ->
    jsonData = JSON.parse data
    stream.push jsonData

  stream.on 'error', (msg) ->
    utils.debug msg
    client.close msg

  client.on 'close', (reason) ->
    utils.debug reason
    stream.push null
    utils.debug 'client went away'
    stream.emit 'close'
    client.close reason

  stream.on 'end', ->
    try
      client.close()
    catch error
      console.log error

  share.listen stream

port = atom.config.get('collaborative-edit.Port') or 8080
addr = atom.config.get('collaborative-edit.ServerAddress') or 'localhost'

send = (socket, msg, done) ->
  socket?.send msg if socket?.readyState is WebSocket.OPEN
  done() if done?

module.exports = class Host

  host: ->
    server.listen port, addr
    utils.debug "Listening on http://#{addr}:#{port}/"

  close: ->
    utils.debug "Closing Server ..."
    try
      wss.close()
    catch error
      console.log error
