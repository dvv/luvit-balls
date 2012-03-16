#!/usr/bin/env luvit

local Table = require('table')

local Zlib = require('../lib/zlib')

local file = require('fs').createReadStream(__dirname .. '/test.gz', {
  chunk_size = 1,
})
local gunzip = Zlib.inflator()
local buf = {}
gunzip:on('data', function (text)
  buf[#buf + 1] = text
end)
gunzip:on('end', function ()
  assert(Table.concat(buf) == 'test\n')
end)
file:pipe(gunzip)
