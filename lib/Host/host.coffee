{allowUnsafeEval} = require 'loophole'
sharejs = allowUnsafeEval -> require 'share'
live = allowUnsafeEval -> require 'livedb'
{Duplex} = allowUnsafeEval -> require 'stream'
connect = allowUnsafeEval -> require 'connect'
http = require 'http'
WebSocketServer = (allowUnsafeEval -> require 'ws').Server

backend = live.client live.memory()
share   = sharejs.server.createClient {backend}

app = connect()

server = http.createServer app

wss = new WebSocketServer {server}

wss.on 'connection', (client) ->
  stream = new Duplex objectMode:yes

  stream._write = (chunk, encoding, callback) ->
    console.log 's->c ', chunk
    client.send JSON.stringify chunk
    callback()

  stream.headers = client.upgradeReq.headers
  stream.remoteAddress = client.upgradeReq.connection.removeAddress

  client.on 'message', (msg) ->
    console.log 'c->s ', msg
    stream.push JSON.parse msg

  stream.on 'error', (msg) ->
    client.close msg

  client.on 'close', (reason) ->
    stream.push null
    stream.emit 'close'
    console.log "Client is closing."
    client.close reason

  steam.on 'end', ->
    client.close()

  share.listen stream

port = atom.config.get('collaborative-edit.port')

server.listen port
console.log "Listening on http://localhost:#{port}/"
