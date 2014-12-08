_removeallclients = () ->
  for client in session.clients
    client?.deactivate()
  session.clients = []

session =
  {
    clients: []

    getclientpanes: ->
      panes = []
      for client in session.clients
        if client.pane?
          panes.push client.pane

      return panes

    opendocument: (done) ->
      session.clients.push done()

    host: ->
      session.server?.host()

    destroy: ->
      _removeallclients()
      setTimeout session.server?.close, 2000

    getallfiles: ->
      filelist = []
      for client in session.clients
        filelist.push client.documentname
      return filelist.toString()

  }

module.exports = session
