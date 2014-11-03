sharejs = require 'share'
live    = require 'livedb'
{Duplex} = require 'stream'
connect  = require 'connect'
http     = require 'http'

backend = live.client live.memory()
share   = sharejs.server.createClient {backend}

app = connect(
  connect.static "#{_dirname}/public"
  connect.static sharejs.scriptsDir
)

host: ->
  server = http.createServer app

  WebSocketServer = require('ws').Server
  wss = new WebSocketServer {server}

  wss.on 'connection', (client) ->
    stream = new Duplex objectMode:yes
    stream._write = (chunk, encoding, callback) ->
      console.log 's->c ', chunck
      client.send JSON.stringify chunk
      callback()

    stream._read = ->

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

  __options = $.getJSON 'config.json', (data) ->
    console.log data

  port = 7007
  server.listen port
  console.log "Listening on http://localhost:#{port}/"

host()
