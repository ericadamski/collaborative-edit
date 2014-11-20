CollaborativeEditView = require './collaborative-edit-view'

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
    Debug:
      type: 'boolean'
      default: true

  activate: ->
    @collaborativeEditView = new CollaborativeEditView()

  deactivate: ->
    console.log @collaborativeEditView
    @collaborativeEditView.destroy()

  serialize: ->
