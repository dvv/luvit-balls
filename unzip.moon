import insert from require 'table'
import band, lshift from require 'bit'
import sub, byte, char from require 'string'

MAGIC_NUMBER = 0x04034b50

class BigEndianBinaryStream
  new: (data) =>
    @buffer = data
    @rewind()

  rewind: () =>
    @index = 0
    return

  get_byte_at: (index) =>
    byte @buffer, index

  -- N.B. Big endian, count down
  get_number: (bytes) =>
    result = 0
    i = @index + bytes - 1
    while i >= @index
      result = lshift(result, 8) + @get_byte_at(i + 1)
      i = i - 1
    @index = @index + bytes
    result

  get_short: () =>
    @get_number 2

  get_int: () =>
    @get_number 4

  get_string: (len) =>
    res = sub @buffer, @index + 1, @index + len
    @index = @index + len
    res

read = (text) ->
  buffer = BigEndianBinaryStream text

  error 'File is not a Zip file' if buffer\get_int() != MAGIC_NUMBER
  buffer\rewind()

  entries = {}

  while buffer\get_int() == MAGIC_NUMBER
    --error 'Bad signature'

    entry = {}

    entry.versionNeeded = buffer\get_short()
    bitFlag = buffer\get_short()

    if band(bitFlag, 0x01) == 0x01
      error 'File contains encrypted entry. Not supported'

    if band(bitFlag, 0x0800) == 0x0800
      error 'File is using UTF8. Not supported'

    if band(bitFlag, 0x0008) == 0x0008
      error 'File is using bit 3 trailing data descriptor. Not supported'

    entry.bitFlags = bitFlags
    entry.compressionMethod = buffer\get_short()
    entry.timeBlob = buffer\get_int()
    entry.crc32 = buffer\get_int()
    entry.compressedSize = buffer\get_int()
    entry.uncompressedSize = buffer\get_int()

    if entry.compressedSize == 0xFFFFFFFF or entry.uncompressedSize == 0xFFFFFFFF
      error 'File is using Zip64 (4gb+ file size). Not supported'

    entry.fileNameLength = buffer\get_short()
    entry.extraFieldLength = buffer\get_short()

    entry.fileName = buffer\get_string entry.fileNameLength
    entry.extra = buffer\get_string entry.extraFieldLength
    entry.data = buffer\get_string entry.compressedSize
    entry.data = ''

    if type(entry.data) == 'string'
      insert entries, {1} --entry
      entries[entry.fileName] = {2} --entry
    else
      break

  entries

-- export
--return Unzip

-----
file = require('fs').read_file_sync('test.zip', 'utf8')
zip = read(file)
--p(zip)
for k, v in ipairs zip
  p(k)
