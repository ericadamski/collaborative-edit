{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
RemoteSession = require './remote'
LocalSession = require './local'
utils = require '../Utils/utils'

# Each client will have two session objects, a remote and a local.
# This will attempt to reduce the number of collsions and keep the code in a
# more readable state.

module.exports = class ClientSession
  constructor: (@type, @document_name, current_text_editor) ->
    switch @type
      when 'local'
        @session = new LocalSession @document_name, current_text_editor
      when 'remote' then @session = new RemoteSession current_text_editor
