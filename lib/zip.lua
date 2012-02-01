local Fs = require('meta-fs')
local Path = require('path')
local Zlib = require('../zlib')
local band = require('bit').band

--
-- walk over entries of a zipball read from `stream`
--
local function walk(stream, options, callback)

  -- defaults
  if not options then options = {} end

  -- data buffer and current position pointers
  local buffer = ''
  local pos = 1
  local anchor = 1 -- preserved between calls to parse()

  -- get big-endian number of specified length
  local function get_number(bytes)
    local result = 0
    local i = pos + bytes - 1
    while i >= pos do
      result = result * 256 + buffer:byte(i)
      i = i - 1
    end
    pos = pos + bytes
    return result
  end

  -- get string of specified length
  local function get_string(len)
    local result = buffer:sub(pos, pos + len - 1)
    pos = pos + len
    return result
  end

  -- parse collected buffer
  local function parse()
    pos = anchor
    -- wait until header is available
    if pos + 30 >= #buffer then return end

    -- ensure header signature is ok
    local signature = get_string(4)
    if signature ~= 'PK\003\004' then
      -- start of central directory?
      if signature == 'PK\001\002' then
        -- unzipping is done
        stream:emit('end')
      -- signature is not ok
      else
        -- report error
        stream:emit('error', 'File is not a Zip file')
      end
      return
    end

    -- read entry data
    local entry = {}
    local version = get_number(2)
    local flags = get_number(2)
    entry.comp_method = get_number(2)
    entry.mtime = get_number(4)
    entry.crc = get_number(4)
    entry.comp_size = get_number(4)
    entry.size = get_number(4)

    -- sanity check
    local err = nil
    if band(flags, 0x01) == 0x01 then
      err = 'File contains encrypted entry'
    elseif band(flags, 0x0800) == 0x0800 then
      err = 'File is using UTF8'
    elseif band(flags, 0x0008) == 0x0008 then
      err = 'File is using bit 3 trailing data descriptor'
    elseif entry.comp_size == 0xFFFFFFFF or entry.size == 0xFFFFFFFF then
      err = 'File is using Zip64 (4gb+ file size)'
    end
    if err then
      stream:emit('error', {
        code = 'ENOTSUPP',
        message = err,
      })
    end

    -- wait until compressed data available
    local name_len = get_number(2)
    local extra_len = get_number(2)
    if pos + name_len + extra_len + entry.comp_size >= #buffer then return end

    -- read entry name and data
    local name = get_string(name_len)
    -- strip `options.strip` leading path chunks
    -- TODO: strip only `options.strip` components
    if options.strip then
      name = name:gsub('[^/]*/', '', options.strip)
    end
    -- prepend entry name with optional prefix
    if options.prefix then
      name = Path.join(options.prefix, name)
    end
    entry.name = name
    --
    entry.extra = get_string(extra_len)
    -- TODO: stream compressed data too
    entry.data = get_string(entry.comp_size)
    -- shift the buffer, to save memory
    buffer = buffer:sub(pos)
    anchor = 1

    -- fire 'entry' event
    stream:emit('entry', stream, entry)
    -- process next entry
    parse()

  end

  --
  -- feed data to parser
  local function ondata(data)
    buffer = buffer .. data
    parse()
  end
  stream:on('data', ondata)
  -- end of stream means we're done ok
  stream:on('end', function ()
    callback()
  end)
  -- read error means we're done in error
  stream:once('error', function (err)
    stream:remove_listener('data', ondata)
    callback(err)
  end)

  return stream
end

--
-- inflate and save to file specified zip entry
--
local function unzip_entry(stream, entry)
  -- inflate
  local text
  local ok
  -- comp_method == 0 means data is stored as-is
  if entry.comp_method > 0 then
    -- TODO: how to stream data?
    ok, text = pcall(Zlib.inflate(-15), entry.data, 'finish')
    if not ok then text = '' end
  else
    text = entry.data
  end
  -- write inflated entry data
  --p(entry.name)
  Fs.mkdir_p(Path.dirname(entry.name), '0755', function (err)
    if err then stream:emit('error', err) ; return end
    Fs.write_file(entry.name, text, function (err)
    end)
  end)
end

--
-- unzip
--
local function unzip(stream, options, callback)
  if not options then options = {} end
  if type(stream) == 'string' then
    stream = Fs.create_read_stream(stream)
  end
  stream:on('entry', unzip_entry)
  return walk(stream, {
    prefix = options.path,
    strip = options.strip,
  }, callback)
end

--
-- inflate
--
local function inflate(data, callback)
  -- TODO: should return stream
  local ok, value = pcall(Zlib.inflate(), data, 'finish')
  if not ok then
    callback(value)
  else
    callback(nil, value)
  end
end

-- export
return {
  unzip = unzip,
  inflate = inflate,
}
