--[[
	Test suite for the sha2 module using the bundled test vectors.
	Usage: lua test_sha2.lua
]]

local sha2 = require 'sha2'

print(sha2._VERSION)

local sha = {
	SHA256 = sha2.sha256,
	SHA384 = sha2.sha384,
	SHA512 = sha2.sha512,
}

local shahex = {
	SHA256 = sha2.sha256hex,
	SHA384 = sha2.sha384hex,
	SHA512 = sha2.sha512hex,
}

local function bintohex(s)
	return (s:gsub('(.)', function(c)
		return string.format('%02x', string.byte(c))
	end))
end

local bits = { SHA256 = 256, SHA384 = 384, SHA512 = 512 }

-- carray is optional: its tests are skipped when the module is missing,
-- unless SHA2_TEST_REQUIRE_CARRAY=1 is set (CI), which makes it an error
local has_carray, carray = pcall(require, 'carray')
if not has_carray then
	if os.getenv('SHA2_TEST_REQUIRE_CARRAY') == '1' then
		error('carray module required (SHA2_TEST_REQUIRE_CARRAY=1) but not loadable:\n' .. tostring(carray), 0)
	end
	carray = nil
end

local function tocarray(s, t)
	return carray.new(t or 'uint8'):append(s)
end

local npass, nfail = 0, 0

local function check(name, got, want)
	if got == want then
		npass = npass + 1
	else
		nfail = nfail + 1
		print(('%s: FAIL (%s ~= %s)'):format(name, got, want))
	end
end

local function check_error(name, pattern, f, ...)
	local ok, err = pcall(f, ...)
	if not ok and tostring(err):find(pattern, 1, true) then
		npass = npass + 1
	else
		nfail = nfail + 1
		print(('%s: FAIL (expected error "%s", got %s)'):format(name, pattern,
			ok and 'no error' or tostring(err)))
	end
end

-- feeds s in chunks of size n through a new digest object
local function streamed(b, s, n, hex)
	local d = sha2.new(b)
	for i = 1, #s, n do
		d:add(s:sub(i, i + n - 1))
	end
	if hex then
		return d:hexdigest()
	end
	return bintohex(d:digest())
end

local function test_vector(datname, s, k, v)
	local b = bits[k]
	for _, n in ipairs({1, 7, 64, 127, 1000}) do
		check(('%s %s stream %d'):format(datname, k, n), streamed(b, s, n), v)
	end
	check(('%s %s stream hex'):format(datname, k), streamed(b, s, 1000, true), v)

	-- several arguments in one add() call
	local d = sha2.new(b)
	local h = math.floor(#s / 3)
	d:add(s:sub(1, h), s:sub(h + 1, 2 * h), '', s:sub(2 * h + 1))
	check(('%s %s add(...)'):format(datname, k), d:hexdigest(), v)

	-- clone of a half-fed object
	d:add(s:sub(1, h))
	local c = d:clone()
	c:add(s:sub(h + 1))
	d:add('different tail')
	check(('%s %s clone'):format(datname, k), c:hexdigest(), v)
	check(('%s %s clone independent'):format(datname, k), d:hexdigest(),
		shahex[k](s:sub(1, h) .. 'different tail'))

	if carray then
		local ca = tocarray(s)
		check(('%s %s carray bin'):format(datname, k), bintohex(sha[k](ca)), v)
		check(('%s %s carray hex'):format(datname, k), shahex[k](ca), v)
		check(('%s %s carray char'):format(datname, k), shahex[k](tocarray(s, 'char')), v)
		check(('%s %s carray int8'):format(datname, k), shahex[k](tocarray(s, 'int8')), v)
		local d2 = sha2.new(b)
		d2:add(tocarray(s:sub(1, h)), s:sub(h + 1, 2 * h), tocarray(s:sub(2 * h + 1)))
		check(('%s %s carray add'):format(datname, k), d2:hexdigest(), v)
	end
end

local function test_digest_object()
	for k, b in pairs(bits) do
		local empty = shahex[k]('')
		local d = sha2.new(b)
		check(k .. ' algorithm', d:algorithm(), b)
		check(k .. ' fresh', d:hexdigest(), empty)
		check(k .. ' add returns self', d:add('abc'), d)
		check(k .. ' digest', d:digest(), sha[k]('abc'))
		check(k .. ' digest resets', d:hexdigest(), empty)
		check(k .. ' add() no args', d:add(), d)
		check(k .. ' chaining', d:add('a'):add('b', 'c'):hexdigest(), shahex[k]('abc'))
		d:add('garbage')
		check(k .. ' reset returns self', d:reset(), d)
		check(k .. ' reset', d:hexdigest(), empty)
		d:add('ab')
		local c = d:clone()
		check(k .. ' clone algorithm', c:algorithm(), b)
		check(k .. ' clone is new object', c ~= d, true)
		c:reset()
		check(k .. ' clone reset leaves original', d:add('c'):hexdigest(), shahex[k]('abc'))
		check(k .. ' tostring', tostring(d):find('sha2.digest (SHA-' .. b .. ')', 1, true) == 1, true)
		check(k .. ' number data', sha2.new(b):add(12):hexdigest(), shahex[k]('12'))
		check_error(k .. ' add table', 'string expected, got table', d.add, d, {})
		check_error(k .. ' add nil', 'string expected, got nil', d.add, d, 'x', nil)
		check_error(k .. ' digest on non-object', 'sha2.digest expected', d.digest, {})
	end
	check_error('new(1)', 'bits must be 256, 384 or 512', sha2.new, 1)
	check_error('new(224)', 'bits must be 256, 384 or 512', sha2.new, 224)
	check_error('new()', 'number expected', sha2.new)
	check_error('new("x")', 'number expected', sha2.new, 'x')
	check_error('sha256(table)', 'string expected, got table', sha2.sha256, {})
end

local function test_carray()
	if not carray then
		print('carray module not available: carray tests skipped')
		return
	end
	for k, b in pairs(bits) do
		check(k .. ' empty carray', shahex[k](carray.new('uint8')), shahex[k](''))
		check(k .. ' empty carray add', sha2.new(b):add(carray.new('char')):hexdigest(), shahex[k](''))
		for _, t in ipairs({'short', 'int', 'double'}) do
			check_error(k .. ' carray ' .. t, 'carray elements must be 1 byte in size',
				sha[k], carray.new(t, 4))
			check_error(k .. ' carray hex ' .. t, 'carray elements must be 1 byte in size',
				shahex[k], carray.new(t, 4))
			local d = sha2.new(b)
			check_error(k .. ' add carray ' .. t, 'carray elements must be 1 byte in size',
				d.add, d, 'x', carray.new(t, 4))
		end
	end
end

local function test_large()
	local chunk = {}
	for i = 0, 65535 do
		chunk[#chunk + 1] = string.char((i * 7 + 3) % 256)
	end
	chunk = table.concat(chunk)
	local nchunks = 160            -- 160 * 64 KB = 10 MB
	local big = chunk:rep(nchunks)
	for k, b in pairs(bits) do
		local d = sha2.new(b)
		for _ = 1, nchunks do
			d:add(chunk)
		end
		check(k .. ' 10 MB stream', d:hexdigest(), shahex[k](big))
		if carray then
			local ca = tocarray(chunk)
			for _ = 1, nchunks do
				d:add(ca)
			end
			check(k .. ' 10 MB carray stream', d:hexdigest(), shahex[k](tocarray(big)))
		end
	end
end

local function main()
	test_digest_object()
	test_carray()
	test_large()

	check('exor', bintohex(sha2.exor('abc', 'abc')), '000000')
	check('exor', bintohex(sha2.exor('\0\255', '\15\240')), '0f0f')

	local i = 0
	while true do
		i = i + 1
		local datname = ('testvectors/vector%03d.dat'):format(i)
		local f = io.open(datname, 'rb')
		if not f then break end
		local s = f:read('*a')
		f:close()

		local hashes = {}
		do
			local g = assert(io.open(('testvectors/vector%03d.info'):format(i), 'r'))
			local name, hash
			for line in g:lines() do
				if line:find('^SHA%d+:') then
					name = line:match('^(SHA%d+)')
					hash = ''
				elseif hash then
					if #line == 0 then
						hashes[name] = hash
						hash = nil
					else
						hash = hash .. line:match('^%s*(.-)%s*$')
					end
				end
			end
			g:close()
		end

		for k,v in pairs(hashes) do
			check(('%s %s bin'):format(datname, k), bintohex(sha[k](s)), v)
			check(('%s %s hex'):format(datname, k), shahex[k](s), v)
			test_vector(datname, s, k, v)
		end
	end

	print(('%d passed, %d failed'):format(npass, nfail))
	return nfail == 0
end

local ok = main()
if type(arg) == 'table' and arg[0] and arg[0]:find('test_sha2%.lua$') then
	os.exit(ok and 0 or 1)
end
return ok
