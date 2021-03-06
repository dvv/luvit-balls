/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#include <lauxlib.h>
#include <lua.h>

typedef struct {
  z_stream stream;
  int (*filter)(z_stream *, int);
  int (*end)(z_stream *);
} z_t;

const char *flush_opts[] = {
  "none", "sync", "full", "finish", NULL
};

static int lz_write(lua_State *L) {

  z_t *z;
  int flush;
  int rc;
  luaL_Buffer buff;

  lua_getfield(L, 1, "stream");
  z = (z_t *)lua_touserdata(L, -1);
  lua_pop(L, 1);

  printf("Z1: %p\n", z);
  z->stream.next_in = (char *)luaL_checklstring(L, 2, &z->stream.avail_in);

  flush = luaL_checkoption(L, 3, flush_opts[3], flush_opts);
  if (flush) flush++;

  luaL_buffinit(L, &buff);
	while (z->stream.avail_in) {
    z->stream.next_out = luaL_prepbuffer(&buff);
    z->stream.avail_out = LUAL_BUFFERSIZE;
    rc = z->filter(&z->stream, flush);
    if (rc != Z_BUF_ERROR) {
      if (rc != Z_OK && rc != Z_STREAM_END) {
        return luaL_error(L, "decode: %d", rc);
      }
    }
    luaL_addsize(&buff, LUAL_BUFFERSIZE - z->stream.avail_out);
	}
  luaL_pushresult(&buff);

  if (rc == Z_STREAM_END) {
    rc = z->end(&z->stream);
    if (rc != Z_OK) {
      return luaL_error(L, "decode: %d", rc);
    }
  } else {
  }
  lua_pushinteger(L, rc);
  return 2;
}

static int lz_close(lua_State *L) {
  int rc;
  lua_getfield(L, -1, "stream");
  z_t *z = (z_t *)lua_touserdata(L, -1);
  printf("Z: %p\n", z);
  if (z) {
    rc = z->end ? z->end(&z->stream) : Z_OK;
    /* drop methods */
    /*lua_pushnil(L);
    lua_setfield(L, -2, "stream");
    lua_pushnil(L);
    lua_setfield(L, -2, "write");
    lua_pushnil(L);
    lua_setfield(L, -2, "close");*/
  }
  lua_pop(L, 1);
  return 1;
}

static const char *methods[] = {
  "inflate", "deflate", NULL
};

static int lz_new(lua_State *L) {

  z_t *z = (z_t *)malloc(sizeof(*z));
  memset(z, 0, sizeof(*z));

  int method = luaL_checkoption(L, 1, NULL, methods);
  if (method == 0) {
    int window_size = lua_isnumber(L, 2) ? lua_tonumber(L, 2) : MAX_WBITS + 32;
    int rc = inflateInit2(&z->stream, window_size);
    if (rc != Z_OK && rc != Z_STREAM_END) {
      return luaL_error(L, "inflateInit2: %d", rc);
    }
    z->filter = inflate;
    z->end = inflateEnd;
  } else if (method == 1) {
    int level = luaL_optint(L, 2, Z_DEFAULT_COMPRESSION);
    int rc = deflateInit(&z->stream, level);
    if (rc != Z_OK && rc != Z_STREAM_END) {
      return luaL_error(L, "deflateInit: %d", rc);
    }
    z->filter = deflate;
    z->end = deflateEnd;
  } else {
    return luaL_error(L, "zlib: unsupported method: %s", method);
  }

  lua_newtable(L);
  lua_pushlightuserdata(L, z);
printf("Z0: %p\n", z);
  lua_setfield(L, -2, "stream");
  lua_pushstring(L, methods[method]);
  lua_setfield(L, -2, "method");
  lua_pushcfunction(L, lz_write);
  lua_setfield(L, -2, "write");
  lua_pushcfunction(L, lz_close);
  lua_setfield(L, -2, "close");

  return 1;
}

static const luaL_Reg exports[] = {
  { "new", lz_new },
  { NULL,      NULL           }
};

LUALIB_API int luaopen_zlib(lua_State *L) {

  /* module table */
  lua_newtable(L);

  /* constants */
  lua_pushstring(L, ZLIB_VERSION);
  lua_setfield(L, -2, "version");

  luaL_register(L, NULL, exports);

  return 1;
}
