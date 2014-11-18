_removeallclients = () ->
  for client in session.clients
    client?.deactivate()
    console.log client
  console.log session.clients
  session.clients = []

session =
  {
    clients: []

    opendocument: (done) ->
      session.clients.push done()
      console.log session.clients

    host: () ->
      console.log session.server
      session.server?.host()

    destroy: () ->
      _removeallclients()
      session.server?.close()

    getallfiles: () ->
      filelist = []
      for client in session.clients
        filelist.push client.documentname
      return filelist.toString()

  }

module.exports = session
