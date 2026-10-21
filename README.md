# sha2 — SHA-2 hashing for Lua

[![Tests](https://github.com/osch/lua-sha2/actions/workflows/ci.yml/badge.svg)](https://github.com/osch/lua-sha2/actions/workflows/ci.yml)
[![LuaRocks](https://img.shields.io/luarocks/v/osch/sha2?logo=lua&color=blue)](https://luarocks.org/modules/osch/sha2)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.txt)

Lua binding for Aaron D. Gifford's BSD-licensed [SHA-2](https://en.wikipedia.org/wiki/SHA-2)
C implementation. Provides SHA-256, SHA-384 and SHA-512 digests as binary strings or
lowercase hex strings, in one call or through streaming digest objects, plus a generic
[HMAC](https://tools.ietf.org/html/rfc2104) implementation. Data may be Lua strings or
[carray](https://github.com/osch/lua-carray) objects.

Works with **Lua 5.1, 5.2, 5.3, 5.4, 5.5** and **LuaJIT**.

## Features

* `sha256`, `sha384`, `sha512` — binary digests
* `sha256hex`, `sha384hex`, `sha512hex` — lowercase hex digests
* `sha2.new(bits)` — streaming digest objects (`add`, `digest`, `hexdigest`,
  `reset`, `clone`), modelled on Perl's `Digest::SHA` object interface
* Optional [carray](https://github.com/osch/lua-carray) support: byte carrays are
  hashed directly from their buffer, without copying
* `exor` — bytewise XOR helper for two equal-length binary strings
* Generic HMAC (`hmac.compute`, `hmac.new`) plus ready-made
  HMAC-SHA256/384/512 and HMAC-MD5 (MD5 via the [`md5`](https://luarocks.org/modules/tomasguisasola/md5) rock)
* No runtime dependencies beyond Lua itself (carray is recognized when present,
  but neither linked nor required)

## Installation

```sh
luarocks install --server=https://luarocks.org/manifests/osch sha2
```

The `--server` option matters: on luarocks.org the plain name `sha2` currently
also matches an older upload of the original 2010 code (`luarocks/sha2`
0.2.0, without digest objects and carray support), which a plain
`luarocks install sha2` may pick instead. Rocks that depend on this module
should require `sha2 >= 0.3.0`.

The development version can be installed directly from its rockspec:

```sh
luarocks install https://luarocks.org/manifests/osch/sha2-scm-0.rockspec
```

Or from a git checkout:

```sh
git clone https://github.com/osch/lua-sha2.git
cd lua-sha2
luarocks make rockspecs/sha2-scm-0.rockspec
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

Streaming, for data that arrives in pieces:

```lua
local d = sha2.new(256)              -- 256, 384 or 512
d:add("Hello, "):add("wor", "ld")    -- add() takes several arguments and returns d
local copy = d:clone()               -- independent copy of the current state
print(d:hexdigest())                 -- same as sha2.sha256hex("Hello, world"); d is reset
copy:add("!")
print(copy:hexdigest())              -- same as sha2.sha256hex("Hello, world!")

-- hashing a file in 64 KB chunks
local f = assert(io.open("big.iso", "rb"))
local d512 = sha2.new(512)
for chunk in function() return f:read(65536) end do
	d512:add(chunk)
end
f:close()
print(d512:hexdigest())
```

carray objects (optional, needs the `carray` rock):

```lua
local carray = require "carray"
local buf = carray.new("uint8"):append("Hello")
assert(sha2.sha256(buf) == sha2.sha256("Hello"))   -- read in place, no string copy
sha2.new(256):add(buf, " ", buf)                   -- strings and carrays can be mixed
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
| `sha2.sha256(data)` | SHA-256 digest as a 32-byte binary string |
| `sha2.sha384(data)` | SHA-384 digest as a 48-byte binary string |
| `sha2.sha512(data)` | SHA-512 digest as a 64-byte binary string |
| `sha2.sha256hex(data)` | SHA-256 digest as a 64-char lowercase hex string |
| `sha2.sha384hex(data)` | SHA-384 digest as a 96-char lowercase hex string |
| `sha2.sha512hex(data)` | SHA-512 digest as a 128-char lowercase hex string |
| `sha2.new(bits)` | new digest object in its initial state; `bits` is 256, 384 or 512 (anything else raises an error) |
| `sha2.exor(a, b)` | bytewise XOR of two equal-length binary strings |
| `sha2._VERSION` | module version string |

Digest object methods:

| Method | Description |
|---|---|
| `d:add(data, ...)` | feeds the arguments in order; returns `d`, so calls can be chained |
| `d:digest()` | binary digest of everything added so far; **resets** `d` to the initial state |
| `d:hexdigest()` | the same as lowercase hex string; also resets `d` |
| `d:reset()` | back to the initial state; returns `d` |
| `d:clone()` | independent copy of `d` with its current state |
| `d:algorithm()` | 256, 384 or 512 |

`digest()`/`hexdigest()` reset the object like Perl's `Digest::SHA`: to get an
intermediate digest and keep adding, call `d:clone():digest()`. `tostring(d)`
gives `sha2.digest (SHA-256): 0x...`. The hash state lives inside the userdata;
the module has no global mutable state and can be used from several Lua states
in parallel.

Every *data* argument (of the one-shot functions and of `add`) is

* a Lua string (or a number, converted as by the string library), or
* a [carray](https://github.com/osch/lua-carray) with elements of 1 byte size
  (element types `char`, `uchar`, `schar`, `int8`, `uint8`; read-only carrays are
  accepted). It is read directly from its buffer, without copying. Other element
  types raise the error `carray elements must be 1 byte in size`.

carray objects are recognized through the
[Carray C API](https://github.com/lua-capis/lua-carray-capi): sha2 neither links
against the carray module nor requires it. Without it, a non-string argument
raises the usual `string expected` error.

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
luarocks test rockspecs/sha2-scm-0.rockspec
```

Individual suites: `lua test_sha2.lua` and `lua test_hmac.lua`
(the former skips its carray tests when the `carray` rock is not installed,
the latter skips the MD5 part when the `md5` rock is not installed).
With `SHA2_TEST_REQUIRE_CARRAY=1` a missing or unloadable `carray` module is
an error instead; CI sets it, so the carray tests always run there.

CI runs on every push: Lua 5.1–5.5, LuaJIT and OpenResty's LuaJIT on Linux,
plus Lua 5.5 on macOS and on Windows (MSVC and MinGW gcc) and a strict-warnings build — see [.github/workflows/ci.yml](.github/workflows/ci.yml).

## History & credits

This project was originally published in 2010 on
[Google Code](https://code.google.com/archive/p/sha2/) by Cosmin Apreutesei,
who holds the copyright of the Lua binding (MIT licensed, see
[LICENSE.txt](LICENSE.txt)). This repository continues maintenance of the
formerly orphaned project and remains credited to the original author:
compatibility with Lua 5.1–5.5 and LuaJIT, a cleaned-up build and CI, and,
since 0.3.0, streaming digest objects and carray support.

The SHA-2 C core is by Aaron D. Gifford,
BSD-style licensed (see the headers of [`sha2.c`](sha2.c) / [`sha2.h`](sha2.h)).

[`carray_capi.h`](carray_capi.h) is copied unchanged from the
[Carray C API](https://github.com/lua-capis/lua-carray-capi) (header of the
[lua-carray](https://github.com/osch/lua-carray) module), MIT licensed.
