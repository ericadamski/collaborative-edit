class Session
  constructor: ->
    @clients = []

  getClientPanes: ->
    panes = []
    for client in @clients
      if client.pane?
        panes.push client.pane

    return panes

  openDocument: (done) ->
    this.clients.push done()

  getAllFiles: ->
    fileList = []
    for client in @clients
      fileList.push client.documentName
    return fileList.toString()


module.exports = Session
