local socket = require("socket")
local dns = require("dns")
local serpent = require("libraries.serpent")

-- Service name
local SERVICE_NAME = "_ulfhednar._udp.local."

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

function shouldRespond(packet)

	if packet.header.qr ~= 0 then return false end

	-- Multicast DNS messages received with an OPCODE other than zero MUST be silently ignored.
	if packet.header.opcode ~= 0 then return false end

	-- Multicast DNS messages received with non-zero Response Codes MUST be silently ignored.
	if packet.header.rcode ~= 0 then return false end

	for _,query in ipairs(packet.question) do
		if query.name == SERVICE_NAME then
			return true
		end
	end
	return false
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local hostname = socket.dns.gethostname()
while true do
	local data, sender_ip, sender_port = udp:receivefrom()
	local packet = dns.parse(data)
	if packet ~= nil then
		if shouldRespond(packet) then
			print("Responding to mDNS query...")
			print(dns.dump(packet))

			print(print(serpent.block(packet)))

			local response = deepcopy(packet)
			response.header.qr = 1
			response.header.opcode = 0
			response.header.aa = 1

			response.answer = {{
				class = "IN",
				type = "PTR",
				name = SERVICE_NAME,
				ptr = hostname .. '.' .. SERVICE_NAME,
				ttl = 4500,
			}, {
				class = "IN",
				type = "A",
				ttl = 4500,
				a = "128.12.67.89",
				name = SERVICE_NAME
			}}

			local out = "\0\0\132\0" .. dns.encode(response, true):sub(5)
			print(dns.dump(out))

			udp:sendto(out, ipv4Addr, port)
		end
	else
		print("Failed to parse an mDNS packet...")
	end
end
