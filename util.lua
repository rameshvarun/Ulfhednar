--[[ Utility function to get a reference to an image.
This prevents calling love.graphics.newImage many times,
as image data does not have to be re-loaded for each entity.
This saves both time and memory ]]--
images = {}
function getImage(image_file)
	if images[image_file] == nil then
		images[image_file] = love.graphics.newImage( image_file )
		images[image_file]:setFilter("nearest", "nearest")
	end
	
	return images[image_file]
end

-- Returns the angle between two points.
function math.getAngle(x1,y1, x2,y2) return math.atan2(x2-x1, y2-y1) end

--Returns the sign of the number
function math.sign(number)
	if number > 0 then return 1 else return -1 end
end

-- Trim whitespace from both ends of the string
function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

--generates a random 10 character string composed of any thing in local characters
function generateID()
	local characters = "_abcdefghijklmnop1234567890ABCDEFGHIJKLMNOP"
	local id_length = 10
	
	local id = ""
	
	for i = 1, id_length do
		local random_loc = math.random(1, characters:len() )
		id = id .. characters:sub( random_loc, random_loc )
	end
	
	return id
end

--Splits a string given some delimiter
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return math.sqrt((x2-x1)^2+(y2-y1)^2) end

function math.norm(x, y) return math.sqrt( x^2 + y^2 ) end

-- Returns the angle between two points.
function math.getAngle(x1,y1, x2,y2) return math.atan2(x2-x1, y2-y1) end

--Clamps number n between two values
function math.clamp(number, low, high)
	return math.max( math.min(number, high), low )
end

-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function checkIntersect(l1p1, l1p2, l2p1, l2p2)
    local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
    return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

--A little helper function from the xml parser's documentation that finds the text data stored within an element
function elementText(el)
  local pieces = {}
  for _,n in ipairs(el.kids) do
    if n.type=='element' then pieces[#pieces+1] = elementText(n)
    elseif n.type=='text' then pieces[#pieces+1] = n.value
    end
  end
  return table.concat(pieces)
end

--Takes an angle and returns the direction in words
function angletodirection(movex, movey, direction)
	if math.abs(movex) > 0 or math.abs(movey) > 0 then
		moveangle = math.getAngle(0, 0, movex, movey)
		
		if moveangle > 2.355 then
			direction = "up"
		elseif moveangle > 0.785 then
			direction = "right"
		elseif moveangle > -0.785 then
			direction = "down"
		elseif moveangle > -2.355 then
			direction = "left"
		else
			direction = "up"
		end
	end
	
	return direction
end

--Counts how many elements are in a table
function counttable(arg)
	local count = 0
	
	for _,_ in pairs(arg) do
		 count =  count + 1
	end
	
	return count
end

--[[ Requires all of the lua scripts in a given directory
The 2nd argument specifies whether or not to descend recursively ]]--
function load_scripts(dir, recursive)
	--Default for recursive is false
	if recursive == nil then recursive = false end

	local files = love.filesystem.getDirectoryItems(dir)
	_.each(files, function(file)
		if  love.filesystem.isFile( dir .. "/" .. file ) then
			if string.sub(file, -4, -1) == ".lua" then
				modulename = string.sub(file, 0, -5)
				require(dir .. "/" .. modulename)
			end
		end
	end)

	if recursive then
		_.each(files, function(file)
			if love.filesystem.isDirectory( dir .. "/" .. file ) then
				load_scripts( dir .. "/" .. file, recursive)
			end
		end)
	end
end