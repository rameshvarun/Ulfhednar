--Define class
MapMenu = class('MapMenu')

MAP_LOCATIONS = {

{
name = "Helheim",
x = 1430,
y = 1586,
file = "hellfloor1.tmx"
},

{
name = "Svartálfaheimr",
x = 1446,
y = 1330,
file = "svart1.tmx"
},

{
name = "Vanaheim",
x = 1169,
y = 1200
},

{
name = "Muspelheim",
x = 1737,
y = 1239
},

{
name = "Midgard",
x = 1465,
y = 1066
},

{
name = "Niflheim",
x = 1193,
y = 900
},

{
name = "Jötunheimr",
x = 1753,
y = 934
},

{
name = "Álfheimr",
x = 1483,
y = 812
},

{
name = "Asgard",
x = 1500,
y = 552
}

}

MAP_SPEED = 700

CURRENT_LOCATION_ID = 1

--Called when the state is first launched
function MapMenu:initialize( players )
	self.map = getImage("menu/levelselect.png")
	self.arrow = getImage("menu/arrow.png")
	self.go = getImage("menu/go.png")
	
	love.graphics.setBackgroundColor( 0, 0, 0 )
	
	cam.x = MAP_LOCATIONS[ CURRENT_LOCATION_ID ].x
	cam.y = MAP_LOCATIONS[ CURRENT_LOCATION_ID ].y
	
	cam.zoom = 0.7
	
	self.players = players
	local i = 1
	for _,player in pairs(self.players) do
		player.index = i --Tell the player which number they are
		i = i + 1
	end
end

--Called every frame for updating AI, etc
function MapMenu:update(dt)
	local CURRENT_LOCATION = MAP_LOCATIONS[ CURRENT_LOCATION_ID ]
	
	local diffx = CURRENT_LOCATION.x - cam.x
	local diffy = CURRENT_LOCATION.y - cam.y
	
	local dist = math.norm(diffx, diffy)
	self.dist = dist
	
	if dist > 10 then
		cam.x = cam.x + (diffx/dist)*dt*MAP_SPEED
		cam.y = cam.y + (diffy/dist)*dt*MAP_SPEED
		
		if cam.zoom  < 0.85 then
			cam.zoom = cam.zoom + dt
		end
	else
		if cam.zoom  > 0.7 then
			cam.zoom = cam.zoom - dt
		else
			cam.zoom = 0.7
		end
	end

	--Update cursors
	_.each(self.players, function(player)
		player:updateCursor(dt)

		if player:cursorReleased() then
			self:click(player.cursor_x, player.cursor_y)
		end
	end)
end

--When any mouse button has been first pressed
function MapMenu:mousepressed(x, y, button) end

--When any mouse button is released
function MapMenu:mousereleased(x, y, button) end

--Simulate a click at a specific point on the screen
function MapMenu:click(x, y)
	--Arrows
	if not(self.dist == nil) and self.dist < 20 then
		if self:unlocked(CURRENT_LOCATION_ID + 1) then
			if x > love.graphics.getWidth()*0.75 - self.arrow:getWidth()/2 then
				if x < love.graphics.getWidth()*0.75 + self.arrow:getWidth()/2 then
					if y > love.graphics.getHeight()/2 - self.arrow:getHeight()/2 then
						if y < love.graphics.getHeight()/2 + self.arrow:getHeight()/2 then
							self:increment()
						end
					end
				end
			end
		end
		
		
		if self:unlocked(CURRENT_LOCATION_ID - 1) then
			if x > love.graphics.getWidth()*0.25 - self.arrow:getWidth()/2 then
				if x < love.graphics.getWidth()*0.25 + self.arrow:getWidth()/2 then
					if y > love.graphics.getHeight()/2 - self.arrow:getHeight()/2 then
						if y < love.graphics.getHeight()/2 + self.arrow:getHeight()/2 then
							self:decrement()
						end
					end
				end
			end
		end
		
		if x > love.graphics.getWidth()/2 - self.go:getWidth()/2 and x < love.graphics.getWidth()/2 + self.go:getWidth()/2 then
			if y > love.graphics.getHeight()*0.75 - self.go:getHeight()/2 and y < love.graphics.getHeight()*0.75 + self.go:getHeight()/2 then
				self:startlevel()
			end
		end
	end
end

--Called every frame to draw stuff onto screen
--[[
Note: calls that occur between the cam:set() and
cam::unset() functions draw objects that scroll with the camera
UI elements and background stuff should obviously not scroll with the camera
]]--
function MapMenu:draw()
	local CURRENT_LOCATION = MAP_LOCATIONS[ CURRENT_LOCATION_ID ]
	
	--Draw background elements
	
	cam:set() --Set camera matrix
	
	--Draw foreground elements
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw( self.map)
	
	cam:unset() --Unset camera
	
	--Draw name
	love.graphics.setFont(caesardressing100)
	
	local width = love.graphics.getWidth()/2
	local x = love.graphics.getWidth()/2 - width/2
	local y = love.graphics.getHeight()*0.02
	love.graphics.setColor(0,0,0,255)
	love.graphics.printf( CURRENT_LOCATION.name, x + 5, y + 5, width, "center")
	
	love.graphics.setColor(255,255,255,255)
	love.graphics.printf( CURRENT_LOCATION.name, x, y, width, "center")
	
	--Arrows
	if not(self.dist == nil) and self.dist < 20 then
		if self:unlocked(CURRENT_LOCATION_ID + 1) then
			love.graphics.setColor(255,255,255,255)
			love.graphics.draw( self.arrow, love.graphics.getWidth()*0.75, love.graphics.getHeight()/2, 0, 1, 1, self.arrow:getWidth()/2 , self.arrow:getHeight()/2 )
		end
		
		if self:unlocked(CURRENT_LOCATION_ID - 1) then
			love.graphics.setColor(255,255,255,255)
			love.graphics.draw( self.arrow, love.graphics.getWidth()*0.25, love.graphics.getHeight()/2, math.pi, 1, 1, self.arrow:getWidth()/2 , self.arrow:getHeight()/2 )
		end
		
		love.graphics.draw( self.go, love.graphics.getWidth()/2, love.graphics.getHeight()*0.75, 0, 1, 1, self.go:getWidth()/2 , self.go:getHeight()/2 )
	end
	
	--Draw cursors
	_.each(self.players, function(player)
		player:drawCursor()
	end)
end

function MapMenu:unlocked( id )
	if id > #MAP_LOCATIONS or id < 1 then
		return false
	end
	
	return true
end

function MapMenu:increment()
	if self:unlocked(CURRENT_LOCATION_ID + 1) then
		CURRENT_LOCATION_ID = CURRENT_LOCATION_ID + 1
	end
end

function MapMenu:decrement()
	if self:unlocked(CURRENT_LOCATION_ID - 1) then
		CURRENT_LOCATION_ID = CURRENT_LOCATION_ID - 1
	end
end

function MapMenu:startlevel()
	currentstate = GameState:new(self.players, MAP_LOCATIONS[ CURRENT_LOCATION_ID ].file)
end

--Called whenever a key is pressed
function MapMenu:keypressed(key, unicode) end

--Called whenever a key is released
function MapMenu:keyreleased(key, unicode) end