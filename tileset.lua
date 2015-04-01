TileSet = class('TileSet')

function TileSet:initialize(element, map)
	self.element = element
	self.map = map
	
	self.name = element.attr["name"]
	
	self.tilewidth =  tonumber( element.attr["tilewidth"] )
	self.tileheight =  tonumber( element.attr["tileheight"] )
	
	self.quads = {}
	
	for i,element in pairs(self.element.kids) do
		if element.name == "image" then
			self.file = MAPS_DIR .. element.attr["source"]
			
			self.width = tonumber( element.attr["width"] )
			self.height = tonumber( element.attr["height"] )
			
			self.image = love.graphics.newImage( self.file )
			self.image:setFilter("nearest", "nearest")
		end
	end
	
	self.firstgid = tonumber( element.attr["firstgid"] )
	
	self.rows = (self.width/self.tilewidth)
	self.columns = (self.height/self.tileheight)
	
	self.numtiles = self.rows*self.columns
	
	for i=0,self.numtiles-1 do
		local column = math.floor( i/self.rows )
		local row = i % self.rows
		
		self.quads[ i + self.firstgid ] = love.graphics.newQuad( row*self.tilewidth, column*self.tileheight, self.tilewidth, self.tileheight, self.width, self.height )
	end
	
	print("Loaded tileset " .. self.name .. " (" .. self.file .. ") containing " .. self.numtiles .. " tiles")
end