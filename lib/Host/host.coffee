{allowUnsafeEval} = require 'loophole'
sharejs = allowUnsafeEval -> require 'share'
{Duplex} = allowUnsafeEval -> require 'stream'
connect = allowUnsafeEval -> require 'connect'
livedb = allowUnsafeEval -> require 'livedb'
http = require 'http'
utils = require '../Utils/utils'

connectionlist = []

app = connect()

backend = livedb.client livedb.memory()

share = sharejs.server.createClient {backend}

server = http.createServer app

WebSocketServer = require('ws').Server
wss = new WebSocketServer {server}

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

  remoteaddress = stream.remoteAddress

  switch connectionlist.length
    when 0
      connectionlist.push client
    when 1
      tmpaddr = connectionlist[0].upgradeReq.connection.remoteAddress
      if remoteaddress is tmpaddr
        connectionlist[0].cursorclient = client
        connectionlist = []
    else
      for c in connetionlist
        tmpaddr = c.upgradeReq.connection.remoteAddress
        if remoteaddress is tmpaddr
          c.cursorclient = c
          connectionlist.splice connectionlist.indexOf(c , 1)
          break

  client.on 'message', (data) ->
    jsondata = JSON.parse data
    if jsondata.cursorposition is undefined
      stream.push jsondata
    else
      if typeof jsondata.cursorposition is 'number'
        console.log "Setting mouse position"
        id = wss.getclients().indexOf getparentclient client
        client.cursorposition = "{\"id\": #{id}, \"position\": #{jsondata.cursorposition}}"
        handlecursorpositionchange client

  stream.on 'error', (msg) ->
    utils.debug msg
    client.close msg

  client.on 'close', (reason) ->
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
  addr is 'localhost'

getparentclient = (client) ->
  for c in wss.getclients()
    if c.cursorclient is client
      return c

handlecursorpositionchange = (client) ->
  position = client.cursorposition
  parent = getparentclient client
  for c in wss.getclients()
    if c isnt client
      c.cursorclient?.send position

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
