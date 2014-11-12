{View, EditorView} = require 'atom'
m_file = require './Utils/file'
m_server = undefined
m_client = require './Client/client'

isServer = false

view = undefined
edit = undefined

startClient = (hosting) ->
  if hosting
    editor = atom.workspace.getActiveEditor()
    m_client.connect(editor)
  else
    m_client.connect()

  view = new ShareView()
  view.show()

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

  @content: (currentFile) ->
    @div class: 'collaborative-edit overlay from-top mini', =>
      @h1 "Connection Information"
      @div =>
        @div "Server IP Address:"
        @subview 'miniAddress', new EditorView(mini: true, placeholderText: 'localhost')
        @div class: 'message', outlet: '_address'
      @div =>
        @div "Server Port:"
        @subview 'miniPort', new EditorView(mini: true, placeholderText: '8080')
        @div class: 'message', outlet: '_port'
      @div =>
        @div "File Name:"
        @subview 'miniFile', new EditorView(mini: true, placeholderText: currentFile)
        @div class: 'message', outlet: '_name'

  initialize: ->
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniAddress.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

    @miniPort.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[0-9]/)

    @miniFile.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

  activate: ->
    new EditConfig()

  show: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

  confirm: ->
    console.log "Address : #{@miniAddress.getText()}, Port : #{@miniPort.getText()}, File Name : #{@miniFile.getText()}"
    addr = @miniAddress.getText()
    port = @miniPort.getText()
    file = @miniFile.getText()

    if addr.length isnt 0
      atom.config.set('collaborative-edit:ServerAddress', addr)

    if port.length >= 4 and port.length <= 6
      atom.config.set('collaborative-edit:Port', port)

    if file.length isnt 0
      atom.config.set('collaborative-edit:DocumentName', file)

    startClient(@isHost)

    @destroy()

  setHost: (bool) ->
    @isHost = bool

module.exports =
class CollaborativeEditView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-top', =>
      @div "The CollaborativeEdit package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()
    atom.workspaceView.command "collaborative-edit:Disconnect", => @Disconnect()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    m_client.deactivate()
    m_server = undefined
    isServer = false
    view.destroy()
    @detach()

  Host: ->
    edit = new EditConfig(atom.workspace.getActiveEditor().getTitle())
    edit.setHost(true)
    edit.show()
    edit.focus()
    m_server = require './Host/host'
    isServer = true
    m_server.host()

  Connect: ->
    edit = new EditConfig('untitled')
    edit.show()
    edit.focus()

  Disconnect: ->
    m_server.close() if isServer
    @destroy()
