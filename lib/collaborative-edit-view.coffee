{View} = require 'atom'

module.exports =
class CollaborativeEditView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-top', =>
      @div "The CollaborativeEdit package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "collaborative-edit:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  Host: ->
    console.log "CollaborativeEditView was Hosted!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)

  Connect: ->
    console.log "CollaborativeEditView was Connected!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
