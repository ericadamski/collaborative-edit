CollaborativeEditView = require './collaborative-edit-view'

class CollaborativeEdit

  config:
    Port:
      type: 'integer'
      default: 8080
    ServerAddress:
      type: 'string'
      default: '127.0.0.1'
    Debug:
      type: 'boolean'
      default: false

  activate: ->
    @collaborativeEditView = new CollaborativeEditView()

  deactivate: ->
    @collaborativeEditView.destroy()

  serialize: ->

module.exports = new CollaborativeEdit
