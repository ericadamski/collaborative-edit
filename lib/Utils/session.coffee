_removeAllClients = ->
  for client in session.clients
    client?.deactivate()
  session.clients = []

class Session

  clients: []

  getClientPanes: ->
    panes = []
    for client in session.clients
      if client.pane?
        panes.push client.pane

    return panes

  openDocument: (done) ->
    this.clients.push done()

  host: ->
    this.server?.host()

  destroy: ->
    _removeAllClients()
    setTimeout session.server?.close, 2000

  getAllFiles: ->
    fileList = []
    for client in this.clients
      fileList.push client.documentName
    return fileList.toString()


module.exports = Session
