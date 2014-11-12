utils =
  {
    isDebug: false

    debug: (str) ->
      console.log str if utils.isDebug
  }

module.exports = utils
