require "effects.rain"
require "effects.snow"
require "effects.fog"

--Define class
GameState = class('GameState')

--Called when the state is first launched
function GameState:initialize(players, mapfile)
	self.debug = false --Should I draw objects/collision boundaries?

	self.gameobjects = {} --Table containing all game objects (Players, enemies, doors, etc.)

	self.players = players
	local i = 1
	for _,player in pairs(self.players) do
		player.game = self --Give the player object a reference to this game state
		player.index = i --Tell the player which number they are
		i = i + 1
		table.insert(self.gameobjects, player) --Add the player to the list of game objects
	end
	
	--For Displaying Text on the Screen
	self.textTime = 0
	self.textString = ""

	--Create physics world
	self.world = love.physics.newWorld(0, 0, true)
	
	--Load map file
	cam.zoom_factor = 1
	self.map = Map:new(mapfile, self)
	
	local playerspawn = self.map:getObjectByType( "playerspawn" ) --Get the player spawn region
	--If there is one, randomly place the players within it
	if not (playerspawn == nil) then
		for _,player in pairs(self.players) do
			player.x = math.random( playerspawn.x,  playerspawn.x + playerspawn.width) --Random x position
			player.y = math.random( playerspawn.y,  playerspawn.y + playerspawn.height) --Random y position
		end
	end
	
	--Load triggers
	self.triggers = {} --Empty set in which to store triggers and spawners
	local trigger_objects = self.map:getObjectsByType( "trigger" )
	for _, trigger_object in pairs(trigger_objects) do
		local trigger = Trigger:new(self, { trigger_object.x, trigger_object.y },
										{ trigger_object.width, trigger_object.height },
										trigger_object.triggertype
										)
		if not(trigger_object.active == nil) then					
			if trigger_object.active:lower() == "false" then trigger.active = false end --Read whether or not the trigger should start in the active phase
		end
		
		if not(trigger_object.whiletriggered == nil) then
			trigger.whiletriggered = assert( loadstring(trigger_object.whiletriggered) )
		end
		
		if not(trigger_object.whilereleased == nil) then
			trigger.whilereleased = assert( loadstring(trigger_object.whilereleased) )
		end
		
		if not(trigger_object.onstart == nil) then
			trigger.onstart = assert( loadstring(trigger_object.onstart) )
		end
		
		if not(trigger_object.onend == nil) then
			trigger.onend = assert( loadstring(trigger_object.onend) )
		end
		
		if not(trigger_object.limit == nil) then
			trigger.limit = tonumber( trigger_object.limit )
		end
		
		--If a name has provided, add it to the table as a named entry (with a key). If not, just append it to the end
		if trigger_object.name == nil then
			table.insert(self.triggers, trigger)
		else
			self.triggers[trigger_object.name] = trigger
		end
	end
	
	--Load spawners
	self.spawners = {}
	local spawner_objects = self.map:getObjectsByType( "spawner" )
	
	for _, spawner_object in pairs(spawner_objects) do
		local spawner = Spawner:new(self,
									{ spawner_object.x, spawner_object.y },
									{ spawner_object.width, spawner_object.height },
									spawner_object.classname,
									spawner_object.spawnertype,
									spawner_object.spawnatstart,
									spawner_object.basenumber,
									spawner_object.idletime,
									spawner_object.clearedscript
									)
		
		if spawner_object.name == nil then
			table.insert(self.spawners, spawner)
		else
			self.spawners[spawner_object.name] = spawner
		end
	end
	
	--Load Props
	for i, props_object in pairs( self.map.objects ) do
		if not (proptypes[ props_object.type ] == nil) then
			local newprop = proptypes[ props_object.type ]:new( props_object, self )
			
			if props_object.name == nil then
				table.insert(self.gameobjects, newprop)
			else
				self.gameobjects[ props_object.name ] = newprop
			end
		end

		--Physics
		if props_object.type == "physics" then
			local body = love.physics.newBody(self.world, props_object.x, props_object.y)

			local points = _.flatten(props_object.points)
			local shape = nil
			if props_object.shape == "polyline" then
				shape = love.physics.newChainShape(false, unpack(points))
			else
				shape = love.physics.newChainShape(true, unpack(points))
			end
			local fixture = love.physics.newFixture(body, shape)
		end
	end
	
	--For Camera shaking
	self.cameraShakeTime = 0
	self.cameraShakeMag = 0
	
	--Level end info
	self.levelendtime = 0
	self.levelresult = 0
	
	--Precipitation
	--self.precipitation = nil
	
	self.map:updateCollision()
	
	--Force garbage collection before map starts
	collectgarbage()
end



--Returns the number of alive players
function GameState:alivePlayers()
	local alive_count = 0
	
	for _,player in pairs(self.players) do
		if player:isAlive() == true then
			alive_count = alive_count + 1
		end
	end
	
	return alive_count
end

--Returns the number of dead players
function GameState:deadPlayers()
	local dead_count = 0
	
	for _,player in pairs(self.players) do
		if player:isAlive() == false then
			dead_count = dead_count + 1
		end
	end
	
	return dead_count
end

--Removes a given game object from the self.gameobjects list (Should work while iterating)
function GameState:removeGameObject(object)
	for key,gameobject in pairs(self.gameobjects) do
		if object == gameobject then
			self.gameobjects[key] = nil
		end
	end
end

--Adds a given game object to the self.gameobjects list (Should work while iterating)
function GameState:addGameObject(object)
	table.insert(self.gameobjects, object)
end


--Called every frame for updating AI, etc
function GameState:update(dt)
	--Update physics world
	self.world:update(dt)
	
	--Update all gameobjects
	for _,gameobject in pairs(self.gameobjects) do
		gameobject:update(dt)
	end
	
	cam:fitPlayers(self.gameobjects, dt)
	
	--Update triggers
	for _, trigger in pairs(self.triggers) do
		trigger:update(dt)
	end
	
	--Update spawners
	for _, spawner in pairs(self.spawners) do
		spawner:update(dt)
	end
	
	self.map:update(dt) --Update map object
	
	--Shaking the Camera
	if self.cameraShakeTime > 0 then
		self.cameraShakeTime = self.cameraShakeTime - dt
		cam.x = cam.x + math.random( -self.cameraShakeMag,  self.cameraShakeMag)
		cam.y = cam.y + math.random( -self.cameraShakeMag,  self.cameraShakeMag)
	end
	
	--Text Display Time
	self.textTime = self.textTime - dt
	
	--Update precipitation
	if not(self.precipitation == nil) then
		self.precipitation:update(dt)
	end
	
	--Level end stuff
	if not( self.levelresult == 0 ) then
		self.levelendtime = self.levelendtime + dt
	else
		if self:alivePlayers() == 0 then
			self.levelresult = -1
		end
	end
end

--When any mouse button has been released
function GameState:mousepressed(x, y, button)
end

--When any mouse button is released
function GameState:mousereleased(x, y, button)
end

--Sort function that orders game objects by their Y coordinate
function orderY(a, b)
	if a == nil or b == nil then
		return false
	end
	
	return a.y < b.y
end

function drawOrder(a, b)
	if a.layer == nil then a.layer = 0 end
	if b.layer == nil then b.layer = 0 end

	if a.layer == b.layer then
		if a.y ~= nil and b.y ~= nil then
			return a.y < b.y
		end
	else
		return a.layer < b.layer
	end

	return false
end

--Called every frame to draw stuff onto screen
--[[
Note: calls that occur between the cam:set() and
cam::unset() functions draw objects that scroll with the camera
UI elements and background stuff should obviously not scroll with the camera
]]--
function GameState:draw()
	--Draw background elements
	
	cam:set() --Set camera matrix
	
	--Draw foreground elements
	
	self.map:draw() --Draw map

	local objects_to_draw = _.values(self.gameobjects) --Get an actual list
	_.sort(objects_to_draw, drawOrder) --Sort by layer and y-ordering
	_.invoke(objects_to_draw, "draw") --Draw all objects

	--Physics debug draw
	if self.debug then
		bodies = self.world:getBodyList()
		for _,body in pairs(bodies) do
			for _,fixture in pairs(body:getFixtureList()) do
				shape = fixture:getShape()
				love.graphics.setColor(255, 255, 255)
				if shape:getType() == "polygon" then
					love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
				end
				if shape:getType() == "circle" then
					love.graphics.circle("line", body:getX(), body:getY(), shape:getRadius())
				end
				if shape:getType() == "chain" then
					love.graphics.line(body:getWorldPoints(shape:getPoints()))
				end
			end
		end
		
	end
	
	cam:unset() --Unset camera
	
	--Draw precipitation
	if not(self.precipitation == nil) then
		self.precipitation:draw()
	end
	
	--Draw text to screen
	if self.textTime > 0 then
		love.graphics.setFont(caesardressing80)
		
		local width = love.graphics.getWidth()/2
		local x = love.graphics.getWidth()/2 - width/2
		local y = love.graphics.getHeight()*0.25
		love.graphics.setColor(0,0,0,255)
		love.graphics.printf( self.textString, x + 5, y + 5, width, "center")
		
		love.graphics.setColor(220,220,220,255)
		love.graphics.printf( self.textString, x, y, width, "center")
	end
	
	--Draw player scores
	local i = 1
	for _,player in pairs(self.players) do
		love.graphics.setFont(caesardressing40)
		
		love.graphics.setColor(PLAYER_COLORS[i][1], PLAYER_COLORS[i][2], PLAYER_COLORS[i][3],255)
		love.graphics.printf( "Player " .. i .. " - " .. player.score, 0, love.graphics.getHeight() - 5 - i*40, love.graphics.getWidth(), "left")
		
		i = i + 1
	end
	
	--Draw boss health
	if not( self.boss == nil ) then
		local width = love.graphics.getWidth()/3
		
		love.graphics.setColor( 255, 0, 0, 255 )
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - width/2, 25, width, 20)
		
		love.graphics.setColor( 0, 255, 0, 255 )
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - width/2, 25, (self.boss.hp/self.boss.maxhp)*width, 20)
	end
	
	if not( self.levelresult == 0 ) then
		love.graphics.setFont(caesardressing80)
	
		local width = love.graphics.getWidth()/2
		local x = love.graphics.getWidth()/2 - width/2
		local y = love.graphics.getHeight()*0.45
		
		if self.levelendtime < 3 then
			love.graphics.setColor(255,255,255, (self.levelendtime/3) * 255)
		else
			love.graphics.setColor(255,255,255, 255)
		end
		
		love.graphics.rectangle( "fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight() )
		
		if self.levelresult == 1 then
			love.graphics.setColor(0,255,0,255)
			love.graphics.printf("Victory" , x, y, width, "center")
			
			setMusic("victory.mp3")
		end
		
		if self.levelresult == -1 then
			love.graphics.setColor(255,0,0,255)
			love.graphics.printf("Defeat" , x, y, width, "center")
			
			setMusic("defeat.mp3")
		end
	end
end

function GameState:showText(text, duration)
	self.textString = text
	self.textTime = duration
end

--Get's a table containing all game objects of a specific type
function GameState:getObjectsByType(type)
	local objects = {}
	
	for _, object in pairs( self.gameobjects ) do
		if not (object.type == nil) then
			if object.type:lower() == type:lower() then
				table.insert(objects, object)
			end
		end
	end
	
	return objects
end

function GameState:shakeCamera(camtime,cammag) --Sets camera shaking variables
	if camtime > self.cameraShakeTime then
		self.cameraShakeTime = camtime
	end
	
	if cammag > self.cameraShakeMag then
		self.cameraShakeMag = cammag
	end
end

--Called whenever a key is pressed
function GameState:keypressed(key, unicode)
	if key == "f1" then
		self.debug = not self.debug
	end
end

--Called whenever a key is released
function GameState:keyreleased(key, unicode)
	
end