class File

  basename: (filename) ->
    dirs = filename?.split '/'
    return dirs.slice(0, -1).join '/'

module.exports = new File()
