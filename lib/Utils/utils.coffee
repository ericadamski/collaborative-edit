class Utils
    isDebug: atom.config.get 'collaborative-edit.Debug'

    debug: (string) ->
        console.log string if @isDebug

module.exports = new Utils
