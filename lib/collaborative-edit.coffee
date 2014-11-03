CollaborativeEditView = require './collaborative-edit-view'
_File = require './Utils/file.coffee'
_server = require './src/hosting.coffee'

module.exports =
  collaborativeEditView: null

  activate: ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()
    atom.workspaceView.command "collaborative-edit:EditHostConfig", => @EditHostConfig()

  Host: ->
    console.log "Hosting"

  Connect: ->
    console.log "Connecting . . ."

  EditHostConfig: ->
    console.log "Editing Host Configuration File"
    currentEditor = atom.workspace.getActiveTextEditor()
    currentPath = _File.basename currentEditor?.getPath()
    atom.workspace.open(currentPath.concat("/src/config.json"))

  deactivate: ->
    @collaborativeEditView.destroy()

  serialize: ->
    collaborativeEditViewState: @collaborativeEditView.serialize()
