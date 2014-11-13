## Easy Handle for Debugging ##
utils =
  {
    isDebug: atom.config.get('collaborative-edit:Debug')

    debug: (str) ->
      console.log str if utils.isDebug
  }

module.exports = utils
