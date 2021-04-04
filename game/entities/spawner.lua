--Define Class
Spawner = class('Spawner')

function Spawner:initialize( game, pos , size, classname, spawnertype, spawnatstart, basenumber, idletime, clearedscript)
	self.type = "spawner" --Set object type
	self.game = game
	
	--Initial position
	self.x = pos[1]
	self.y = pos[2]

	--Dimensions
	self.width = size[1]
	self.height = size[2]

	--Initializations
	self.classname = split( classname, "," )
	self.spawnertype = spawnertype
	
	if spawnatstart == nil then
		self.spawnatstart = false
	else
		self.spawnatstart = (spawnatstart:lower() == "true" )
	end
	
	if basenumber == nil then
		print("Spawner was created without specifying a base number!")
		self.basenumber = 0
	else
		self.basenumber = basenumber
	end
	
	if idletime == nil then
		self.idletime = 0
	else
		self.idletime = idletime
	end
	
	self.idletimer = nil
	
	if not (clearedscript == nil) then
		self.clearedscript = assert( loadstring( clearedscript ) )
	end

	self.active = false --Starts out inactive

	self.children = {} --Children currently alive

	--If spawnatstart is true, then call spawn() right off the bat
	if self.spawnatstart == true then
		self:spawn()
	end
end

function Spawner:killall()
	for key,child in pairs(self.children) do
		child.hp = -1
	end
end

function Spawner:getValidPos()
	while true do
		local posx = math.random( self.x, self.x + self.width)
		local posy = math.random( self.y,  self.y + self.height)
		
		if not self.game.map:collidePoint( posx, posy) then
			return posx, posy
		end
	end
end

function Spawner:spawn()
	print("Spawning enemies")
	
	self.active = true
	
	if self.spawnertype == "unique" then
		for i=1,self.basenumber do
			local posx, posy = self:getValidPos()
		
			--Create the enemy object
			local classname = trim( self.classname[ math.random(1, #self.classname ) ] )
			local enemy = enemytypes[ classname ]:new(posx, posy, self.game, self)
			
			table.insert( self.game.gameobjects,  enemy) --Add it to the game objects table
			table.insert( self.children,  enemy) --Add it your own table
		end
	end
	
	if self.spawnertype == "variable" or self.spawnertype == "continuous" then
		for i=1,self.basenumber*( counttable( self.game.players ) ) do
			local posx, posy = self:getValidPos()
			
			--Create the enemy object
			local classname = trim( self.classname[ math.random(1, #self.classname ) ] )
			local enemy = enemytypes[ classname ]:new(posx, posy, self.game, self)
			
			table.insert( self.game.gameobjects,  enemy) --Add it to the game objects table
			table.insert( self.children,  enemy) --Add it your own table
		end
	end
end

function Spawner:update(dt)
	if self.active == true then
		
		
		if counttable( self.children ) < 1 then
			if self.spawnertype == "unique" or self.spawnertype == "variable" then
				game = self.game 
				spawner = self
				
				if not (self.clearedscript == nil) then
					self.clearedscript()
				end
				
				self.active = false
			end
			
			if self.spawnertype == "continuous" then
			
				if self.idletimer == nil then
					game = self.game 
					spawner = self
					
					if not (clearedscript == nil) then self.clearedscript() end
					
					self.idletimer = self.idletime
				else
					self.idletimer = self.idletimer - dt
					
					if self.idletimer < 0 then
						self.idletimer = nil
						
						self:spawn()
					end
				end
				
				
			end
		end
	end
end

--Removes a given game object from the self.gameobjects list (Should work while iterating)
function Spawner:removeChild(object)
	for key,child in pairs(self.children) do
		if object == child then
			self.children[key] = nil
		end
	end
end