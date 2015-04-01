--Define class
Credits = class('Credits')

--Called when the state is first launched
function Credits:initialize()
	self.time = 0
	
	self.credits, self.size = love.filesystem.read("CREDITS.txt")
	love.graphics.setBackgroundColor( 0,0,0 ) --Set background color to white
end

--Called every frame for updating AI, etc
function Credits:update(dt)
	self.time = self.time + dt
end


--Called every frame to draw stuff onto screen
--[[
Note: calls that occur between the cam:set() and
cam::unset() functions draw objects that scroll with the camera
UI elements and background stuff should obviously not scroll with the camera
]]--
function Credits:draw()
	love.graphics.setFont(caesardressing30)
	love.graphics.setColor(255,255,255,255)
	
	local pos = love.graphics.getHeight()-self.time*30
	love.graphics.printf( self.credits, 0, pos, love.graphics.getWidth(), "center")
	
	local width, lines = caesardressing30:getWrap(self.credits, love.graphics.getWidth())
	local length = lines*caesardressing30:getHeight( )
	
	--When credits finish, jump back to the main menu
	if pos + length < 0 then
		currentstate = Credits:new()
	end
end

--Called whenever a key is pressed
function Credits:keypressed(key, unicode)
end

--Called whenever a key is released
function Credits:keyreleased(key, unicode)
end

--When any mouse button has been released
function Credits:mousepressed(x, y, button)
end

--When any mouse button is released
function Credits:mousereleased(x, y, button)
end