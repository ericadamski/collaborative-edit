{allowUnsafeEval} = require 'loophole'
utils = require '../Utils/utils'
Session = require './session.coffee'



  #
  # port = atom.config.get 'collaborative-edit.Port'
  # addr = atom.config.get 'collaborative-edit.ServerAddress'
  #
  # interval = setInterval(
  #   ( ->
  #     try
  #       ws = new WebSocket("ws://#{addr}:#{port}")
  #       local.setsocket new WebSocket("ws://#{addr}:#{port}")
  #
  #       local.getsocket().onopen = () ->
  #         ws.send(
  #          "{\"istaken\": true, \"documentname\": \"#{local.documentname}\"}")
  #         this.send(
  #           "{\"iscursorsocket\": true, \"documentname\": "+
  #           "\"#{local.documentname}\"}")
  #         this.doc = local.documentname
  #
  #       share = new sharejs.client.Connection(ws)
  #
  #       share.debug = atom.config.get 'collaborative-edit.Debug'
  #
  #      local.setcurrentdocument doc = share.get("Sharing", local.documentname)
  #
  #       doc.on('after op', (op, localop) ->
  #         ## only for remote operations
  #         if not localop
  #           remoteupdatedocumentcontents op
  #       )
  #
  #       doc.subscribe()
  #
  #       doc.whenReady( ->
  #         utils.debug "Document is ready."
  #
  #         local.getsocket().onmessage = (msg) ->
  #           try
  #             if this.readyState is WebSocket.OPEN
  #               local.updateremotecursors msg
  #           catch error
  #             console.log error
  #
  #         remote.setbuffer local.getbuffer()
  #
  #         if (not doc.type)
  #           havenewfile doc
  #         else
  #           local.setglobalcontext doc.createContext()
  #           local.getbuffer().setTextViaDiff doc.getSnapshot()
  #
  #         setupfilehandlers()
  #         local._updatecursorposition()
  #
  #         clearInterval(interval)
  #       )
  #     catch error
  #       utils.debug error
  #   ),
  #   1000
  # )
  #
  # return { documentname: local.documentname }

class Client
  connect: (document_name, current_text_editor) ->

    @local_session = new Session(
      'local', document_name, current_text_editor)

    @remote_session = new Session(
      'remote', document_name, current_text_editor)

    doc = @local_session.session.get_document()

    doc.on('after op', (op, localop) ->
      remote_update_document_contents op unless localop
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
    @local_session.session.update_destroy()

setup_file_handlers = (local) ->
  local.add_handler(local.get_editor().onDidDestroy(local.destroy))
  local.add_handler(
    local.get_editor().onDidChangeCursorPosition((event) ->
      local.update_cursor_position event))
  local.get_buffer().on('changed', () ->
    local.update)

remote_update_document_contents = (op) ->
  if not @remote_session.session.is_op_same(
    op, @local_session.session.get_previous_operation())
    @remote_session.session.handle_op op
  @local_session.session.set_previous_operation op
  @remote_session.session.update_done_remote_op false

module.exports = () -> return new Client
