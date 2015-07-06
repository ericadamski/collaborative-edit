{allowUnsafeEval} = require 'loophole'
Utils = require '../Utils/utils'
Session = require './session.coffee'
Synchronizer = require '../Utils/synchronizer'
#
class Client
  connect: (document_name, current_text_editor) ->
    @local_session = new Session(
      'local', document_name, current_text_editor)

    that = this

    if @local_session.session.editor is undefined
      @local_session.session.watch 'editor', (prop, oldVal, newVal) ->
        this.unwatch 'editor'
        @editor = newVal
        that.remote_session = new Session 'remote', document_name, @editor
    else
      @remote_session = new Session 'remote', document_name, current_text_editor

    @local_session.session.watch '_document', (prop, oldVal, newVal) ->
      this.unwatch '_document'
      @_document = newVal
      that.afterConnect()

  afterConnect: ->
    doc = @local_session.session._document

    @synchronizer = new Synchronizer @local_session.session

    that = this

    local = @local_session.session

    doc.subscribe (error) ->
      if not error?
        doc.whenReady ->
          Utils.debug 'Document is ready.'

          if not doc.type?
            doc.create 'text'
            text = local.buffer.getText()
            context = doc.createContext()
            context.insert 0, text
            local.set_context context
            local.set_document_position(
              local.buffer.characterIndexForPosition(
                local.get_cursor_position()
              )
            )
          else
            local.set_context doc.createContext()
            local.buffer.setTextViaDiff doc.getSnapshot()

          setup_file_handlers local
      else
        console.error error

    doc.on('after op', (op, localop) ->
      console.log "is remote op." if not localop
      operation = {
        'remote' : true,
        'op' : op,
        'time_stamp' : Utils.now()
      }
      remote_update_document_contents(operation, that) unless localop
    )

    doc.watch 'version', (prop, oldVal, newVal) ->
      console.log "Going from version #{oldVal} to #{newVal}"
      version = newVal

  deactivate: ->
    @local_session.session.destroy()

setup_file_handlers = (local) ->
  local.add_handler(local.editor.onDidDestroy(local.destroy))
  local.add_handler(
    local.editor.onDidChangeCursorPosition((event) ->
      local.update_cursor_position event))
  local.buffer.onDidChange (event) ->
    local.update event

remote_update_document_contents = (operation, that) ->
  # if not remoteHandler.is_op_same( operation.op,
  #   localHandler.get_previous_operation()?.op)
  that.local_session.session.set_previous_operation operation
  that.remote_session.session.handle_op operation.op

module.exports = () -> return new Client
