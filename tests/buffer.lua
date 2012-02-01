local String = require('string')
local Table = require('table')
local Buffer = require('buffer')

local exports = { }

function Buffer.prototype:readString(offset, length)
  if not length then length = self.length end
  if offset + length - 1 > self.length then length = self.length - offset + 1 end
  local parts = {}
  local nparts = 1
  for i = offset, offset + length - 1 do
    parts[nparts] = String.char(self[i])
    nparts = nparts + 1
  end
  return Table.concat(parts, "")
end

exports['buffer can be sliced'] = function (test)
  local buf = Buffer:new('foobar')
  test.equal(buf:readUInt8(1), 0x66)
  test.equal(buf:readString(2, 4), 'ooba')
  test.equal(buf:readString(2), 'oobar')
  test.done()
end

return exports
