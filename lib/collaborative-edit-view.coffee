{View, EditorView} = require 'atom'
client = require './Client/client'

startclient = (hosting) ->
  if hosting
    editor = atom.workspace.getActiveEditor()
    atom.config.set('collaborative-edit.DocumentName', editor.getTitle())
    client.connect editor
  else
    client.connect()

  @view = new ShareView()
  @view.show()

class ShareView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-bottom', =>
      @div 'This file is being shared', class: 'message'

  show: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

class EditConfig extends View
  isHost: false

  @content: (currentfile) ->
    @div class: 'collaborative-edit overlay from-top mini', =>
      @h1 "Connection Information"
      @div class: 'block', =>
        @label "Server IP Address:"
        @subview 'miniaddress', new EditorView(mini: true, placeholderText: 'localhost')
        @div class: 'message', outlet: '_address'
      @div class: 'blocl', =>
        @label "Server Port:"
        @subview 'miniport', new EditorView(mini: true, placeholderText: '8080')
        @div class: 'message', outlet: '_port'
      @div class: 'block', =>
        @label "File Name:"
        @subview 'minifile', new EditorView(mini: true, placeholderText: currentfile)
        @div class: 'message', outlet: '_name'

  initialize: ->
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniaddress.setTooltip("The ADDRESS to host on, or connect to. Default : #{atom.config.get('collaborative-edit:ServerAddress')}")
    @miniaddress.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

    @miniport.setTooltip("The PORT to host on, or connect to. Default : #{atom.config.get('collaborative-edit:Port')}")
    @miniport.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[0-9]/)

    @minifile.setTooltip("The DOCUMENT to host on, or connect to. Default : #{atom.config.get('collaborative-edit:DocumentName')}")
    @minifile.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

  activate: ->
    new EditConfig()

  show: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

  confirm: ->
    addr = @miniaddress.getText()
    port = @miniport.getText()
    file = @minifile.getText()

    if addr.length isnt 0
      atom.config.set('collaborative-edit.ServerAddress', addr)

    if port.length >= 4 and port.length <= 6
      atom.config.set('collaborative-edit.Port', port)

    if file.length isnt 0
      atom.config.set('collaborative-edit.DocumentName', file)

    @server = require './Host/host'
    @isserver = true
    @server.host()

    startclient(@ishost)

    @destroy()

  sethost: (bool) ->
    @ishost = bool

module.exports =
class CollaborativeEditView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-top', =>
      @div "The CollaborativeEdit package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()
    atom.workspaceView.command "collaborative-edit:Disconnect", => @Disconnect()

  serialize: ->

  destroy: ->
    client.deactivate()
    @server = undefined
    @isserver = false
    @view.destroy()
    @detach()

  Host: ->
    @edit = new EditConfig(atom.workspace.getActiveEditor().getTitle())
    @edit.sethost(true)
    @edit.show()
    @edit.focus()

  Connect: ->
    @edit = new EditConfig('untitled')
    @edit.show()
    @edit.focus()

  Disconnect: ->
    @server.close() if @isserver
    @destroy()
