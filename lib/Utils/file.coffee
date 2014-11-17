exports.baseName = (fileName) ->
    return '' if not fileName?
    directories = fileName.split '/'
    directories.slice(0, -1).join '/'

