--Directory in which to look for the map file and all of its corresponding files
MAPS_DIR = "maps/"

--Define class
Map = class('Map')

--Constructor for map class
function Map:initialize(filename, game)
	self.game = game --Reference back to gamestate

	self.filename = MAPS_DIR .. filename --Get the full path to the file
	print("Loading map from " .. filename)
	
	self.file = love.filesystem.newFile(self.filename) --Open the file and read it
	self.file:open('r')
	
	self.xml, self.xmlsize = self.file:read() --Read in whole file to self.xml
	
	self.doc = SLAXML:dom( self.xml ) --Parse xml into dom using SLAXML
	self.map = self.doc.root --Get root element
	
	--Attributes of map element
	self.width = tonumber( self.map.attr["width"] )
	self.height = tonumber( self.map.attr["height"] )
	self.tilewidth = tonumber( self.map.attr["tilewidth"] )
	self.tileheight = tonumber( self.map.attr["tileheight"] )
	
	self.layers = {} --Table to store all layer objets
	self.tilesets = {} --Table to store all tileset objects
	self.objects = {} --Stores all objects loaded from the object layers
	
	self.collisionlayer = nil
	
	--First pass. This is just to ensure that all tilesets have been loaded before layers are loaded
	for _,element in pairs(self.map.kids) do
		if element.name == "properties" then --Map properties
			for _, property_element in pairs(element.kids) do
				if  property_element.name == "property" then
					local name = property_element.attr["name"]
					local value = property_element.attr["value"]
					
					if name == "onstart" then self.onstart = assert( loadstring(value) ) end
					if name == "onupdate" then self.onupdate = assert( loadstring(value) ) end
					if name == "BULLETS_COLLIDE" then BULLETS_COLLIDE = (value:lower() == "true") end
				end
			end
		end
		
		--Load tilesets
		if element.name == "tileset" then
			self.tilesets[ element.attr["name"] ] = TileSet:new( element, self)
		end
		
		if element.name == "objectgroup" then
		
			for _, object_element in pairs(element.kids) do
				if object_element.name == "object" then
					--Create object as a table
					local object = {}
					object.name = object_element.attr["name"] --Load it's name information
					object.type = object_element.attr["type"] --Load type information
					
					--Load attributes, however, any of these could be nill
					object.x = tonumber( object_element.attr["x"] )
					object.y = tonumber( object_element.attr["y"] )
					object.width = tonumber( object_element.attr["width"] )
					object.height = tonumber( object_element.attr["height"] )
					
					--Find out what shape it is
					object.shape = "rectangle" --Start out assuming its a rectangle
					
					for _, shape in pairs(object_element.kids) do
						if shape.name == "ellipse" then
							object.shape = "ellipse"
						end
						
						if shape.name == "polygon" or shape.name == "polyline" then
							object.shape = shape.name
							object.points = {}
							
							for _, point in ipairs( split( shape.attr["points"], " " ) ) do
								local coordinates_string = split( point, "," )
								local coordinates = { tonumber( coordinates_string[1] ), tonumber( coordinates_string[2] ) }
								
								table.insert( object.points, coordinates)
							end
						end
						
						if shape.name == "properties" then
							for _, property in pairs(shape.kids) do
								if property.name == "property" then
									object[ property.attr["name"] ] = property.attr["value"]
									print(  property.attr["name"], object[ property.attr["name"] ] )
								end
							end
						end
					end
					
					if object.name == nil then
						table.insert( self.objects , object) --If the name was not specified, just insert it in
					else
						self.objects[ object.name ] = object --If a name was provided, use that for the key
						print ("Loaded object " .. object.name)
					end
				end
			end
			
		end
	end
	
	--Second pass
	for i,element in pairs(self.map.kids) do
		if element.name == "layer" then
			local layer = Layer:new( element, self )
			table.insert( self.layers, layer) --insert layer - this is done instead of using the name as a key, because order must be preserved
			
			if element.attr["name"]:lower() == "collision" then
				self.collisionlayer = layer
				self.collisionlayer:populatePhysicsWorld(self.game.world)
				
				print("Found a collision layer!")
			end
		end
	end

	print(filename .. " successfully loaded")
	
	if not (self.onstart == nil) then
		_G[ "game" ] = self.game
		self.onstart()
	end
	
	self:startAstarThread()
end

function Map:startAstarThread()
	
  --Channel for communicating setup info to AStar thread
  self.channel = love.thread.getChannel( "astar_setup" )
	
	--Send initial info for setting up map
	self.channel:supply({
      type = "setup",
      tilewidth = self.tilewidth,
      tileheight = self.tileheight,
      tiles = table.concat( self.collisionlayer.data, ", " ),
      width = self.collisionlayer.width
      })
	
	print("Started A-star Thread")
end

function Map:updateCollision()
	local serialized = serpent.dump( self:getObjectsByType("collision") )
	self.channel:supply({
      type = 'collision',
      data = serialized
    })
end

--Returns the first object of a specific type
function Map:getObjectByType(type)
	for i, object in pairs( self.objects ) do
		if not (object.type == nil) then
			if object.type:lower() == type:lower() then
				return object
			end
		end
	end
	
	return nil
end

--Get's a table containing all objects of a specific type
function Map:getObjectsByType(type)
	local objects = {}
	
	for _, object in pairs( self.objects ) do
		if not (object.type == nil) then
			if object.type:lower() == type:lower() then
				table.insert(objects, object)
			end
		end
	end
	
	return objects
end

--Get the tileset object that owns the current
function Map:getTileSet(tilenum)
	for name,tileset in pairs(self.tilesets) do
		if tilenum >= tileset.firstgid and tilenum < (tileset.firstgid + tileset.numtiles) then
			return name, tileset
		end
	end
	
	return nil, nil
end

function Map:update(dt)
	--Call the registered onupdate handler
	if not (self.onupdate == nil) then
		self.onupdate()
	end
end

--[[ Check to see if a given point falls within either one of
the collision objects, or within the collision layer of the tilemap ]]--
function Map:collidePoint(x, y)
	--Collide with collision objects
	local collisionObjects = self:getObjectsByType("collision")
	for _, collisionObject in pairs(collisionObjects) do
		if x > collisionObject.x and y > collisionObject.y then
			if x < collisionObject.x + collisionObject.width and y < collisionObject.y + collisionObject.height then
				return true
			end
		end
	end
	
	--Collide with collision layer
	if not (self.collisionlayer == nil) then
		return not (self.collisionlayer:getTileAtPoint(x, y) == 0)
	end
	
	return false
end

--[[ Given a rectangle and the position the rectangle wants to move to,
the function returns the position the rectangle should be at if it collides
with the collision layer of the tilemap
]]--
function Map:collideRectangle(oldx, oldy, width, height, newx, newy)
	--"Push" in the x direction firest, then push in the y direction
	
	--Moving right
	if newx - oldx > 0 then
		local oldright, top = self.collisionlayer:getIndex(oldx + width/2, oldy - height/2)
		local newright, bot = self.collisionlayer:getIndex(newx + width/2, oldy + height/2)
		
		local x_coll = false
		
		for x = oldright, newright do
			for y = top, bot do
				if not (self.collisionlayer:getTile(x, y) == 0) then
					newx = (x-1)*self.tilewidth - width/2 - 1
					
					x_coll = true
					break
				end
			end
			
			if x_coll == true then break end
		end
	end
	
	--Moving left
	if newx - oldx < 0 then
		local oldleft, top = self.collisionlayer:getIndex(oldx - width/2, oldy - height/2)
		local newleft, bot = self.collisionlayer:getIndex(newx - width/2, oldy + height/2)
		
		local x_coll = false
		
		for x = oldleft, newleft, -1 do
			for y = top, bot do
				if not (self.collisionlayer:getTile(x, y) == 0) then
					newx = (x)*self.tilewidth + width/2 + 1
					
					x_coll = true
					break
				end
			end
			
			if x_coll == true then break end
		end
	end
	
	--Moving down
	if newy - oldy > 0 then
		local right, oldbot = self.collisionlayer:getIndex(newx + width/2, oldy + height/2)
		local left, newbot = self.collisionlayer:getIndex(newx - width/2, newy + height/2)
		
		local y_coll = false
		
		for y = oldbot, newbot do
			for x = left, right do
				if not (self.collisionlayer:getTile(x, y) == 0) then
					newy = (y-1)*self.tileheight- height/2 - 1
				
					y_coll = true
					break
				end
			end
		
			if y_coll == true then break end
		end
	end
	
	--Moving up
	if newy - oldy < 0 then
		local right, oldtop = self.collisionlayer:getIndex(newx + width/2, oldy - height/2)
		local left, newtop = self.collisionlayer:getIndex(newx - width/2, newy - height/2)
		
		local y_coll = false
		
		for y = oldtop, newtop, -1 do
			for x = left, right do
				if not (self.collisionlayer:getTile(x, y) == 0) then
					newy = (y)*self.tileheight + height/2 + 1
				
					y_coll = true
					break
				end
			end
		end

	end
	
	--Collide with collision objects
	local collisionObjects = self:getObjectsByType("collision")
	for _, collisionObject in pairs(collisionObjects) do
		local collisionx = collideRect(newx - width/2, oldy - height/2, newx + width, oldy + height,
		collisionObject.x, collisionObject.y, collisionObject.x + collisionObject.width, collisionObject.y + collisionObject.height) 
		
		if collisionx then
			newx = oldx
		end
		
		local collisiony = collideRect(newx - width/2, newy - height/2, newx + width, newy + height,
		collisionObject.x, collisionObject.y, collisionObject.x + collisionObject.width, collisionObject.y + collisionObject.height) 

		if collisiony then
			newy = oldy
		end
	end
	
	return newx, newy
end

function Map:draw()
	love.graphics.setColor( 255, 255, 255, 255 ) --Reset draw color to white
	
	--iterate through each tile layer
	for i, layer in ipairs(self.layers) do
		layer:draw(self.game.debug)
	end
	
	love.graphics.setLineWidth (2)
	--Draw objects
	if self.game.debug == true then
		for i, object in pairs( self.objects ) do
		
			if object.type == "collision" then
				love.graphics.setColor( 255, 0, 0, 100 ) --Set draw color to greyish
			else
				love.graphics.setColor( 100, 100, 100, 100 ) --Set draw color to greyish
			end
			
			if object.shape == "rectangle" then
				love.graphics.rectangle("line", object.x, object.y, object.width, object.height)
			end
			
			if object.shape == "ellipse" then
				love.graphics.rectangle("line", object.x, object.y, object.width, object.height)
			end
			
			if object.shape == "polyline" or object.shape == "polygon" then
				local points = {}
				
				for j, point in pairs( object.points ) do
					table.insert( points, object.x + point[1])
					table.insert( points, object.y + point[2])
				end
				
				if object.shape == "polyline" then
					love.graphics.line( points )
				else
					love.graphics.polygon("fill",  points )
				end
			end
		end
	end
end

return Map