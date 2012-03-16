#!/usr/bin/env luvit

local Zip = require('../lib/zip').Zip

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

local entries = {}
local uzip = Zip:new(
    require('fs').createReadStream(__dirname .. '/test.zip'),
    {
      inflateOptions = -15
    }
  )
  :on('entry', function (entry)
    entries[#entries + 1] = entry
    p('E', entry.name, entry.comp_method)
  end)
  :on('end', function ()
    assert(#entries == 2)
    assert(entries[1].name == 'all.gyp')
    assert(entries[2].name == 'license.txt')
  end)
