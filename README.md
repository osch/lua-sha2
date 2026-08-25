# sha2 — SHA-2 hashing for Lua

[![Tests](https://github.com/osch/lua-sha2/actions/workflows/ci.yml/badge.svg)](https://github.com/osch/lua-sha2/actions/workflows/ci.yml)
[![LuaRocks](https://img.shields.io/luarocks/v/osch/sha2?logo=lua&color=blue)](https://luarocks.org/modules/osch/sha2)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.txt)

Lua binding for Aaron D. Gifford's public-domain [SHA-2](https://en.wikipedia.org/wiki/SHA-2)
C implementation. Provides SHA-256, SHA-384 and SHA-512 digests as binary strings or
lowercase hex strings, plus a generic [HMAC](https://tools.ietf.org/html/rfc2104) implementation.

Works with **Lua 5.1, 5.2, 5.3, 5.4, 5.5** and **LuaJIT**.

## Features

* `sha256`, `sha384`, `sha512` — binary digests
* `sha256hex`, `sha384hex`, `sha512hex` — lowercase hex digests
* `exor` — bytewise XOR helper for two equal-length binary strings
* Generic HMAC (`hmac.compute`, `hmac.new`) plus ready-made
  HMAC-SHA256/384/512 and HMAC-MD5 (MD5 via the [`md5`](https://luarocks.org/modules/tomasguisasola/md5) rock)
* No runtime dependencies beyond Lua itself

## Installation

```sh
luarocks install sha2
```

Or from a git checkout:

```sh
git clone https://github.com/osch/lua-sha2.git
cd lua-sha2
luarocks make
```

## Usage

```lua
local sha2 = require "sha2"

-- binary digest
local digest = sha2.sha256("Hello")

-- lowercase hex digest
print(sha2.sha256hex("And so we say goodbye to our beloved pet, Nibbler, who's gone to a place where I, too, hope one day to go. The toilet."))
-- 3c4ba860b4917a85b075f5e0c8cebe65bd1646d0d5ac3326a974ae965a44a5e1
```

HMAC:

```lua
local hmac = require "hmac"
require "hmac.sha2"   -- registers hmac.sha256, hmac.sha384, hmac.sha512

print((hmac.sha256("what do ya want for nothing?", "Jefe"):gsub("(.)", function(c)
	return string.format("%02x", c:byte())
end)))
-- 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843
```

HMAC-MD5 (optional, needs the `md5` rock):

```lua
require "hmac.md5"    -- registers hmac.md5

print((hmac.md5("what do ya want for nothing?", "Jefe"):gsub("(.)", function(c)
	return string.format("%02x", c:byte())
end)))
-- 750c783e6ab0b503eaa86e310a5db738
```

## API

### `require "sha2"`

| Function | Description |
|---|---|
| `sha2.sha256(message)` | SHA-256 digest as a 32-byte binary string |
| `sha2.sha384(message)` | SHA-384 digest as a 48-byte binary string |
| `sha2.sha512(message)` | SHA-512 digest as a 64-byte binary string |
| `sha2.sha256hex(message)` | SHA-256 digest as a 64-char lowercase hex string |
| `sha2.sha384hex(message)` | SHA-384 digest as a 96-char lowercase hex string |
| `sha2.sha512hex(message)` | SHA-512 digest as a 128-char lowercase hex string |
| `sha2.exor(a, b)` | bytewise XOR of two equal-length binary strings |
| `sha2._VERSION` | module version string |

### `require "hmac"`

| Function | Description |
|---|---|
| `hmac.compute(key, message, hash_fn, block_size[, opad][, ipad])` | generic HMAC; returns `mac, opad, ipad` (`opad`/`ipad` can be cached per key) |
| `hmac.new(hash_fn, block_size)` | returns `function(message, key)` bound to one hash function |

After loading an algorithm variant:

```lua
require "hmac.sha2"   -- hmac.sha256(message, key), hmac.sha384(message, key), hmac.sha512(message, key)
require "hmac.md5"    -- hmac.md5(message, key); needs the md5 rock
```

All MAC functions return binary strings; wrap them in your own hex/base64
encoding if needed.

## Testing

The repository bundles NIST-style test vectors (`testvectors/`) and RFC test
cases (RFC 4231, RFC 2202). Run either way:

```sh
lua run_tests.lua    # runs both suites
# or
luarocks test
```

Individual suites: `lua test_sha2.lua` and `lua test_hmac.lua`
(the latter skips the MD5 part when the `md5` rock is not installed).

CI runs the full matrix on every push across Linux, Lua 5.1–5.5,
LuaJIT and OpenResty's LuaJIT — see [.github/workflows/ci.yml](.github/workflows/ci.yml).

## History & credits

This project was originally published in 2010 on
[Google Code](https://code.google.com/archive/p/sha2/) by Cosmin Apreutesei,
who holds the copyright of the Lua binding (MIT licensed, see
[LICENSE.txt](LICENSE.txt)). This repository continues maintenance of the
formerly orphaned project — compatibility with modern Lua versions,
cleaned-up build and CI — and remains credited to the original author.

The SHA-2 C core is by Aaron D. Gifford,
BSD-style licensed (see the headers of [`sha2.c`](sha2.c) / [`sha2.h`](sha2.h)).
