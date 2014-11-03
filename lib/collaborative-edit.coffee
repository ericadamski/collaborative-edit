CollaborativeEditView = require './collaborative-edit-view'
_File = require './Utils/file'
#sharejs = require 'share'
#live = require 'livedb'
#Duplex = require 'stream'
#express = require 'express'
http = require 'http'

module.exports =
  collaborativeEditView: null

  config:
    port:
      type: 'integer'
      default: 8080
      minimum: 8000


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
