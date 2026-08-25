package = 'sha2'
version = '0.2.1-1'
rockspec_format = '3.0'
source = {
	url = 'git+https://github.com/osch/lua-sha2',
	tag = 'v0.2.1',
}
description = {
	summary = 'SHA-256/384/512 hashing for Lua, plus HMAC',
	detailed = [[
		Lua binding for the SHA-2 (SHA-256/384/512) C implementation
		by Aaron Gifford. Provides binary and lowercase hex digests
		and a generic HMAC implementation with ready-made
		HMAC-SHA256/384/512 variants (HMAC-MD5 via the md5 rock).
		Works with Lua 5.1 up to 5.5 and LuaJIT.
	]],
	homepage = 'https://github.com/osch/lua-sha2',
	license = 'MIT',
}
dependencies = {
	'lua >= 5.1'
}

build = {
	type = 'builtin',
	modules = {
		sha2 = {
			sources = { 'sha2.c', 'sha2lib.c' },
			incdirs = { '.' },
		},
		hmac = 'hmac.lua',
		['hmac.sha2'] = 'hmac/sha2.lua',
		['hmac.md5'] = 'hmac/md5.lua',
	},
	copy_directories = { 'testvectors' },
}

test = {
	type = 'command',
	command = 'lua',
	flags = { 'run_tests.lua' },
}
