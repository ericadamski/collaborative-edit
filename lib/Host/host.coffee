{allowUnsafeEval} = require 'loophole'
sharejs = allowUnsafeEval -> require 'share'
{Duplex} = allowUnsafeEval -> require 'stream'
connect = allowUnsafeEval -> require 'connect'
livedb = allowUnsafeEval -> require 'livedb'
http = require 'http'
utils = require '../Utils/utils'

clientAddresses = []

clientNumber = 0

app = connect()

backend = livedb.client livedb.memory()

share = sharejs.server.createClient {backend}

server = http.createServer app

WebSocketServer = require('ws').Server
wss = new WebSocketServer {server}
wss.on 'connection', (client) ->
  utils.debug client
  stream = new Duplex objectMode:yes
  stream._write = (chunk, encoding, callback) ->
    client.send JSON.stringify chunk
    callback()

  stream._read = ->

  stream.headers = client.upgradeReq.headers
  stream.remoteAddress = client.upgradeReq.connection.remoteAddress
  clientAddresses.push {"id": ++clientNumber, "address": stream.remoteAddress, "_clientObj": client}

  utils.debug clientAddresses

  client.on 'message', (data) ->
    stream.push JSON.parse data

  stream.on 'error', (msg) ->
    utils.debug msg
    client.close msg

  client.on 'close', (reason) ->
    toRemove = getCurrentClient(client)
    if toRemove isnt undefined
      clientAddresses.splice(toRemove.id - 1, 1, toRemove)
    utils.debug reason
    stream.push null
    stream.emit 'close'
    utils.debug 'client went away'
    client.close reason

  stream.on 'end', ->
    client.close()

  share.listen stream

port = atom.config.get('collaborative-edit.Port')
addr = atom.config.get('collaborative-edit.ServerAddress')

if port is undefined
  port = 8080

if addr is undefined
  addr = 'localhost'

getCurrentClient = (client) ->
  for c in clientAddresses
    if c._clientObj is client
      return c

host =
  {
    host: ->
      server.listen(port, addr)
      utils.debug "Listening on http://#{addr}:#{port}/"

    close: ->
      utils.debug "Closing Server"
      wss.close()
  }

module.exports = host
