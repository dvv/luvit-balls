import band from require 'bit'
import sub, byte, char from require 'string'
import insert from require 'table'

Zlib = require './zlib'

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

Zip_prototype =

  get: (name) =>
    entry = self[name]
    if entry.comp_method > 0
      ok, text = pcall Zlib.inflate(-15), entry.data, 'finish'
      if ok
        text
      else
        ''
    else
      entry.data


  read: (text) =>
    buffer = BigEndianBinaryStream text

    error 'File is not a Zip file' if buffer\get_int() != MAGIC_NUMBER
    buffer\rewind()

    index = 0
    self.entries = {}

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
        -- index by name
        self.entries[entry.name] = entry
        -- index by position
        insert self.entries, entry
      else
        break

    self.entries

Zip =

  new: () ->
    self = {}
    setmetatable self, __index: Zip_prototype

-----
Path = require 'path'
Fs = require('./util')

-- TODO: make streaming

zip = Zip.new()
zip = zip.read(Fs.read_file_sync('test.zip', 'utf8'))
--p(zip)

Fiber = require 'fiber'
Fiber.new (resume, wait) ->
  err = nil
  i = nil
  k = nil
  v = nil
  --for k, v in ipairs zip
  for i, v in ipairs zip
    k = v.name
    Fs.mkdir_p Path.dirname(k), '0755', resume
    err = wait()
    if err
      p k, err
      break
    if v.size > 0 and v.comp_size > 0
      text = zip\get k
      Fs.write_file k, text, resume
      err = wait()
      if err
        p k, err
        break

--p zip.get 'sockjs-sockjs-client-20c0df3/.gitignore'
--p zip.get 'sockjs-sockjs-client-20c0df3/version'
