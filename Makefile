#CFLAGS += -DEXPOSE_CONSTANTS

all: module

module: build/zlib.luvit
build/zlib.luvit: src/zlib.c
	mkdir -p build
	$(CC) $(CFLAGS) -Isrc/ -shared -o $@ $^ $(LDFLAGS)

clean:
	rm -fr build tmp

test: module
	checkit tests/buffer.lua tests/inflate.lua

.PHONY: all module clean test
.SILENT:
