{allowUnsafeEval} = require 'loophole'
utils = require '../Utils/utils'
Session = require './session.coffee'

class Client
  connect: (document_name, current_text_editor) ->
    @local_session = new Session(
      'local', document_name, current_text_editor)

    if not current_text_editor?
      current_text_editor = @local_session.session.editor

    @remote_session = new Session(
      'remote', document_name, current_text_editor)

    that = this

    @local_session.session.watch '_document', (prop, oldVal, newVal) ->
      console.log 'Changed'
      this.unwatch '_document'
      this._document = newVal
      that.afterConnect()

  afterConnect: ->
    doc = @local_session.session._document

    that = this

    doc.on('after op', (op, localop) ->
      operation = { 'remote?' : localop, 'op' : op }
      remote_update_document_contents operation, that unless localop
    )

    doc.subscribe()

    local = @local_session.session

    try
      doc.whenReady( ->
        utils.debug 'Document is ready.'

        if not doc.type?
          doc.create 'text'
          text = local.get_buffer().getText()
          context = this.createContext()
          context.insert 0, text
          local.set_context context
          local.set_document_position(
            local.get_buffer().characterIndexForPosition(
              local.get_cursor_position()
            )
          )
          console.log local.get_document_position()
        else
          local.set_context doc.createContext()

        setup_file_handlers local
      )
    catch error
      console.error error

  deactivate: ->
    @local_session.session.destroy()

setup_file_handlers = (local) ->
  local.add_handler(local.get_editor().onDidDestroy(local.destroy))
  local.add_handler(
    local.get_editor().onDidChangeCursorPosition((event) ->
      local.update_cursor_position event))
  local.buffer.on('changed', (event) ->    local.update event)

remote_update_document_contents = (operation, that) ->
  # I want to make an op a structure like op = {remote? : T/F, op: op}
  #that.local_session.session.set_previous_operation operation
  remoteHandler = that.remote_session.session
  localHandler = that.local_session.session

  if not remoteHandler.is_op_same( operation.op,
    localHandler.get_previous_operation()?.op)
    remoteHandler.handle_op operation.op
  #that.remote_session.session.update_done_remote_op false
  # ideally take this out.

module.exports = () -> return new Client
