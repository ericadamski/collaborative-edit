CollaborativeEditView = require './collaborative-edit-view'

class CollaborativeEdit

  config:
    port:
      type: 'integer'
      default: 8080
      minimum: 8000
    serverAddress:
      type: 'string'
      default: '127.0.0.1'
    Debug:
      type: 'boolean'
      default: true

  activate: ->
    @collaborativeEditView = new CollaborativeEditView()

  deactivate: ->
    @collaborativeEditView.destroy()

  serialize: ->
    # do something

module.exports = new CollaborativeEdit
