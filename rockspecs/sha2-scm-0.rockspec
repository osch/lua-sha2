package = "sha2"
version = "scm-0"
rockspec_format = "3.0"
source = {
  url = "https://github.com/osch/lua-sha2/archive/master.zip",
  dir = "lua-sha2-master",
}
description = {
  summary = "SHA-256/384/512 hashing for Lua (one-shot and streaming), plus HMAC",
  homepage = "https://github.com/osch/lua-sha2",
  license = "MIT",
  detailed = [[
      Lua binding for the SHA-2 (SHA-256/384/512) C implementation
      by Aaron Gifford. Provides binary and lowercase hex digests,
      one-shot or through streaming digest objects (add/digest/
      hexdigest/reset/clone), for Lua strings and, optionally,
      carray objects (read without copying), and a generic HMAC
      implementation with ready-made HMAC-SHA256/384/512 variants
      (HMAC-MD5 via the md5 rock).
      Works with Lua 5.1 up to 5.5 and LuaJIT.
  ]],
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    sha2 = {
      sources = { "sha2.c", "sha2lib.c" },
      incdirs = { "." },
      defines = { "SHA2_VERSION="..version:gsub("^(.*)-.-$", "%1") },
    },
    hmac = "hmac.lua",
    ["hmac.sha2"] = "hmac/sha2.lua",
    ["hmac.md5"] = "hmac/md5.lua",
  },
  -- copy no directory: luarocks then installs the top-level README and
  -- LICENSE files into the rock's doc/ directory
  copy_directories = {},
}
test = {
  type = "command",
  command = "lua",
  flags = { "run_tests.lua" },
}
