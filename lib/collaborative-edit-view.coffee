{View, EditorView} = require 'atom'
client = require './Client/client'
currentsession = require './Utils/session'

shareview = undefined

startclient = (documentname) ->
  if currentsession.tohost
    editor = atom.workspace.getActiveEditor()
    currentsession.opendocument -> return client().connect documentname, editor
  else
    currentsession.opendocument -> return client().connect documentname

  shareview?.destroy()
  shareview = new ShareView()
  shareview.show()


getsharedfiles = () ->
  return currentsession.getallfiles()

class ShareView extends View
  activepane = undefined
  @content: ->
    @div class: 'collaborative-edit overlay from-bottom', =>
      @div "File(s) #{getsharedfiles()} are being shared", class: 'message'

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
        @subview 'miniaddress', new EditorView(mini: true, placeholderText: atom.config.get('collaborative-edit.ServerAddress'))
        @div class: 'message', outlet: '_address'
      @div class: 'blocl', =>
        @label "Server Port:"
        @subview 'miniport', new EditorView(mini: true, placeholderText: atom.config.get('collaborative-edit.Port'))
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

    if currentsession.tohost
      if file is ""
        file = atom.workspace.getActiveEditor().getTitle()
      currentsession.server = require './Host/host'
      currentsession.host()

    startclient file

    @destroy()

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
    shareview?.destroy()
    currentsession.destroy()
    @detach()

  Host: ->
    @edit = new EditConfig(atom.workspace.getActiveEditor().getTitle())
    currentsession.tohost = true
    @edit.show()
    @edit.focus()

  Connect: ->
    @edit = new EditConfig('untitled')
    currentsession.tohost = false
    @edit.show()
    @edit.focus()

  Disconnect: ->
    @destroy()
