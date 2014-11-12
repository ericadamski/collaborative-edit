CollaborativeEditView = require './collaborative-edit-view'
m_file = require './Utils/file'
m_server = undefined
m_client = require './Client/client'

isServer = false

startClient = (editor, hosting) ->
  if hosting
    m_client.connect(editor)
  else
    m_client.connect()

module.exports =
  collaborativeEditView: null

  config:
    Port:
      type: 'integer'
      default: 8080
      minimum: 8000
    ServerAddress:
      type: 'string'
      default: '127.0.0.1'
    DocumentName:
      type: 'string'
      default: 'untitled'


  activate: ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()
    atom.workspaceView.command "collaborative-edit:Disconnect", => @Disconnect()

  Host: ->
    m_server = require './Host/host'
    isServer = true
    editor = atom.workspace.getActiveEditor()
    m_server.host()
    atom.config.set('collaborative-edit.DocumentName',
      editor.getTitle())
    startClient(editor, true)

  Connect: ->
    startClient(null, false)

  Disconnect: ->
    m_server.close() if isServer
    @deactivate()

  deactivate: ->
    m_client.deactivate()
    m_server = undefined
    isServer = false

  serialize: ->
