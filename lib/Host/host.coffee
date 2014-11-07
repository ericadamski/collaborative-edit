{allowUnsafeEval} = require 'loophole'
sharejs = allowUnsafeEval -> require 'share'
{Duplex} = allowUnsafeEval -> require 'stream'
connect = allowUnsafeEval -> require 'connect'
livedb = allowUnsafeEval -> require 'livedb'
http = require 'http'

app = connect()

backend = livedb.client livedb.memory()

share = sharejs.server.createClient {backend}

server = http.createServer app

WebSocketServer = require('ws').Server
wss = new WebSocketServer {server}
wss.on 'connection', (client) ->
  console.log client
  stream = new Duplex objectMode:yes
  stream._write = (chunk, encoding, callback) ->
    client.send JSON.stringify chunk
    callback()

  stream._read = ->

  stream.headers = client.upgradeReq.headers
  stream.remoteAddress = client.upgradeReq.connection.remoteAddress

  client.on 'message', (data) ->
    stream.push JSON.parse data

  stream.on 'error', (msg) ->
    console.log msg
    client.close msg

  client.on 'close', (reason) ->
    console.log reason
    stream.push null
    stream.emit 'close'
    console.log 'client went away'
    client.close reason

  stream.on 'end', ->
    client.close()

  share.listen stream

port = atom.config.get('collaborative-edit.Port')
addr = atom.config.get('collaborative-edit.ServerAddress')

h =
  {
    host: ->
      server.listen(port, addr)
      console.log "Listening on http://#{addr}:#{port}/"
  }

module.exports = h
