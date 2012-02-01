all: module

module:
	$(MAKE) -C zlib

clean:
	rm -fr tmp zlib/build

test: module
	checkit tests/buffer.lua

.PHONY: all module clean test
.SILENT:
