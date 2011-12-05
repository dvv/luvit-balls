import band from require 'bit'
import sub, byte, char from require 'string'

MAGIC_NUMBER = 0x04034b50

class BigEndianBinaryStream
  new: (data) =>
    @buffer = data
    @rewind()

  rewind: () =>
    @index = 1
    return

  get_byte_at: (index) =>
    byte @buffer, index

  -- N.B. Big endian, count down
  get_number: (bytes) =>
    result = 0
    i = @index + bytes - 1
    while i >= @index
      result = result * 256 + @get_byte_at(i)
      i = i - 1
    @index = @index + bytes
    result

  get_short: () =>
    @get_number 2

  get_int: () =>
    @get_number 4

  get_string: (len) =>
    res = sub @buffer, @index, @index + len - 1
    @index = @index + len
    res

read = (text) ->
  buffer = BigEndianBinaryStream text

  error 'File is not a Zip file' if buffer\get_int() != MAGIC_NUMBER
  buffer\rewind()

  index = 0
  entries = {}

  while buffer\get_int() == MAGIC_NUMBER
    --error 'Bad signature'

    entry = {}

    index = index + 1
    entry.index = index
    version = buffer\get_short()
    flags = buffer\get_short()

    if band(flags, 0x01) == 0x01
      error 'File contains encrypted entry. Not supported'

    if band(flags, 0x0800) == 0x0800
      error 'File is using UTF8. Not supported'

    if band(flags, 0x0008) == 0x0008
      error 'File is using bit 3 trailing data descriptor. Not supported'

    entry.comp_method = buffer\get_short()
    entry.mtime = buffer\get_int()
    entry.crc = buffer\get_int()
    entry.comp_size = buffer\get_int()
    entry.size = buffer\get_int()

    if entry.comp_size == 0xFFFFFFFF or entry.size == 0xFFFFFFFF
      error 'File is using Zip64 (4gb+ file size). Not supported'

    name_len = buffer\get_short()
    extra_len = buffer\get_short()

    entry.name = buffer\get_string name_len
    entry.extra = buffer\get_string extra_len

    entry.data = buffer\get_string entry.comp_size
    --assert(#entry.data == entry.comp_size)
    --entry.data = ''
    --entry.ptr = buffer\index
    --entry.data = sub buffer.buffer, buffer.index - 32, buffer.index + entry.comp_size + 32 - 1

    if type(entry.data) == 'string'
      entries[entry.name] = entry
    else
      break

  entries

-- export
--return Unzip

-----
file = require('fs').read_file_sync('test.zip', 'utf8')
zip = read(file)
--p(zip)
--for k, v in ipairs zip
--  p(k)

entry = zip['sockjs-sockjs-client-20c0df3/Makefile']
--entry = zip['sockjs-sockjs-client-20c0df3/.gitignore']
data = entry.data
entry.data = nil
--p entry
print data
Zlib = require './zlib'
s = Zlib.inflate(-15) data, 'finish'
p(s)
