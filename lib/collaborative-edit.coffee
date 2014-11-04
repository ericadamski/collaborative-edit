CollaborativeEditView = require './collaborative-edit-view'
m_file = require './Utils/file'

module.exports =
  collaborativeEditView: null

  config:
    port:
      type: 'integer'
      default: 8080
      minimum: 8000
    ServerAddress:
      type: 'string'
      default: "127.0.0.1"


  activate: ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()

  Host: ->
    _currentDocument = atom.workspace.open()
    #get current wokring doc or use new one
    console.log "Starting to Host Document #{_currentDocument}"
    _server = require './Host/host'

  Connect: ->
    console.log "Connecting . . ."
    m_client = require './Client/client'

  EditHostConfig: ->
    console.log "Editing Host Configuration File"
    currentEditor = atom.workspace.getActiveTextEditor()
    currentPath = m_file.basename currentEditor?.getPath()
    atom.workspace.open(currentPath.concat("/src/config.json"))

  deactivate: ->
    @collaborativeEditView.destroy()

  serialize: ->
    collaborativeEditViewState: @collaborativeEditView.serialize()
