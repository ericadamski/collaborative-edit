exports.debug = (string) ->
  console.log string if atom.config.get 'collaborative-edit.Debug'

exports.now = ->
  new Date().getTime()
