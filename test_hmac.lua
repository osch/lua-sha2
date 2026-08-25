--[[
	Test suite for the hmac module.
	Checks HMAC-SHA256/384/512 against RFC 4231 test vectors, the
	HMAC-MD5 RFC 2202 test case (if the md5 rock is installed) and an
	AWS signature example including base64 output.

	Usage: lua test_hmac.lua
]]

local hmac = require 'hmac'
require 'hmac.sha2'

local function bintohex(s)
	return (s:gsub('(.)', function(c)
		return string.format('%02x', string.byte(c))
	end))
end

local function hextobin(s)
	return (s:gsub('(%x%x)', function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local npass, nfail = 0, 0

local function check(name, got, want)
	if got == want then
		npass = npass + 1
	else
		nfail = nfail + 1
		print(('%s: FAIL (%s ~= %s)'):format(name, bintohex(got), bintohex(want)))
	end
end

-- base64 encoder (no luasocket dependency)
local function base64(data)
	local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	local out = {}
	for i = 1, #data, 3 do
		local a, b, c = data:byte(i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local q = {}
		q[1] = chars:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
		q[2] = chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
		q[3] = b and chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or '='
		q[4] = c and chars:sub(n % 64 + 1, n % 64 + 1) or '='
		out[#out+1] = table.concat(q)
	end
	return table.concat(out)
end

local function main()
	--per http://tools.ietf.org/html/rfc4231
	local tests = {
		{ key = (hextobin'0b'):rep(20),
			data = 'Hi There',
			hmac256 = 'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7',
			hmac384 = 'afd03944d84895626b0825f4ab46907f15f9dadbe4101ec682aa034c7cebc59cfaea9ea9076ede7f4af152e8b2fa9cb6',
			hmac512 = '87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854',
		},
		{ key = 'Jefe',
			data = 'what do ya want for nothing?',
			hmac256 = '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
			hmac384 = 'af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e8e2240ca5e69e2c78b3239ecfab21649',
			hmac512 = '164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737',
		},
		{ key = (hextobin'aa'):rep(20),
			data = (hextobin'dd'):rep(50),
			hmac256 = '773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe',
			hmac384 = '88062608d3e6ad8a0aa2ace014c8a86f0aa635d947ac9febe83ef4e55966144b2a5ab39dc13814b94e3ab6e101a34f27',
			hmac512 = 'fa73b0089d56a284efb0f0756c890be9b1b5dbdd8ee81a3655f83e33b2279d39bf3e848279a722c806b485a47e67c807b946a337bee8942674278859e13292fb',
		},
		{ key = hextobin'0102030405060708090a0b0c0d0e0f10111213141516171819',
			data = (hextobin'cd'):rep(50),
			hmac256 = '82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b',
			hmac384 = '3e8a69b7783c25851933ab6290af6ca77a9981480850009cc5577c6e1f573b4e6801dd23c4a7d679ccf8a386c674cffb',
			hmac512 = 'b0ba465637458c6990e5a8c5f61d4af7e576d97ff94b872de76f8050361ee3dba91ca5c11aa25eb4d679275cc5788063a5f19741120c4f2de2adebeb10a298dd',
		},
		{ key = (hextobin'aa'):rep(131),
			data = 'Test Using Larger Than Block-Size Key - Hash Key First',
			hmac256 = '60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54',
			hmac384 = '4ece084485813e9088d2c63a041bc5b44f9ef1012a2b588f3cd11f05033ac4c60c2ef6ab4030fe8296248df163f44952',
			hmac512 = '80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f3526b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598',
		},
		{ key = (hextobin'aa'):rep(131),
			data = 'This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.',
			hmac256 = '9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2',
			hmac384 = '6617178e941f020d351e2f254e8fd32c602420feb0b8fb9adccebb82461e99c5a678cc31e799176d3860e6110c46523e',
			hmac512 = 'e37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58',
		},
	}

	for k,t in ipairs(tests) do
		check(('rfc4231.%d sha256'):format(k), hmac.sha256(t.data, t.key), hextobin(t.hmac256))
		check(('rfc4231.%d sha384'):format(k), hmac.sha384(t.data, t.key), hextobin(t.hmac384))
		check(('rfc4231.%d sha512'):format(k), hmac.sha512(t.data, t.key), hextobin(t.hmac512))
	end

	do --per amazon aws example
		local message = 'GET\nwebservices.amazon.com\n/onca/xml\nAWSAccessKeyId=00000000000000000000&ItemId=0679722769&Operation=ItemLookup&ResponseGroup=ItemAttributes%2COffers%2CImages%2CReviews&Service=AWSECommerceService&Timestamp=2009-01-01T12%3A00%3A00Z&Version=2009-01-06'
		local mac = hextobin'35a71ef94dc0cf83a137bb484aa82cd6f74b0470448a359c05e0aa2f9c4df718'
		local key = '1234567890' --their dummy key
		local b64_mac = 'Nace+U3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg='

		check('amazon hmac256', hmac.sha256(message, key), mac)
		check('amazon base64', base64(hmac.sha256(message, key)), b64_mac)
	end

	do --optional, needs the md5 rock
		local ok, err = pcall(function()
			require 'hmac.md5'
			check('rfc2202 md5', hmac.md5('what do ya want for nothing?', 'Jefe'), hextobin'750c783e6ab0b503eaa86e310a5db738')
		end)
		if not ok then
			print('md5 tests skipped ('..tostring((err:gsub('\n.*', '')))..')')
		end
	end

	print(('%d passed, %d failed'):format(npass, nfail))
	return nfail == 0
end

local ok = main()
if type(arg) == 'table' and arg[0] and arg[0]:find('test_hmac%.lua$') then
	os.exit(ok and 0 or 1)
end
return ok

