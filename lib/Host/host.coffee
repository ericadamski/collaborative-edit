{allowUnsafeEval} = require 'loophole'
sharejs = allowUnsafeEval -> require 'share'
{Duplex} = allowUnsafeEval -> require 'stream'
connect = allowUnsafeEval -> require 'connect'
livedb = allowUnsafeEval -> require 'livedb'
http = require 'http'
utils = require '../Utils/utils'

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

  client.on 'message', (data) ->
    console.log client
    console.log data
    jsondata = JSON.parse data
    if jsondata.istaken isnt undefined
      if client.documents is undefined
        client.documents = []
      client.documents.push {istaken: jsondata.istaken, documentname: jsondata.documentname}
    else if jsondata.iscursorsocket isnt undefined
      addcursor client, jsondata.documentname
    else if jsondata.cursorposition is undefined
      stream.push jsondata
    else
      utils.debug "Setting mouse position"
      id = wss.getclients().indexOf getparentclient client, jsondata.documentname
      if typeof jsondata.cursorposition is 'number'
        client.cursorposition = "{\"id\": #{id}, \"position\": #{jsondata.cursorposition}}"
      else if typeof jsondata.cursorposition is 'string'
        client.cursorposition = "{\"id\": #{id}, \"position\": \"#{jsondata.cursorposition}\"}"

      handlecursorpositionchange client, jsondata.documentname

  stream.on 'error', (msg) ->
    utils.debug msg
    client.close msg

  client.on 'close', (reason) ->
    console.log client
    utils.debug reason
    stream.push null
    stream.emit 'close'
    utils.debug 'client went away'
    if client.documents is undefined
      client.close reason
    else
      id = wss.getclients().indexOf client
      for doc in client.documents
        if doc.cursor isnt undefined
          send doc.cursor, "{\"id\": #{id}, \"position\": \"close\"}"
          doc.cursor.close reason

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

sendallcursors = (newclient, documentname) ->
  parent = getparentclient newclient

  if parent isnt undefined
    for c in wss.getclients()
      if c isnt parent and c isnt newclient
        send c.cursorclient, c.cursorclient.cursorposition


getparentclient = (client, documentname) ->
  for c in wss.getclients()
    if c isnt client and c.documents isnt undefined
      for doc in c.documents
        if doc.documentname is documentname and doc.cursor is client
          return c


handlecursorpositionchange = (client, documentname) ->
  console.log client
  position = client.cursorposition
  for c in wss.getclients()
    if c isnt client and c?.documents?
      for doc in c.documents
        if doc.documentname is documentname and doc.cursor isnt client
          doc.cursor?.send position

addcursor = (client, documentname) ->
  for c in wss.getclients()
    if c isnt client and c.documents?
      for doc in c.documents
        if doc.documentname is documentname and not doc.cursor?
          doc.cursor = client

send = (socket, msg) ->
  socket?.send msg if socket?.readyState is WebSocket.OPEN

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
