CollaborativeEditView = require './collaborative-edit-view'
m_file = require './Utils/file'
m_server = require './Host/host'
m_client = require './Client/client'

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

  Host: ->
    m_server.host()

    _currentEditor = atom.workspace.getActiveTextEditor()

    if not _currentEditor
      _currentEditor = atom.workspace.open()
      m_client.connect(_currentEditor)
    else
      atom.config.set('collaborative-edit.DocumentName',
        _currentEditor.getTitle())
      m_client.connect(_currentEditor)

  Connect: ->
    console.log "Connecting . . ."
    m_client.connect()

  deactivate: ->

  serialize: ->
  
