{allowUnsafeEval} = require 'loophole'
{View, TextEditorView} = require 'atom-space-pen-views'
Client = allowUnsafeEval -> require './Client/client'
Session = require './Utils/session'
Host = require './Host/host'

class ShareView extends View
  @content: (currentSession) ->
    @div class: 'collaborative-edit overlay from-bottom', =>
      @div "File(s) #{currentSession.getAllFiles()} are being shared",
        class: 'message'

  show: ->
    atom.workspaceView.append this

  destroy: ->
    @detach()

class EditConfig extends View
  @content: (currentfile) ->
    @div class: 'collaborative-edit overlay from-top mini', =>
      @h1 "Connection Information"
      @div class: 'block', =>
        @label for: 'miniAddress', "Server IP Address:"
        @subview 'miniAddress', new TextEditorView mini: true,
           placeholderText:
             atom.config.get('collaborative-edit.ServerAddress')
      @div class: 'block', =>
        @label for: 'miniPort', "Server Port:"
        @subview 'miniPort', new TextEditorView mini: true,
           placeholderText: atom.config.get('collaborative-edit.ServerPort')
      @div class: 'block', =>
        @label for: 'miniFile', "File Name:"
        @subview 'miniFile',
          new TextEditorView mini: true, placeholderText: currentfile
      @div class: 'block', =>
        @button class: 'inline-block btn', click: 'confirm', "Confirm"
        @button class: 'inline-block btn', click: 'destroy', "Cancel"

  initialize: (fileName, currentSession, @onConfim) ->
    @currentSession = currentSession

    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    # @miniAddress.setTooltip "The ADDRESS to host on, or connect to. Default "+
    #   ": #{atom.config.get('collaborative-edit:ServerAddress')}"
    @miniAddress.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

    # @miniPort.setTooltip "The PORT to host on, or connect to. Default : "+
    #   "#{atom.config.get('collaborative-edit:Port')}"
    @miniPort.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[0-9]/)

    @miniFile.preempt 'textInput', (e) ->
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

    console.log this

  destroy: ->
    @detach()

  show: ->
    atom.workspaceView.append this

  detached: ->
    utils.debug 'Detached Config View.'

  confirm: ->
    console.log @miniAddress

    addr = @miniAddress.getText()
    port = @miniPort.getText()
    file = @miniFile.getText()

    console.log "Address : #{addr}, Port : #{port}, File : #{file}"

    if addr.length isnt 0
      atom.config.set('collaborative-edit.ServerAddress', addr)

    if port.length >= 4 and port.length <= 6
      atom.config.set('collaborative-edit.ServerPort', port)

    if @currentSession.toHost
      if file is ""
        file = atom.workspace.getActiveEditor().getTitle()
      @currentSession.server = new Host()
      @currentSession.host()

    file = 'untitled' if file is ""

    @onConfim file, @currentSession

    @detach()

module.exports = class CollaborativeEditView extends View
  @content: ->
    @div class: 'collaborative-edit overlay from-top', =>
      @div "The CollaborativeEdit package is Alive! It's ALIVE"

  initialize: (serializeState) ->
    atom.commands.add "collaborative-edit:Host": @Host(),
      "collaborative-edit:Connect": @Connect(),
      "collaborative-edit:Disconnect": @Disconnect()

  serialize: ->

  destroy: ->
    @shareView?.destroy()
    @currentSession.destroy()
    @detach()

  startClient: (documentName, currentSession) ->
    console.log currentSession
    if currentSession.toHost
      editor = atom.workspace.getActiveEditor()
      console.log editor
      Client().connect documentName, editor
    else
      Client().connect documentName

    @shareView?.destroy()
    @shareView = new ShareView currentSession
    @shareView.show()

  Host: ->
    @currentSession = new Session()
    @currentSession.toHost = true
    @edit = new EditConfig atom.workspace.getActiveTextEditor().getTitle(),
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
    @detach()
