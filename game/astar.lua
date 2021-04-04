--[[ Takes a start and goal(in tile coordinates)
Based off of http://en.wikipedia.org/wiki/A*_search_algorithm#Pseudocode
]]--

require 'love.timer'
require 'love.filesystem'

local serpent = require("libraries.serpent")

MAX_ASTAR_TIME = 1

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2)
	return math.sqrt((x2-x1)^2+(y2-y1)^2)
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


function getTile(ix, iy)
	return data[ (iy-1)*width + ix ]
end

function getIndex(x, y)
	return math.floor(x/ tilewidth ) + 1, math.floor(y/ tileheight ) + 1
end

function getTileAtPoint(x, y)
	ix, iy = getIndex(x, y)
	
	return getTile(ix, iy)
end

collisionObjects = {}
function collidePoint(x, y)
	--Collide with collision objects
	for _, collisionObject in pairs(collisionObjects) do
		if x > collisionObject.x and y > collisionObject.y then
			if x < collisionObject.x + collisionObject.width and y < collisionObject.y + collisionObject.height then
				return true
			end
		end
	end
	
	return not (getTileAtPoint(x, y) == 0)
end

function PointToString(node)
	return table.concat(node, ",")
end

function findPath(start, goal)
	local closedset = {} --Set of nodes already evaluated
	local openset = { start } --Set of nodes to be evaluated
	local came_from = {} --Map of nodes, use to reconstruct path afterwards
	
	local g_score = {}
	g_score[ PointToString( start ) ] = 0
	
	local f_score = {}
	f_score[ PointToString(start) ] = g_score[ PointToString( start ) ] + heuristic( start, goal )
	
	local starttime = love.timer.getTime()
	
	while #openset > 0 do
		local current = nil
		
		local lowest_f_score = nil
		for _,node in pairs(openset) do
			if lowest_f_score == nil or f_score[ PointToString(node) ] < lowest_f_score then
				current = node
				lowest_f_score = f_score[ PointToString(node) ]
			end
		end
		
		if current[1] == goal[1] and current[2] == goal[2] then
			return reconstruct_path(came_from, goal)
		end
		
		if love.timer.getTime() - starttime > MAX_ASTAR_TIME then
			return reconstruct_path(came_from, current)
		end
		
		--Remove current from openset
		for key, node in pairs(openset) do
			if node[1] == current[1] and node[2] == current[2] then
				openset[key] = nil
				break
			end
		end
		
		
		
		table.insert(closedset, current)
		
		--Iterate through neighboring nodes
		for x=-1,1 do
			for y=-1,1 do
				local isSameTile = (x == 0 and y == 0)
				local isCollision = collidePoint( (current[1] + x - 0.5)*tilewidth, (current[2] + y -0.5)*tileheight )
				if (not isSameTile) and (not isCollision) then
					neighbor = { current[1] + x, current[2] + y }
					
					tentative_g_score = g_score[ PointToString(current) ] + dist_between(current, neighbor)
					
					--Check if neighbor is in closedset
					neighbor_in_closedset = false
					for _, node in pairs(closedset) do
						if node[1] == neighbor[1] and node[2] == neighbor[2] then
							neighbor_in_closedset = true
							break
						end
					end
					
					--Check if neighbor is in openset
					neighbor_in_openset = false
					for _, node in pairs(openset) do
						if node[1] == neighbor[1] and node[2] == neighbor[2] then
							neighbor_in_openset = true
							break
						end
					end
					
					if neighbor_in_closedset and tentative_g_score >= g_score[ PointToString(neighbor) ] then
					
					else
						if (not neighbor_in_openset) or tentative_g_score < g_score[ PointToString(neighbor) ] then
							came_from[ PointToString(neighbor) ] = current
							g_score[ PointToString(neighbor) ] = tentative_g_score
							f_score[ PointToString(neighbor) ] = g_score[ PointToString(neighbor) ] + heuristic(neighbor, goal)
							
							if not neighbor_in_openset then
								table.insert( openset, neighbor )
							end
						end
					end
				end
			end
		end
		
	end
	
	return nil
end

function reconstruct_path(came_from, current_node)
	if not (came_from[ PointToString(current_node) ] == nil) then
		local p = reconstruct_path(came_from, came_from[ PointToString(current_node) ])
		table.insert(p, current_node)
		
		return p
	else
		return { current_node }
	end
end

function dist_between(a, b)
	return math.dist(a[1], a[2], b[1], b[2])
end

function heuristic(a, b)
	return math.dist(a[1], a[2], b[1], b[2])*50
end

--[[
The code below this is the queue management system. Above is the actual a-star algorithm
]]--

print("A-Star Thread: Initializing...")

--Get references to channels
local setup_channel = love.thread.getChannel( "astar_setup" )
local requests_channel = love.thread.getChannel( "astar_requests" )



while true do
  
  --Handle new setup information
  local setup_data = setup_channel:pop()
  if not(setup_data == nil) then
    --A new map is being setup
    if setup_data.type == "setup" then
      --Get the tile dimensions
      tilewidth = setup_data.tilewidth
      tileheight = setup_data.tileheight
      print(tilewidth)
      
      --Get tile map data as string, split by commas
      tiles = split( setup_data.tiles, "," )
      
      --Convert into table of numbers
      data = {}
      for j,tile in ipairs(tiles) do
        data[j] = tonumber( tile ) --Covert table of strings to numbers
      end
      
      --Get number of tiles in one row (width of the map)
      width = setup_data.width
      
      --Ready to recieve requests
      requests_channel:clear()
      print("A-Star Thread: Received map setup data, ready to receive requests...")
    end
    
    --If the list of collision objects has been updated (will also happen while map is running)
    if setup_data.type == "collision" then
      print("A-Star Thread: Received updated collision info...")
      collisionObjects = loadstring( setup_data.data )()
    end
  else
    --Only take requests if you did not receive setup info
    --Perform a-star requests
    local request = requests_channel:pop()
    if not(request == nil) then
      local message = request.message
      
      --Split into pieces by commas
      local words = split( message, "," )

      --Parse start node and end node
      local startnode = { tonumber(words[1]), tonumber(words[2]) }
      local endnode = { tonumber(words[3]), tonumber(words[4]) }
      
      --Channel in which to push back to main thread
      local result_channel = love.thread.getChannel( request.senderid )

      --Get result
      local path = findPath(startnode, endnode)
      local result = {}
      if not( path == nil ) then
        table.remove(path, 1)
        
        --Parse to string
        local points = {}
        for _, point in ipairs( path ) do
          table.insert(points, point[1] .. "," .. point[2])
        end
        
        result.points = table.concat(points, ";")
        result.foundPath = true
        --Post result back to main thread
        result_channel:push( result )
      else
        result.foundPath = false
        result_channel:push( result )
      end
    end
  end
end

