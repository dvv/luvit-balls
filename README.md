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

local Zip = require('balls').Zip
local uzip = Zip:new(
    require('fs').createReadStream(__dirname .. '/test.zip'),
    {
      -- TODO: auto guess
      inflateOptions = -15
    }
  )
  -- zip entry parsed
  :on('entry', function (entry)
    p('E', entry.name, entry.comp_size)
  end)
  -- zipball read entirely
  :on('end', function ()
    print('UNZIPPED')
  end)
```

License
-----

[MIT](luvit-balls.txt)
