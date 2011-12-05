local band
do
  local _table_0 = require('bit')
  band = _table_0.band
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
      self.index = 1
      return 
    end,
    get_byte_at = function(self, index)
      return byte(self.buffer, index)
    end,
    get_number = function(self, bytes)
      local result = 0
      local i = self.index + bytes - 1
      while i >= self.index do
        result = result * 256 + self:get_byte_at(i)
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
      local res = sub(self.buffer, self.index, self.index + len - 1)
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
  local index = 0
  local entries = { }
  while buffer:get_int() == MAGIC_NUMBER do
    local entry = { }
    index = index + 1
    entry.index = index
    local version = buffer:get_short()
    local flags = buffer:get_short()
    if band(flags, 0x01) == 0x01 then
      error('File contains encrypted entry. Not supported')
    end
    if band(flags, 0x0800) == 0x0800 then
      error('File is using UTF8. Not supported')
    end
    if band(flags, 0x0008) == 0x0008 then
      error('File is using bit 3 trailing data descriptor. Not supported')
    end
    entry.comp_method = buffer:get_short()
    entry.mtime = buffer:get_int()
    entry.crc = buffer:get_int()
    entry.comp_size = buffer:get_int()
    entry.size = buffer:get_int()
    if entry.comp_size == 0xFFFFFFFF or entry.size == 0xFFFFFFFF then
      error('File is using Zip64 (4gb+ file size). Not supported')
    end
    local name_len = buffer:get_short()
    local extra_len = buffer:get_short()
    entry.name = buffer:get_string(name_len)
    entry.extra = buffer:get_string(extra_len)
    entry.data = buffer:get_string(entry.comp_size)
    if type(entry.data) == 'string' then
      entries[entry.name] = entry
    else
      break
    end
  end
  return entries
end
local file = require('fs').read_file_sync('test.zip', 'utf8')
local zip = read(file)
local ffi = require('ffi')
ffi.cdef([[unsigned long compressBound(unsigned long sourceLen);
int compress2(uint8_t *dest, unsigned long *destLen,
      const uint8_t *source, unsigned long sourceLen, int level);
int uncompress(uint8_t *dest, unsigned long *destLen,
       const uint8_t *source, unsigned long sourceLen);
]])
local zlib = ffi.load(ffi.os == 'Windows' and "zlib1" or 'z')
local entry = zip['sockjs-sockjs-client-20c0df3/Makefile']
local data = entry.data
entry.data = nil
print(data)
local Zlib = require('./zlib')
local s = Zlib.inflate(-15)(data, 'finish')
p(s)
