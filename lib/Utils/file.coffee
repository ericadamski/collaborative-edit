exports.baseName = (fileName) ->
    return '' if not fileName?
    directories = fileName.split '/'
    dirs.slice(0, -1).join '/'

