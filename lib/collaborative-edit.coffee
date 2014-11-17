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
    documentName:
      type: 'string'
      default: 'untitled'
    debug:
      type: 'boolean'
      default: true

  activate: ->
    @collaborativeEditView = new CollaborativeEditView()

  deactivate: ->
    console.log @collaborativeEditView
    @collaborativeEditView.destroy()

  serialize: ->
    # do something

module.exports = new CollaborativeEdit