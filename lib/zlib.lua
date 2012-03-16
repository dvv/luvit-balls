local Zlib = require('../build/zlib')

--
-- generic zlib stream
--

local iZlib = require('core').iStream:extend()

function iZlib:initialize(what, ...)
  self.fn = Zlib[what](...)
end

function iZlib:write(chunk)
  local flag = chunk == '' and 'finish' or nil
  local text, err = self.fn(chunk, flag)
  if not text then
    self:emit('error', err)
  else
    if #text > 0 then
      self:emit('data', text)
    end
    self:emit('drain')
  end
end

function iZlib:done()
  self.fn = nil
  self:emit('end')
end

--
-- shortcuts
--

local function inflator(...)
  return iZlib:new('inflate', ...)
end

local function deflator(...)
  return iZlib:new('deflate', ...)
end

--
-- module
--

return {
  iZlib = iZlib,
  inflator = inflator,
  deflator = deflator,
}
