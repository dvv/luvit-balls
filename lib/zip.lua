local band = require('bit').band
local Zlib = require('./zlib')

--
-- Zip archive walker
--
local Zip = require('core').iStream:extend()

-- TODO: make it more pure iStream
function Zip:initialize(stream, options)

  -- defaults
  options = options or {}

  -- we accept streams or filenames
  -- TODO: better to use strings to directly pass the buffer?
  if type(stream) == 'string' then
    stream = Fs.createReadStream(stream)
  end

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
        self:emit('end')
      -- signature is not ok
      else
        -- report error
        self:emit('error', 'not a Zip file')
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
      err = 'encrypted entry'
    elseif band(flags, 0x0800) == 0x0800 then
      err = 'using UTF8'
    elseif band(flags, 0x0008) == 0x0008 then
      err = 'using bit 3 trailing data descriptor'
    elseif entry.comp_size == 0xFFFFFFFF or entry.size == 0xFFFFFFFF then
      err = 'using Zip64'
    end
    if err then
      self:emit('error', { code = 'ENOTSUPP', message = err })
    end

    -- read entry name and data
    local name_len = get_number(2)
    local extra_len = get_number(2)
    if #buffer < pos + name_len + extra_len then
      return
    end
    entry.name = get_string(name_len)
    entry.extra = get_string(extra_len)

    -- wait until compressed data available
    -- TODO: we should stream here until entry.comp_size octets are seen!
    if pos + name_len + extra_len + entry.comp_size >= #buffer then
      return
    end
    entry.data = get_string(entry.comp_size)
    -- shift the buffer, to save memory
    buffer = buffer:sub(pos)
    anchor = 1

    -- comp_method == 0 means data is stored as-is
    if entry.comp_method == 0 then
      -- fire 'entry' event
      self:emit('entry', entry)
    else
      local z = Zlib.inflator(options.inflateOptions)
      z:on('end', function ()
        -- fire 'entry' event
        entry.data = data
        self:emit('entry', entry)
      end)
      z:write(entry.data)
      -- ???
      z:done()
    end

    -- process next entry
    parse()

  end

  -- feed data to parser
  local function ondata(data)
    buffer = buffer .. data
    parse()
  end
  stream:on('data', ondata)
  stream:once('error', function (err)
    stream:removeListener('data', ondata)
    self:emit('error', err)
  end)

end

-- export
return {
  Zip = Zip,
}
