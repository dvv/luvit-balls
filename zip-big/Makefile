VERSION := 0.10

all: module

module: build/zip.luvit

ROOT    := $(shell pwd)

build/zip.luvit: build/zip.c build/libzip/lib/.libs/libzip.a
	$(CC) -I$(LUA_DIR) -I$(ROOT)/build/libzip/lib -shared -o $@ $^ -lz

build/zip.c:
	mkdir -p build
	wget --no-check-certificate https://github.com/brimworks/lua-zip/raw/master/lua_zip.c -O - \
		| sed 's/luaopen_brimworks_zip/luaopen_zip/g' >$@

build/libzip/lib/.libs/libzip.a: build/libzip
	( cd $^; ./configure )
	$(MAKE) -C $^

build/libzip:
	mkdir -p build
	wget http://www.nih.at/libzip/libzip-$(VERSION).tar.gz -O - | tar -xzpf - -C build
	mv build/libzip-$(VERSION) $@

clean:
	rm -fr build

.PHONY: all module clean
.SILENT:
