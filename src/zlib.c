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

/**
 * @upvalue z_stream - Memory for the z_stream.
 * @upvalue remainder - Any remainder from the last deflate call.
 *
 * @param string - "print" to deflate stream.
 * @param int - flush output buffer? Z_SYNC_FLUSH, Z_FULL_FLUSH, or Z_FINISH.
 *
 * if no params, terminates the stream (as if we got empty string and Z_FINISH).
 */
static int lz_filter_impl(
    lua_State *L,
    int (*filter)(z_streamp, int),
    int (*end)(z_streamp), char* name)
{
   z_stream *stream;
   int flush = Z_NO_FLUSH, rc;
   luaL_Buffer buff;
   size_t avail_in;

  if (filter == deflate) {
    const char *const opts[] = { "none", "sync", "full", "finish", NULL };
    flush = luaL_checkoption(L, 2, opts[0], opts);
    if (flush) flush++;
    /* Z_NO_FLUSH(0) Z_SYNC_FLUSH(2), Z_FULL_FLUSH(3), Z_FINISH (4) */

    /* no arguments or nil? terminate the stream */
    if (lua_gettop(L) == 0 || lua_isnil(L, 1)) {
      flush = Z_FINISH;
    }
  }

  stream = (z_stream *)lua_touserdata(L, lua_upvalueindex(1));
  if (stream == NULL) {
    if (lua_gettop(L) >= 1 && lua_isstring(L, 1)) {
      return luaL_error(L, "%s: stream is closed", name);
    }
    lua_pushstring(L, "");
    lua_pushboolean(L, 1);
    return 2;
  }

  luaL_buffinit(L, &buff);

  if (lua_gettop(L) > 1) {
    lua_pushvalue(L, 1);
  }

  if (lua_isstring(L, lua_upvalueindex(2))) {
    lua_pushvalue(L, lua_upvalueindex(2));
    if (lua_gettop(L) > 1 && lua_isstring(L, -2)) {
      lua_concat(L, 2);
    }
  }

  /* perform inflate/deflate */
  stream->next_in = (unsigned char *)lua_tolstring(L, -1, &avail_in);
  stream->avail_in = avail_in;
  if (!stream->avail_in && !flush) {
    /* empty string results in noop */
    lua_pushstring(L, "");
    lua_pushboolean(L, 0);
    lua_pushinteger(L, stream->total_in);
    lua_pushinteger(L, stream->total_out);
    return 4;
  }

  do {
    stream->next_out  = (unsigned char *)luaL_prepbuffer(&buff);
    stream->avail_out = LUAL_BUFFERSIZE;
    rc = filter(stream, flush);
    /* Ignore Z_BUF_ERROR since that just indicates that we
     * need a larger buffer in order to proceed. Thanks to
     * Tobias Markmann for finding this bug!
     */
    if (Z_BUF_ERROR != rc) {
      if (rc != Z_OK && rc != Z_STREAM_END) {
        return luaL_error(L, "%s-ing: %d", name, rc);
      }
    }
    luaL_addsize(&buff, LUAL_BUFFERSIZE - stream->avail_out);
  } while (stream->avail_out == 0);

  /* need to do this before we alter the stack */
  luaL_pushresult(&buff);

  /* save remainder in lua_upvalueindex(2) */
  if (stream->next_in != NULL) {
    lua_pushlstring(L, (char *)stream->next_in, stream->avail_in);
    lua_replace(L, lua_upvalueindex(2));
  }

  /* "close" the stream/remove finalizer */
  if (Z_STREAM_END == rc) {
    /*  Clear-out the metatable so end is not called twice: */
    lua_pushnil(L);
    lua_setmetatable(L, lua_upvalueindex(1));

    /*  nil the upvalue: */
    lua_pushnil(L);
    lua_replace(L, lua_upvalueindex(1));

    /*  Close the stream: */
    rc = end(stream);
    if (rc != Z_OK) {
      return luaL_error(L, "%s: %d", name, rc);
    }

    lua_pushboolean(L, 1);
  } else {
    lua_pushboolean(L, 0);
  }
  lua_pushinteger(L, stream->total_in);
  lua_pushinteger(L, stream->total_out);
  return 4;
}

static int lz_deflate(lua_State *L) {
  return lz_filter_impl(L, deflate, deflateEnd, "deflate");
}

static int lz_deflate_new(lua_State *L) {
  int level = luaL_optint(L, 1, Z_DEFAULT_COMPRESSION);

  z_stream *stream = (z_stream *)lua_newuserdata(L, sizeof(z_stream));
  memset(stream, 0, sizeof(z_stream));

  int rc = deflateInit(stream, level);
  if (rc != Z_OK && rc != Z_STREAM_END) {
    return luaL_error(L, "deflateInit: %d", rc);
  }

  luaL_getmetatable(L, "zlib_deflate");
  lua_setmetatable(L, -2);

  lua_pushnil(L);
  lua_pushcclosure(L, lz_deflate, 2);

  return 1;
}

static int lz_deflate_delete(lua_State *L) {
  z_stream *stream  = (z_stream *)lua_touserdata(L, 1);
  deflateEnd(stream);
  return 0;
}

static int lz_inflate(lua_State *L) {
  return lz_filter_impl(L, inflate, inflateEnd, "inflate");
}

static int lz_inflate_new(lua_State *L) {
  z_stream *stream = (z_stream *)lua_newuserdata(L, sizeof(z_stream));
  memset(stream, 0, sizeof(z_stream));

  int window_size = lua_isnumber(L, 1) ? lua_tonumber(L, 1) : MAX_WBITS + 32;

  int rc = inflateInit2(stream, window_size);
  if (rc != Z_OK && rc != Z_STREAM_END) {
    return luaL_error(L, "inflateInit2: %d", rc);
  }

  luaL_getmetatable(L, "zlib_inflate");
  lua_setmetatable(L, -2);

  lua_pushnil(L);
  lua_pushcclosure(L, lz_inflate, 2);

  return 1;
}

static int lz_inflate_delete(lua_State *L) {
  z_stream *stream = (z_stream *)lua_touserdata(L, 1);
  inflateEnd(stream);
  return 0;
}

static const luaL_Reg exports[] = {
  { "deflate", lz_deflate_new },
  { "inflate", lz_inflate_new },
  { NULL,      NULL           }
};

LUALIB_API int luaopen_zlib(lua_State *L) {

  luaL_newmetatable(L, "zlib_deflate");
  lua_pushcfunction(L, lz_deflate_delete);
  lua_setfield(L, -2, "__gc");
  lua_pop(L, 1);

  luaL_newmetatable(L, "zlib_inflate");
  lua_pushcfunction(L, lz_inflate_delete);
  lua_setfield(L, -2, "__gc");
  lua_pop(L, 1);

  /* module table */
  lua_newtable(L);

  /* constants */
  lua_pushstring(L, ZLIB_VERSION);
  lua_setfield(L, -2, "version");

#ifdef EXPOSE_CONSTANTS
    /* error codes */
  lua_pushinteger(L, Z_OK);
  lua_setfield(L, -2, "OK");
  lua_pushinteger(L, Z_STREAM_END);
  lua_setfield(L, -2, "STREAM_END");
  lua_pushinteger(L, Z_NEED_DICT);
  lua_setfield(L, -2, "NEED_DICT");
  lua_pushinteger(L, Z_ERRNO);
  lua_setfield(L, -2, "ERRNO");
  lua_pushinteger(L, Z_STREAM_ERROR);
  lua_setfield(L, -2, "STREAM_ERROR");
  lua_pushinteger(L, Z_DATA_ERROR);
  lua_setfield(L, -2, "DATA_ERROR");
  lua_pushinteger(L, Z_MEM_ERROR);
  lua_setfield(L, -2, "MEM_ERROR");
  lua_pushinteger(L, Z_BUF_ERROR);
  lua_setfield(L, -2, "BUF_ERROR");
  lua_pushinteger(L, Z_VERSION_ERROR);
  lua_setfield(L, -2, "VERSION_ERROR");

    /* flush values */
  lua_pushinteger(L, Z_NO_FLUSH);
  lua_setfield(L, -2, "NO_FLUSH");
  lua_pushinteger(L, Z_PARTIAL_FLUSH);
  lua_setfield(L, -2, "PARTIAL_FLUSH");
  lua_pushinteger(L, Z_SYNC_FLUSH);
  lua_setfield(L, -2, "SYNC_FLUSH");
  lua_pushinteger(L, Z_FULL_FLUSH);
  lua_setfield(L, -2, "FULL_FLUSH");
  lua_pushinteger(L, Z_FINISH);
  lua_setfield(L, -2, "FINISH");
  lua_pushinteger(L, Z_BLOCK);
  lua_setfield(L, -2, "BLOCK");
  lua_pushinteger(L, Z_TREES);
  lua_setfield(L, -2, "TREES");

    /* compression levels */
  lua_pushinteger(L, Z_NO_COMPRESSION);
  lua_setfield(L, -2, "NO_COMPRESSION");
  lua_pushinteger(L, Z_BEST_SPEED);
  lua_setfield(L, -2, "BEST_SPEED");
  lua_pushinteger(L, Z_BEST_COMPRESSION);
  lua_setfield(L, -2, "BEST_COMPRESSION");
  lua_pushinteger(L, Z_DEFAULT_COMPRESSION);
  lua_setfield(L, -2, "DEFAULT_COMPRESSION");

    /* compression strategy */
  lua_pushinteger(L, Z_DEFAULT_STRATEGY);
  lua_setfield(L, -2, "DEFAULT_STRATEGY");
  lua_pushinteger(L, Z_FILTERED);
  lua_setfield(L, -2, "FILTERED");
  lua_pushinteger(L, Z_HUFFMAN_ONLY);
  lua_setfield(L, -2, "HUFFMAN_ONLY");
  lua_pushinteger(L, Z_RLE);
  lua_setfield(L, -2, "RLE");
  lua_pushinteger(L, Z_FIXED);
  lua_setfield(L, -2, "FIXED");

    /* data type */
  lua_pushinteger(L, Z_BINARY);
  lua_setfield(L, -2, "BINARY");
  lua_pushinteger(L, Z_TEXT);
  lua_setfield(L, -2, "TEXT");
  lua_pushinteger(L, Z_ASCII);
  lua_setfield(L, -2, "ASCII");
  lua_pushinteger(L, Z_UNKNOWN);
  lua_setfield(L, -2, "UNKNOWN");

    /* misc */
  lua_pushinteger(L, Z_DEFLATED);
  lua_setfield(L, -2, "DEFLATED");
  lua_pushinteger(L, Z_NULL);
  lua_setfield(L, -2, "NULL");
#endif

  luaL_register(L, NULL, exports);

  return 1;
}
