Balls
=====

Collection of helpers to deal with zipballs

Usage
-----

```lua
-- import
local unzip = require('balls').unzip

-- unzip zipball 'foo.zip' into ./foo/zip
unzip('foo.zip', { path = 'foo/zip' }, function(err)
  print('DONE', err)
end)
```

License
-----

[MIT](luvit-balls.txt)
