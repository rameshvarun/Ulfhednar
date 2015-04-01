Layer = class('Layer')

function Layer:initialize(element, map)
	self.element = element
	self.map = map
	
	self.name = element.attr["name"]
	
	self.width =  tonumber( element.attr["width"] )
	self.height =  tonumber( element.attr["height"] )
	
	self.data = {}
	
	for i,element in pairs(self.element.kids) do
		if element.name == "data" then
			local tiles = split( elementText(element), "," ) --Split csv into table of strings
			
			for j,tile in ipairs(tiles) do
				self.data[j] = tonumber( tile ) --Covert table of strings to numbers
			end
		end
	end
	
	--Since a sprite batch can only consist of a single image, you need a separate sprite batch for each tileset
	self.batches = {}
	
	for name,tileset in pairs(self.map.tilesets) do
		self.batches[name] = love.graphics.newSpriteBatch(tileset.image, self.width*self.height)
	end
	
	self:updateBatches()
	
	print("Loaded layer " .. self.name)
end

function Layer:updateBatches()
	for name,tileset in pairs(self.map.tilesets) do
		self.batches[name]:clear()
	end
	
	for x=1,self.width do
		for y=1,self.height do
			local tilenum = self:getTile(x, y)
			
			if tilenum > 0 then
				local name, tileset = self.map:getTileSet(tilenum)
			
				self.batches[name]:add( tileset.quads[tilenum], (x - 1)*self.map.tilewidth, (y - 1)*self.map.tileheight )
			end
		end
	end
end

function Layer:getTile(ix, iy)
	return self.data[ (iy-1)*self.width + ix ]
end

function Layer:getIndex(x, y)
	return math.floor(x/ self.map.tilewidth ) + 1, math.floor(y/ self.map.tileheight ) + 1
end

function Layer:getTileAtPoint(x, y)
	ix, iy = self:getIndex(x, y)
	
	return self:getTile(ix, iy)
end

function Layer:draw(debug)
	if not (self.name:lower() == "collision") then
		for name,tileset in pairs(self.map.tilesets) do
			love.graphics.draw( self.batches[name] )
		end
	end

	
end

--[[ Uses the tilemap data to populate static bodies in the given physics
world. Should only be called on collision layers. ]]--
function Layer:populatePhysicsWorld(world)
	for x=1,self.width do
		for y=1,self.height do
			local tilenum = self:getTile(x, y)
			
			if tilenum > 0 then
				local body = love.physics.newBody(world, (x - 0.5)*self.map.tilewidth,  (y - 0.5)*self.map.tileheight)
				local shape = love.physics.newRectangleShape(self.map.tilewidth, self.map.tileheight)
				local fixture = love.physics.newFixture(body, shape)
			end
		end
	end
end