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
  sendallcursors client
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
          connectionlist.splice connectionlist.indexOf(c), 1
          break

  client.on 'message', (data) ->
    console.log client
    jsondata = JSON.parse data
    if jsondata.cursorposition is undefined
      stream.push jsondata
    else
      utils.debug "Setting mouse position"
      id = wss.getclients().indexOf getparentclient client
      if typeof jsondata.cursorposition is 'number'
        client.cursorposition = "{\"id\": #{id}, \"position\": #{jsondata.cursorposition}}"
      else if typeof jsondata.cursorposition is 'string'
        client.cursorposition = "{\"id\": #{id}, \"position\": \"#{jsondata.cursorposition}\"}"

      handlecursorpositionchange client

  stream.on 'error', (msg) ->
    utils.debug msg
    client.close msg

  client.on 'close', (reason) ->
    utils.debug reason
    stream.push null
    stream.emit 'close'
    utils.debug 'client went away'
    try
      client.cursorclient?.close reason
      client.close reason
    catch error
      console.log error

  stream.on 'end', ->
    try
      client.close()
    catch error
      console.log error

  share.listen stream

port = atom.config.get('collaborative-edit.Port')
addr = atom.config.get('collaborative-edit.ServerAddress')

if port is undefined
  port = 8080

if addr is undefined
  addr is 'localhost'

sendallcursors = (newclient) ->
  parent = getparentclient newclient

  if parent isnt undefined
    for c in wss.getclients()
      if c isnt parent and c isnt newclient
        send c.cursorclient, c.cursorclient.cursorposition


getparentclient = (client) ->
  for c in wss.getclients()
    if c.cursorclient is client
      return c

handlecursorpositionchange = (client) ->
  position = client.cursorposition
  parent = getparentclient client
  for c in wss.getclients()
    if c isnt parent and c isnt client
      try
        send c.cursorclient, position
      catch error
        console.log error

send = (socket, msg) ->
  console.log msg
  console.log socket
  socket?.send msg if socket.readyState is WebSocket.OPEN

host =
  {
    host: ->
      console.log server.listen(port, addr)
      utils.debug "Listening on http://#{addr}:#{port}/"

    close: ->
      utils.debug "Closing Server"
      try
        wss.close()
      catch error
        console.log error
  }

module.exports = host
