## Easy Handle for Debugging ##
#atom.config.get('collaborative-edit:Debug')
class Utils

  isdebug: atom.config.get('collaborative-edit.Debug')

  debug: (str) ->
    console.log str if utils.isdebug

module.exports = new utils()
