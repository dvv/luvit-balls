#
# TODO: choose lzlib or brimworks's lua-zlib. The latter is simpler to use
#

#VERSION := 0.4-work3

all: module

module: build/zlib.luvit

build/zlib.luvit: build/zlib.c
	$(CC) `luvit-config --cflags` -shared -o $@ $^ -lz

build/zlib.c:
	mkdir -p build
	#wget http://files.luaforge.net/releases/lzlib/lzlib/lzlib-$(VERSION)/lzlib-$(VERSION).tar.gz -O - | tar -xzpf - -O lzlib-$(VERSION)/lzlib.c >$@
	wget -qct3 --no-check-certificate https://github.com/brimworks/lua-zlib/raw/master/lua_zlib.c -O $@

clean:
	rm -fr build

test:
	checkit tests/smoke.lua

.PHONY: all module clean
.SILENT:
