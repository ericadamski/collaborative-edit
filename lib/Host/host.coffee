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
    jsonData = JSON.parse data
    if jsonData.a is "unsub"
      id = wss.getClients().indexOf client
      if client.documents?
        for doc in client.documents
          if doc.cursor?
            doc.cursor.cursorPosition =
              "{\"id\": #{id}, \"position\": \"close\"}"
            cursorSocket = doc.cursor
            handleCursorPositionChange {_parent: client, _cursor: doc.cursor},
              doc.documentName
    if jsonData.isTaken isnt undefined
      if client.documents is undefined
        client.documents = []
      client.documents.push(
        {isTaken: jsonData.isTaken, documentName: jsonData.documentName})
    else if jsonData.isCursorSocket isnt undefined
      addCursor client, jsonData.documentName
    else if jsonData.cursorPosition is undefined
      stream.push jsonData
    else
      utils.debug "Setting mouse position"
      parent = getParentClient client, jsonData.documentName
      id = wss.getClients().indexOf parent
      if typeof jsonData.cursorPosition is 'number'
        client.cursorPosition =
          "{\"id\": #{id}, \"position\": #{jsonData.cursorPosition}}"
      else if typeof jsonData.cursorPosition is 'string'
        client.cursorPosition =
          "{\"id\": #{id}, \"position\": \"#{jsonData.cursorPosition}\"}"

      handleCursorPositionChange {_parent: parent, _cursor: client},
        jsonData.documentName

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

port = atom.config.get('collaborative-edit.Port')
addr = atom.config.get('collaborative-edit.ServerAddress')

if port is undefined
  port = 8080

if addr is undefined
  addr is 'localhost'

getParentClient = (client, documentName) ->
  for c in wss.getClients()
    if c isnt client and c.documents?
      for doc in c.documents
        if doc.documentName is documentName and doc.cursor is client
          return c


handleCursorPositionChange = (clients, documentName, done) ->
  for c in wss.getClients()
    if c?
      if c isnt clients._parent and c isnt clients._cursor and c.documents?
        for doc in c.documents
          if doc.documentName is documentName
            send doc.cursor, clients._cursor.cursorPosition, done

addCursor = (client, documentName) ->
  for c in wss.getClients()
    if c isnt client and c.documents?
      for doc in c.documents
        if doc.documentName is documentName and not doc.cursor?
          doc.cursor = client

send = (socket, msg, done) ->
  socket?.send msg if socket?.readyState is WebSocket.OPEN
  done() if done?

class Host

  host: ->
    server.listen port, addr
    utils.debug "Listening on http://#{addr}:#{port}/"

  close: ->
    utils.debug "Closing Server"
    try
      wss.close()
    catch error
      console.log error

module.exports = Host
