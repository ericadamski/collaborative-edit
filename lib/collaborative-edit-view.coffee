{allowUnsafeEval} = require 'loophole'
{View, EditorView} = require 'atom'
Client = allowUnsafeEval -> require './Client/client'
Session = require './Utils/session'
Host = require './Host/host'

class ShareView extends View
  @content: (currentSession) ->
    @div class: 'collaborative-edit overlay from-bottom', =>
      @div "File(s) #{currentSession.getAllFiles()} are being shared", class: 'message'

  show: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

class EditConfig extends View
  @content: (currentfile) ->
    @div class: 'collaborative-edit overlay from-top mini', =>
      @h1 "Connection Information"
      @div class: 'block', =>
        @label "Server IP Address:"
        @subview 'miniAddress',
          new EditorView mini: true,
            placeholderText: atom.config.get('collaborative-edit.ServerAddress')
        @div class: 'message', outlet: '_address'
      @div class: 'blocl', =>
        @label "Server Port:"
        @subview 'miniPort',
          new EditorView mini: true,
            placeholderText: atom.config.get('collaborative-edit.Port')
        @div class: 'message', outlet: '_port'
      @div class: 'block', =>
        @label "File Name:"
        @subview 'miniFile',
          new EditorView mini: true, placeholderText: currentfile
        @div class: 'message', outlet: '_name'

  initialize: (fileName, currentSession, onConfim) ->
    @currentSession = currentSession

    @on 'core:confirm', => @confirm onConfim
    @on 'core:cancel', => @detach()

    @miniAddress.setTooltip "The ADDRESS to host on, or connect to. Default "+
      ": #{atom.config.get('collaborative-edit:ServerAddress')}"
    @miniAddress.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

    @miniPort.setTooltip "The PORT to host on, or connect to. Default : "+
      "#{atom.config.get('collaborative-edit:Port')}"
    @miniPort.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[0-9]/)

    @miniFile.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

  activate: ->
    new EditConfig()

  show: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

  confirm: (done) ->
    addr = @miniAddress.getText()
    port = @miniPort.getText()
    file = @miniFile.getText()

    if addr.length isnt 0
      atom.config.set('collaborative-edit.ServerAddress', addr)

    if port.length >= 4 and port.length <= 6
      atom.config.set('collaborative-edit.Port', port)

    if @currentSession.toHost
      if file is ""
        file = atom.workspace.getActiveEditor().getTitle()
      @currentSession.server = new Host()
      @currentSession.host()

    file = 'untitled' if file is ""

    done file, @currentSession

    @destroy()

module.exports = class CollaborativeEditView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-top', =>
      @div "The CollaborativeEdit package is Alive! It's ALIVE"

  initialize: (serializeState) ->
    atom.workspaceView.command "collaborative-edit:Host", => @Host()
    atom.workspaceView.command "collaborative-edit:Connect", => @Connect()
    atom.workspaceView.command "collaborative-edit:Disconnect", => @Disconnect()

  serialize: ->

  destroy: ->
    @shareView?.destroy()
    @currentSession.destroy()
    @detach()

  startClient: (documentName, currentSession) ->
    console.log currentSession
    if currentSession.toHost
      editor = atom.workspace.getActiveEditor()
      currentSession.openDocument ->
        return Client().connect documentName, editor
    else
      currentSession.openDocument ->
        return Client().connect documentName

    @shareView?.destroy()
    @shareView = new ShareView currentSession
    @shareView.show()

  Host: ->
    @currentSession = new Session()
    @currentSession.toHost = true
    @edit = new EditConfig atom.workspace.getActiveEditor().getTitle(),
      @currentSession, @startClient
    @edit.show()
    @edit.focus()

  Connect: ->
    @currentSession = new Session()
    @currentSession.toHost = false
    @edit = new EditConfig 'untitled', @currentSession, @startClient
    @edit.show()
    @edit.focus()

  Disconnect: ->
    @destroy()
