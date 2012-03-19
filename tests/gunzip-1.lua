#!/usr/bin/env luvit

local Table = require('table')
local Zlib = require('../build/zlib')

local testgz = require('fs').readFileSync(__dirname .. '/test.gz')


--p(Zlib.new('deflate'):write('test\n'))
--p(Zlib.new(''))
local inf = Zlib.new('inflate')
p(inf:write(testgz:sub(1, 24), 'none'))
p(inf:write(testgz:sub(25)))
--local def = Zlib.deflator()
--p(def('test\n', 'flush'))
