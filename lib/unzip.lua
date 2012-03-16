#!/usr/bin/env luvit

local Zip = require('./zip').Zip
--
-- unzip
--
local function unzip(stream, options, callback)
  options = options or {}
  local zip = Zip:new(stream, options)
  -- write text to filename entry.name
  zip:on('entry', function (entry)
    --p(entry.name)
    Fs.mkdir_p(Path.dirname(entry.name), '0755', function (err)
      if err then zip:emit('error', err) ; return end
      Fs.writeFile(entry.name, entry.data, function (err)
      end)
    end)
  end)
  zip:once('end', function ()
    callback()
  end)
  zip:once('error', function (err)
    callback(err)
  end)
end



--local fp = require('fs').createReadStream('zlib.zip')
local fp = require('fs').createReadStream('python26.zip')
--local fp = require('fs').createReadStream('chrome-win32.zip')
--fp:pipe(process.stdout)

Zip:new(fp):on('entry', function(entry) print(entry.name) end)
