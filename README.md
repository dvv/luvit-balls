Usage
-----

    -- import
    local unzip = require('balls').unzip

    -- unzip zipball 'foo.zip' into ./foo/zip
    unzip('foo.zip', 'foo/zip', function(err)
      print('DONE', err)
    end)

License
-------

Check [here](license.txt).
