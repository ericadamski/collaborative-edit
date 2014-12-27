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
    for client in session.clients
      client?.deactivate()
    setTimeout session.server?.close, 2000

  getAllFiles: ->
    fileList = []
    for client in this.clients
      fileList.push client.documentName
    return fileList.toString()


module.exports = Session
