local insert
do
  local _table_0 = require('table')
  insert = _table_0.insert
end
local band, lshift
do
  local _table_0 = require('bit')
  band, lshift = _table_0.band, _table_0.lshift
end
local sub, byte, char
do
  local _table_0 = require('string')
  sub, byte, char = _table_0.sub, _table_0.byte, _table_0.char
end
local MAGIC_NUMBER = 0x04034b50
local BigEndianBinaryStream
BigEndianBinaryStream = (function()
  local _parent_0 = nil
  local _base_0 = {
    rewind = function(self)
      self.index = 0
      return 
    end,
    get_byte_at = function(self, index)
      return byte(self.buffer, index)
    end,
    get_number = function(self, bytes)
      local result = 0
      local i = self.index + bytes - 1
      while i >= self.index do
        result = lshift(result, 8) + self:get_byte_at(i + 1)
        i = i - 1
      end
      self.index = self.index + bytes
      return result
    end,
    get_short = function(self)
      return self:get_number(2)
    end,
    get_int = function(self)
      return self:get_number(4)
    end,
    get_string = function(self, len)
      local res = sub(self.buffer, self.index + 1, self.index + len)
      self.index = self.index + len
      return res
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, data)
      self.buffer = data
      return self:rewind()
    end
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local read
read = function(text)
  local buffer = BigEndianBinaryStream(text)
  if buffer:get_int() ~= MAGIC_NUMBER then
    error('File is not a Zip file')
  end
  buffer:rewind()
  local entries = { }
  while buffer:get_int() == MAGIC_NUMBER do
    local entry = { }
    entry.versionNeeded = buffer:get_short()
    local bitFlag = buffer:get_short()
    if band(bitFlag, 0x01) == 0x01 then
      error('File contains encrypted entry. Not supported')
    end
    if band(bitFlag, 0x0800) == 0x0800 then
      error('File is using UTF8. Not supported')
    end
    if band(bitFlag, 0x0008) == 0x0008 then
      error('File is using bit 3 trailing data descriptor. Not supported')
    end
    entry.bitFlags = bitFlags
    entry.compressionMethod = buffer:get_short()
    entry.timeBlob = buffer:get_int()
    entry.crc32 = buffer:get_int()
    entry.compressedSize = buffer:get_int()
    entry.uncompressedSize = buffer:get_int()
    if entry.compressedSize == 0xFFFFFFFF or entry.uncompressedSize == 0xFFFFFFFF then
      error('File is using Zip64 (4gb+ file size). Not supported')
    end
    entry.fileNameLength = buffer:get_short()
    entry.extraFieldLength = buffer:get_short()
    entry.fileName = buffer:get_string(entry.fileNameLength)
    entry.extra = buffer:get_string(entry.extraFieldLength)
    entry.data = buffer:get_string(entry.compressedSize)
    entry.data = ''
    if type(entry.data) == 'string' then
      insert(entries, {
        1
      })
      entries[entry.fileName] = {
        2
      }
    else
      break
    end
  end
  return entries
end
local file = require('fs').read_file_sync('test.zip', 'utf8')
local zip = read(file)
for k, v in ipairs(zip) do
  p(k)
end
