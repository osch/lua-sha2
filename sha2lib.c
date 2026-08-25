#include <lua.h>
#include <lauxlib.h>
#include "sha2.h"

// source: md5lib.c from md5 Lua library
/**
*  X-Or. Does a bit-a-bit exclusive-or of two strings.
*  @param s1: arbitrary binary string.
*  @param s2: arbitrary binary string with same length as s1.
*  @return  a binary string with same length as s1 and s2,
*   where each bit is the exclusive-or of the corresponding bits in s1-s2.
*/
static int ex_or (lua_State *L) {
	size_t l1, l2;
	const char *s1 = luaL_checklstring(L, 1, &l1);
	const char *s2 = luaL_checklstring(L, 2, &l2);
	luaL_Buffer b;
	luaL_argcheck( L, l1 == l2, 2, "lengths must be equal" );
	luaL_buffinit(L, &b);
	while (l1--) luaL_addchar(&b, (*s1++)^(*s2++));
	luaL_pushresult(&b);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-256 hash string.
*/
static int sha256(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	SHA256_CTX context;
	uint8_t digest[SHA256_DIGEST_LENGTH];

	SHA256_Init(&context);
	SHA256_Update(&context, (const uint8_t*)data, len);
	SHA256_Final(digest, &context);

	lua_pushlstring(L, (const char*)digest, SHA256_DIGEST_LENGTH);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-256 hash string.
*/
static int sha256hex(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	char digest[SHA256_DIGEST_STRING_LENGTH];
	SHA256_Data((const uint8_t*)data, len, digest);
	lua_pushlstring(L, digest, SHA256_DIGEST_STRING_LENGTH - 1);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-384 hash string.
*/
static int sha384(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	SHA384_CTX context;
	uint8_t digest[SHA384_DIGEST_LENGTH];

	SHA384_Init(&context);
	SHA384_Update(&context, (const uint8_t*)data, len);
	SHA384_Final(digest, &context);

	lua_pushlstring(L, (const char*)digest, SHA384_DIGEST_LENGTH);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-384 hash string.
*/
static int sha384hex(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	char digest[SHA384_DIGEST_STRING_LENGTH];
	SHA384_Data((const uint8_t*)data, len, digest);
	lua_pushlstring(L, digest, SHA384_DIGEST_STRING_LENGTH - 1);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-512 hash string.
*/
static int sha512(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	SHA512_CTX context;
	uint8_t digest[SHA512_DIGEST_LENGTH];

	SHA512_Init(&context);
	SHA512_Update(&context, (const uint8_t*)data, len);
	SHA512_Final(digest, &context);

	lua_pushlstring(L, (const char*)digest, SHA512_DIGEST_LENGTH);
	return 1;
}

/**
*  @param: an arbitrary binary string.
*  @return: an SHA-512 hash string.
*/
static int sha512hex(lua_State *L) {
	size_t len;
	const char *data = luaL_checklstring(L, 1, &len);

	char digest[SHA512_DIGEST_STRING_LENGTH];
	SHA512_Data((const uint8_t*)data, len, digest);
	lua_pushlstring(L, digest, SHA512_DIGEST_STRING_LENGTH - 1);
	return 1;
}

static void set_info (lua_State *L) {
	lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, "sha2 0.2.1");
	lua_settable (L, -3);
}

typedef struct {
	const char *name;
	lua_CFunction func;
} sha2_reg;

static const sha2_reg reg[] = {
	{"exor", ex_or},
	{"sha256", sha256},
	{"sha256hex", sha256hex},
	{"sha384", sha384},
	{"sha384hex", sha384hex},
	{"sha512", sha512},
	{"sha512hex", sha512hex},
	{NULL, NULL}
};

int luaopen_sha2(lua_State *L) {
	int i, n = 0;
	while (reg[n].name) n++;
	lua_createtable(L, 0, n);
	for (i = 0; i < n; i++) {
		lua_pushstring(L, reg[i].name);
		lua_pushcfunction(L, reg[i].func);
		lua_rawset(L, -3);
	}
	set_info (L);
#if LUA_VERSION_NUM < 502
	lua_pushvalue(L, -1);
	lua_setglobal(L, "sha2");
#endif
	return 1;
}
