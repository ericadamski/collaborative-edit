## Easy Handle for Debugging ##
#atom.config.get('collaborative-edit:Debug')
class Utils

  isDebug: atom.config.get('collaborative-edit.Debug')

  debug: (str) ->
    console.log str if utils.isDebug

module.exports = new utils()
