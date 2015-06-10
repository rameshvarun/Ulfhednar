local lume = require "libraries.lume"
local channel = love.thread.getChannel('remotes')

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

REMOTES = {}
function runServer()
	DISCOVERY_MESSAGE = "ULFHEDNAR_REMOTE_DISCOVERY"
	ANNOUNCE_MESSAGE = "ULFHEDNAR_REMOTE_ANNOUNCE"
	SERVER_PORT = 3779

	local socket = require("socket")

	print("Initializing UDP socket...")
	udp = socket.udp()
	udp:setsockname('*', SERVER_PORT)

	local ip = assert(socket.dns.toip(socket.dns.gethostname()))
	local _, port = udp:getsockname()
	print(ip .. ":" .. port)

	print("Listing for packets...")

	while true do
		local data, sender_ip, sender_port = udp:receivefrom()
		if data then
			if data == DISCOVERY_MESSAGE then
				print("Recieved discovery message from " .. sender_ip .. ":" .. sender_port)
				udp:sendto(ANNOUNCE_MESSAGE, sender_ip, sender_port)
			else
				words = data:split(":")
				if #words == 5 then
					REMOTES[tonumber(words[1])] = {
						x = tonumber(words[2]),
						y = tonumber(words[3]),
						attack = words[4] == "true",
						special = words[5] == "true",
						last_updated = os.time()
					}
					channel:push( lume.serialize(REMOTES) )
				end
			end
		end
	end

	print("Remote server shutting down ...")
end

local status, err = pcall(runServer)
if err then
	print("Remote server crashed...")
	print(err)
end