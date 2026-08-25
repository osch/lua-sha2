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

local npass, nfail = 0, 0

local function check(name, got, want)
	if got == want then
		npass = npass + 1
	else
		nfail = nfail + 1
		print(('%s: FAIL (%s ~= %s)'):format(name, got, want))
	end
end

local function main()
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
