#!/usr/bin/env luvit

local bind = require('utils').bind
local FilterStream = require('core').iStream:extend()

local function identity(data, callback) callback(nil, data) end

--[[
local function proxy(self, name, fn)
  return bind(self[name], self
  fn(chunk, function (err, ...)
    if err then
      self.stream:emit('error', err)
    else
      self.stream:emit(name, ...)
    end
  end)
end
]]--

function FilterStream:initialize(stream, read_fn, write_fn, options)
  self.stream = stream
  self.read_fn = read_fn or identity
  self.write_fn = write_fn or identity
  self.options = options or {}
  self:on('data', bind(self.onData, self))
  self:on('end',   function (...) p('END  '); self.stream:emit('end', ...) end)
  self:on('close', function (...) p('CLOSE'); self.stream:emit('close', ...) end)
  self:on('drain', function (...) p('DRAIN'); self.stream:emit('drain', ...) end)
end

function FilterStream:onData(chunk)
    p('READ', chunk)
  self.read_fn(chunk, function (err, ...)
    if err then
      self.stream:emit('error', err)
    else
      self.stream:emit('data', ...)
    end
  end)
end

function FilterStream:write(chunk, callback)
  self.write_fn(chunk, function (err, ...)
    if err then
      self.stream:emit('error', err)
    else
      self.stream:write(..., callback)
    end
  end)
end

--[[
local stream = require('core').Emitter:extend()

FilterStream:new(function (chunk, callback)
  local s = chunk:upper()
  p('READ', chunk)
  callback(nil, s)
end, function (chunk, callback)
  local s = chunk:lower()
  p('WRITE', chunk)
  callback(nil, s)
end):on('message', require('utils').bind(print, 'READ')):emit('data', 'foooo1'):write('fFoOOOb 1 aRrr')
]]--

local Zlib = require('../build/zlib')
local function make_(typ, ...)
  local fn = Zlib[typ](...)
  return function (chunk, callback)
    p(typ .. ':CHUNK', chunk)
    callback(nil, fn(chunk))
  end
end

local ps = require('fs').createReadStream('zip.lua') --FilterStream:extend()
local zs = FilterStream:new(ps, nil, make_('deflate'))
ps:pipe(zs)--process.stdout)

--[[
function ZStream:initialize(typ, options)
  typ = typ or 'inflate'
  options = options or {}
  self.filter = require('../build/zlib')[typ]()
end

function ZStream:write(chunk, callback)
  local processed = self.filter(chunk)
  self.target:write
end]]--

--[[
  print('WRITTEN', chunk)
  if callback then callback() end
]]--
