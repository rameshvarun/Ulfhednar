local socket = require("socket")

-- Service name
local SERVICE_NAME = "_ulfhednar._udp.local"

-- mDNS constants
local ipv4Addr = '224.0.0.251'
local ipv6Addr = 'FF02::FB'
local port = 5353

local udp = assert(socket.udp())
assert(udp:setoption("reuseport", true)) -- Allow other sockets to listen on the same port.
assert(udp:setsockname("*", port)) -- Bind to port 5353 on all interfaces.
assert(udp:setoption('ip-add-membership',
	{ interface = '*', multiaddr = ipv4Addr })) -- Add this host to the mDNS multicast group.

print("Listening for mDNS queries...")

function twoByteInteger(byte1, byte2) return byte1*256 + byte2 end

function decodePacket(data)
	-- Helper function: parse DNS name field, supports pointers
    -- @param data     received datagram
    -- @param offset    offset within datagram (1-based)
    -- @return  parsed name
    -- @return  offset of first byte behind name (1-based)
    local function parse_name(data, offset)
        local n,d,l = '', '', data:byte(offset)
        while (l > 0) do
            if (l >= 192) then -- pointer
                local p = (l % 192) * 256 + data:byte(offset + 1)
                return n..d..parse_name(data, p + 1), offset + 2
            end
            n = n..d..data:sub(offset + 1, offset + l)
            offset = offset + l + 1
            l = data:byte(offset)
            d = '.'
        end
        return n, offset + 1
    end

	assert(data:byte(1) == 0)
	assert(data:byte(2) == 0)

	local isQuery = data:byte(3) == 0
	assert(data:byte(4) == 0)

	local qdCount = twoByteInteger(data:byte(5), data:byte(6))
	local anCount = twoByteInteger(data:byte(7), data:byte(8))
	local nsCount = twoByteInteger(data:byte(9), data:byte(10))
	local arCount = twoByteInteger(data:byte(11), data:byte(12))
	
	local offset = 13

	local queries = {}
	for i=1, qdCount do
		if offset > data:len() then error("Truncated packet.") end
		local name, offset = parse_name(data, offset)
		local type = twoByteInteger(data:byte(offset), data:byte(offset + 1))
		local class = twoByteInteger(data:byte(offset+ 2), data:byte(offset + 3))
		offset = offset + 4

		table.insert(queries, {
			name = name,
			type = type,
			class = class,
		})
	end

	return {
		isQuery = isQuery,
		header = {
			qdCount = qdCount,
			anCount = anCount,
			nsCount = nsCount,
			arCount = arCount,
		},
		queries = queries,
	}
end

function createReply()
	local data = "\0\0" -- ID
	data = data .. "\132\0" --Flags
	data = data .. "\0\0" -- QDCOUNT
	data = data .. "\0\0" -- ANCOUNT
	data = data .. "\0\0" -- NSCOUNT
	data = data .. "\0\0" -- ARCOUNT

	return data
end

while true do
	local data, sender_ip, sender_port = udp:receivefrom()
	local status, result = pcall(decodePacket, data)
	if status then
		if result.isQuery then
			local isDiscovery = false
			for _, query in ipairs(result.queries) do
				if query.name == SERVICE_NAME then
					isDiscovery = true
				end
			end

			if isDiscovery then
				print("Sending response.")
				local data = createReply()
				udp:sendto(data, sender_ip, sender_port)
			end
		end
	else
		print("Failed to decode packet: " .. result)
	end
end