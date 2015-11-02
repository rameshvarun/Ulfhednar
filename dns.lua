-- Pure Lua DNS parsing / printing / serialization.
-- Taken from https://gist.github.com/zeen/2340121
local t_insert,t_concat = table.insert,table.concat;
local s_char = string.char;
local pairs,ipairs = pairs,ipairs;
local type = type;
local tostring,tonumber = tostring,tonumber;

-- DNS Parser
-- The following is a parser for the DNS format defined in RFC1035

-- starts reading DNS labels from packet, starting from index pos,
-- and following pointers.
-- returns ("example.com.", nextIndex) on success, or nil on failure
function readDnsName(packet, pos)
	local endpos;
	local pointers = 0;
	local labels = {};
	while pointers < 20 do
		if #packet < pos then return; end
		local len = packet:byte(pos);
		pos = pos + 1;
		if len == 0 then -- done
			if not endpos then endpos = pos; end
			if #labels == 0 then return ".", endpos; end -- for when the name is just "."
			t_insert(labels, ""); -- for the final '.'
			return t_concat(labels, "."), endpos;
		elseif len < 64 then -- normal label
			if #packet >= pos + len then
				t_insert(labels, packet:sub(pos, pos+len-1));
				pos = pos+len;
			else
				return; -- trunctated label
			end
		elseif len-len%64 == 192 then -- upper two bits set, i.e., a pointer, see RFC1035#4.1.4
			if #packet < pos then return; end
			if not endpos then endpos = pos+1; end
			pos = (len-192)*256+packet:byte(pos)+1;
			pointers = pointers + 1;
		else -- upper two bits are either 01 or 10, which we don't understand
			return; -- we don't understand this
		end
	end
	return; -- too many pointer redirects
end

local recordTypes = {
	'A', 'NS', 'MD', 'MF', 'CNAME', 'SOA', 'MB', 'MG', 'MR', 'NULL', 'WKS',
	'PTR', 'HINFO', 'MINFO', 'MX', 'TXT',
	[ 28] = 'AAAA', [ 29] = 'LOC',   [ 33] = 'SRV',
	[252] = 'AXFR', [253] = 'MAILB', [254] = 'MAILA', [255] = '*'
};
local recordClasses = { 'IN', 'CS', 'CH', 'HS', [255] = '*' };
local toTypeNumber, toTypeString = {}, {};
local toClassNumber, toClassString = {}, {};
for n,s in pairs(recordTypes) do
	toTypeNumber[n],toTypeNumber[s],toTypeNumber[s:lower()] = n,n,n;
	toTypeString[n],toTypeString[s],toTypeString[s:lower()] = s,s,s;
end
for n,s in pairs(recordClasses) do
	toClassNumber[n],toClassNumber[s],toClassNumber[s:lower()] = n,n,n;
	toClassString[n],toClassString[s],toClassString[s:lower()] = s,s,s;
end

local parsers = {};

function parsers.A(packet, pos, rr)
	if rr.rdlength == 4 then
		local b1, b2, b3, b4 = packet:byte(pos, pos+3);
		rr.a = b1.."."..b2.."."..b3.."."..b4;
		return pos+4;
	end
end
function parsers.AAAA(packet, pos, rr)
	if rr.rdlength == 16 then
		local t = { packet:byte(pos, pos+15) };
		for i=1,8 do
			t[i] = ("%x"):format(t[i*2-1]*256+t[i*2]); -- skips leading zeros
		end
		local ip = t_concat(t, ":", 1, 8);
		local len = #ip:match("^[0:]*");
		local token;
		for s in ip:gmatch(":[0:]+") do
			if len < #s then len,token = #s,s; end -- find longest sequence of zeros
		end
		rr.aaaa = ip:gsub(token or "^[0:]+", "::", 1);
		return pos+16;
	end
end
function parsers.CNAME(packet, pos, rr)
	local cname,newpos = readDnsName(packet, pos);
	if cname and pos + rr.rdlength == newpos then
		rr.cname = cname;
		return newpos;
	end
end
function parsers.MX(packet, pos, rr)
	local name,newpos = readDnsName(packet, pos+2);
	if name and pos + rr.rdlength == newpos then
		local b1,b2 = packet:byte(pos, pos+1);
		rr.pref = b1*256+b2;
		rr.mx = name;
		return newpos;
	end
end
--function parsers.LOC(packet, pos, rr)
function parsers.NS(packet, pos, rr)
	local name,newpos = readDnsName(packet, pos);
	if name and pos + rr.rdlength == newpos then
		rr.ns = name;
		return newpos;
	end
end
--function parsers.SOA(packet, pos, rr)
function parsers.SRV(packet, pos, rr)
	local name,newpos = readDnsName(packet, pos+6);
	if name and pos + rr.rdlength == newpos then
		local b1,b2,b3,b4,b5,b6 = packet:byte(pos, pos+5);
		rr.srv = {
			priority = b1*256+b2;
			weight   = b3*256+b4;
			port     = b5*256+b6;
			target   = name;
		};
		return newpos;
	end
end
function parsers.PTR(packet, pos, rr)
	local name,newpos = readDnsName(packet, pos);
	if name and pos + rr.rdlength == newpos then
		rr.ptr = name;
		return newpos;
	end
end
function parsers.TXT(packet, pos, rr)
	local len = rr.rdlength;
	if len > 0 and packet:byte(pos) == len-1 then
		rr.txt = packet:sub(pos+1, pos+len);
		return pos+len+1;
	end
end

function readDnsResourceRecord(packet, pos)
	local name;
	name, pos = readDnsName(packet, pos);
	if not name then return; end

	if pos+9 > #packet then return; end
	local b1,b2,b3,b4,b5,b6,b7,b8,b9,b10 = packet:byte(pos, pos+9);
	local rdlength = b9*256+b10;
	pos = pos+10;
	
	if pos+rdlength-1 > #packet then return; end
	local rr = {
		name     = name;
		type     = b1*256+b2;
		class    = b3*256+b4;
		ttl      = b5*16777216+b6*65536+b7*256+b8;
		rdlength = rdlength;
		rdata    = packet:sub(pos, pos+rdlength);
	};
	local parser = parsers[recordTypes[rr.type]];
	rr.type  = toTypeString [rr.type ] or rr.type ;
	rr.class = toClassString[rr.class] or rr.class;
	if not parser then return rr, pos; end
	local newpos = parser(packet, pos, rr);
	if newpos == pos+rdlength then
		return rr, newpos;
	end
end

function readDnsResourceRecordArray(packet, pos, count, rrs)
	for i=#rrs+1,count do
		local rr;
		rr, pos = readDnsResourceRecord(packet, pos);
		if not rr then return #packet+1; end
		rrs[i] = rr;
	end
	return pos;
end

function parseDnsPacket(packet)
	-- parse header
	if #packet < 12 then return; end
	local b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12 = packet:byte(1,12);

	local header = {
		id      = b1 *256 + b2;

		-- (b%upper - b%lower)/lower
		qr      = (b3%256 - b3%128)/128; -- X000 0000
		opcode  = (b3%128 - b3%  8)/  8; -- 0XXX X000
		aa      = (b3%  8 - b3%  4)/  4; -- 0000 0X00
		tc      = (b3%  4 - b3%  2)/  2; -- 0000 00X0
		rd      = (b3%  2 - b3%  1)/  1; -- 0000 000X

		ra      = (b4%256 - b4%128)/128; -- X000 0000
		z       = (b4%128 - b4% 16)/ 16; -- 0XXX 0000
		rcode   = (b4% 16 - b4%  1)/  1; -- 0000 XXXX

		qdcount = b5 *256 + b6;
		ancount = b7 *256 + b8;
		nscount = b9 *256 + b10;
		arcount = b11*256 + b12;
	};

	local pos = 13;
	local question = {};
	for i=1,header.qdcount do
		-- q = qname,qtype,qclass
		local qname;
		qname, pos = readDnsName(packet, pos);
		if not qname then return; end

		if #packet < pos+3 then return; end
		local b1,b2,b3,b4 = packet:byte(pos, pos+3);
		local qtype  = b1*256 + b2;
		local qclass = b3*256 + b4;
		pos = pos+4;

		question[i] = { name = qname, type = toTypeString[qtype] or qtype, class = toClassString[qclass] or qclass };
	end

	local answer, authority, additional = {}, {}, {};
	pos = readDnsResourceRecordArray(packet, pos, header.ancount, answer);
	pos = readDnsResourceRecordArray(packet, pos, header.nscount, authority);
	pos = readDnsResourceRecordArray(packet, pos, header.arcount, additional);

	local recordCount = #answer + #authority + #additional;
	local expectedRecords = header.ancount + header.nscount + header.arcount;
	if expectedRecords < recordCount and header.tc == 0 then return; end -- unexpected truncation
	if expectedRecords == recordCount and header.tc == 1 then return; end -- expected truncation

	local response = {
		header = header;
		question = question;
		answer = answer;
		authority = authority;
		additional = additional;
	};
	return response;
end

-- End of DNS Parser

-- DNS encoding routines

local function _fixBit(value, default)
	if value == nil then return default; end
	if value and value ~= 0 then return 1; end
	return 0;
end
function encodeHeader(packet, qdcount, ancount, nscount, arcount)
	local header = packet.header;
	local id = header.id;
	local b2 = id%256;
	local b1 = (id-b2)/256;

	--local qdcount = (packet.question   and #packet.question   or 0);
	--local ancount = (packet.answer     and #packet.answer     or 0);
	--local nscount = (packet.authority  and #packet.authority  or 0);
	--local arcount = (packet.additional and #packet.additional or 0);
	local b6  = qdcount%256;
	local b5  = (qdcount-b6)/256;
	local b8  = ancount%256;
	local b7  = (ancount-b8)/256;
	local b10 = nscount%256;
	local b9  = (nscount-b10)/256;
	local b12 = arcount%256;
	local b11 = (arcount-b12)/256;

	local qr = _fixBit(header.qr, (ancount+nscount+arcount == 0 and 0 or 1)); --  1b    0 query, 1 response
	local opcode = header.opcode or 0;
	local aa = _fixBit(header.aa, 0); --  1b    1 authoritative response
	local tc = _fixBit(header.tc, 0); --  1b    1 truncated response
	tc = 0; -- disable truncation bit in encoding, this happens later
	local rd = _fixBit(header.rd, 1); --  1b    1 recursion desired
	local b3 = rd + 2*tc + 4*aa + 8*opcode + 128*qr;

	local ra = _fixBit(header.ra, 0); --	1b  1 recursion available
	local z = header.z or 0;          --	3b  0 resvered
	local rcode = header.rcode or 0;  --	4b  0 no error
									  --	1 format error
									  --	2 server failure
									  --	3 name error
									  --	4 not implemented
									  --	5 refused
									  --	6-15 reserved
	local b4 = rcode + 16*z + 128*ra;

	return s_char( b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12 );
end
local function _append(buffer, data)
	buffer.n = buffer.n + #data;
	return t_insert(buffer, data);
end
function encodeName(buffer, name)
	local t = {};
	for label in name:gmatch("[^.]+") do
		t_insert(t, s_char(#label)..label);
	end
	t_insert(t, s_char(0));
	if buffer.pointers then -- compression enabled?
		for i=1,#t do -- for each substring the name ends in
			local subst = t_concat(t, "", i, #t);
			local pointer = buffer.pointers[subst];
			if pointer then
				return _append(buffer, pointer);
			elseif #subst > 2 then
				local index = buffer.n;
				buffer.pointers[subst] = s_char(192+(index-index%256)/256, index%256);
				_append(buffer, t[i]);
			else
				return _append(buffer, subst);
			end
		end
	else
		return _append(buffer, t_concat(t));
	end
end
function encodeQuestion(buffer, question)
	if question.name then
		encodeName(buffer, question.name);
		local qtype  = toTypeNumber [question.qtype ] or toTypeNumber ['A' ];
		local qclass = toClassNumber[question.qclass] or toClassNumber['IN'];
		_append(buffer, s_char((qtype-qtype%256)/256, qtype%256, (qclass-qclass%256)/256, qclass%256))
		return true;
	end
end
function encodeResourceRecord(buffer, rr)
	local name  = rr.name;
	local type  = toTypeNumber [rr.type ] or toTypeNumber ['A' ];
	local class = toClassNumber[rr.class] or toClassNumber['IN'];
	local ttl = rr.ttl or 0;
	local rdata1, rdata2;
	
	local t = toTypeString[type];
	if t == 'A' and rr.a then
		rdata1 = s_char(rr.a:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$"));
		if #rdata1 ~= 4 then return; end
	elseif t == 'AAAA' and rr.aaaa then
		local aaaa,n = rr.aaaa:gsub("%x+", function(s) return ("%04x"):format(s); end);
		if aaaa:find("%.") and aaaa:find("%d+%.%d+%.%d+%.%d+$") then -- IPv4 style IP at the end
			local ip4 = aaaa:gsub("%d+%.%d+%.%d+%.%d+$");
			aaaa:gsub("%d+%.%d+%.%d+%.%d+$", ("%02x%02x:%02x%02x"):format(aaaa:match("(%d+)%.(%d+)%.(%d+)%.(%d+)$")))
		end
		aaaa = aaaa:gsub("::", ("00"):rep(16-n));
		rdata1 = aaaa:gsub(":", ""):gsub("%x%x", function(s) return s_char(tonumber(s, 16)); end)
		if #rdata1 ~= 16 then return; end
	elseif t == 'CNAME' and rr.cname then
		rdata2 = rr.cname;
	elseif t == 'MX' and rr.pref and rr.mx then
		rdata1, rdata2 = s_char( (rr.pref-rr.pref%256)/256, rr.pref%256 ), rr.mx;
	elseif t == 'NS' and rr.ns then
		rdata2 = rr.ns;
	elseif t == 'SRV' and rr.srv and rr.srv.port and rr.srv.name then
		local priority = rr.srv.priority or 0;
		local weight   = rr.srv.weight   or 0;
		local port     = rr.srv.port;
		rdata1, rdata2 = s_char(
			(priority-priority%256)/256, priority%256,
			(weight  -weight  %256)/256, weight  %256,
			(port    -port    %256)/256, port    %256), rr.srv.name;
	elseif t == 'PTR' and rr.ptr then
		rdata2 = rr.ptr;
	elseif t == 'TXT' and rr.txt then
		rdata1 = rr.txt;
	end

	encodeName(buffer, name);
	_append(buffer, s_char(
		(type-type%256)/256, type%256, (class-class%256)/256, class%256,
		(ttl-ttl%16777216)/16777216, (ttl-ttl%65536)/65536, (ttl-ttl%256)/256, ttl%256
	));
	_append(buffer, "##"); -- dummy rdlength
	local n,i = buffer.n,#buffer;
	if rdata1 then
		_append(buffer, rdata1);
	end
	if rdata2 then
		encodeName(buffer, rdata2);
	end
	local rdlength = buffer.n - n;
	buffer[i] = s_char((rdlength-rdlength%256)/256, rdlength%256);
	return true;
end
local function _encodeRecords(buffer, encoder, records)
	local n = 0;
	if records then
		for i,v in ipairs(records) do
			if encoder(buffer, v) then
				n = n + 1;
			end
		end
	end
	return n;
end
function encodeDnsPacket(packet, compress)
	local buffer = { "\0\0\0\0\0\0\0\0\0\0\0\0", n=12, pointers=compress and {} };
	local qdcount = _encodeRecords(buffer, encodeQuestion,       packet.question  );
	local ancount = _encodeRecords(buffer, encodeResourceRecord, packet.answer    );
	local nscount = _encodeRecords(buffer, encodeResourceRecord, packet.authority );
	local arcount = _encodeRecords(buffer, encodeResourceRecord, packet.additional);
	buffer[1] = encodeHeader(packet, qdcount, ancount, nscount, arcount);
	return t_concat(buffer);
end
function truncateDnsPacket(packet)
	if #packet > 512 then
		packet = packet:sub(1,512);
		local b3 = packet:byte(3) + 2; -- enable the truncation bit
		packet = packet:sub(1,2)..s_char(b3)..packet:sub(4,512);
	end
	return packet;
end

-- End of DNS encoding routines

-- DNS dumping routines
local function dumpResourceRecord(rr)
	local s;
	local t = toTypeString[rr.type] or ("("..rr.type..")");
	if t == "MX" then
		s = ("%2i %s"):format(rr.pref, rr.mx);
	elseif t == "SRV" then
		local srv = rr.srv;
		s = ("%5d %5d %5d %s"):format(srv.priority, srv.weight, srv.port, srv.target);
	else
		s = rr[t:lower()];
		if type(s) ~= "string" then s = "<UNKNOWN RDATA TYPE>"; end
	end
	return ("%2s %-5s %6i %-28s %s"):format(toClassString[rr.class] or ("("..rr.class..")"), t, rr.ttl, rr.name, s);
end
local function dumpResourceRecordArray(rrs, indent)
	indent = indent or "";
	local t = {};
	for i,rr in ipairs(rrs) do
		t_insert(t, dumpResourceRecord(rr));
	end
	return indent..t_concat(t, "\n"..indent);
end
local function dumpDnsQuestion(question)
	local t = toTypeString [question.type ] or ("("..question.type ..")");
	local c = toClassString[question.class] or ("("..question.class..")");
	return question.name.." "..t.." "..c;
end
local function dumpDnsHeader(header)
	local keys = "id, qr, opcode, aa, tc, rd, ra, rcode, qdcount, ancount, nscount, arcount";
	return (keys:gsub("%w+", function(k) return k:upper().."="..tostring(header[k]); end));
end
function dumpDnsPacket(packet)
	if type(packet) == "string" then
		packet = parseDnsPacket(packet);
		if not packet then return "<INVALID DNS PACKET>"; end
	end
	--local s = {};
	local s = "DNSPacket {\n\theaders = {\n\t\t"..dumpDnsHeader(packet.header):gsub(" QD","\n\t\tQD").."\n\t}\n";
	s = s.."\tQuestion {\n";
	for i,v in ipairs(packet.question) do
		s = s.."\t\t"..dumpDnsQuestion(v).."\n"
	end
	if #packet.answer > 0 then
		s = s.."\t}\n\tAnswer = {\n\t\t";
		s = s..dumpResourceRecordArray(packet.answer):gsub("\n","\n\t\t").."\n";
	end
	if #packet.authority > 0 then
		s = s.."\t}\n\tAuthority = {\n\t\t";
		s = s..dumpResourceRecordArray(packet.authority):gsub("\n","\n\t\t").."\n";
	end
	if #packet.additional > 0 then
		s = s.."\t}\n\tAdditional = {\n\t\t";
		s = s..dumpResourceRecordArray(packet.additional):gsub("\n","\n\t\t").."\n";
	end
	s = s.."\t}\n";
	s = s.."}";
	return s
end

return {
	parse = parseDnsPacket,
	encode = encodeDnsPacket,
	dump = dumpDnsPacket
}