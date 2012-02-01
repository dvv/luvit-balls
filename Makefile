all: module

module:
	$(MAKE) -C zlib

clean:
	rm -fr tmp
	$(MAKE) -C zlib clean

test: module
	checkit tests/buffer.lua tests/inflate.lua

.PHONY: all module clean test
.SILENT:
