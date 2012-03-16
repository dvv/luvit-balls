Balls
=====

Collection of helpers to deal with compressed data

Usage
-----

```lua
local Zlib = require('balls').Zlib

local file = require('fs').createReadStream(__dirname .. '/test.gz', {
  chunk_size = 1,
})

local gunzip = Zlib.inflator()
gunzip:on('data', function (text)
  print('CHUNK', text)
end)
gunzip:on('end', function ()
  print('GUNZIPPED')
end)
file:pipe(gunzip)
```

License
-----

[MIT](luvit-balls.txt)
