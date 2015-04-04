--Define class
ControlMenu = class('ControlMenu')

--Called when the state is first launched
function ControlMenu:initialize()
	self.players = {}
	
	love.graphics.setBackgroundColor( 0 , 0 , 0 )
	
	HAS_PLAYER = {}
	
	self.card = getImage("menu/player.png")

	--Ready buttons
	self.ready_on = getImage("menu/ready_on.png")
	self.ready_off = getImage("menu/ready_off.png")
	self.ready_buttons = {}
	
	cam.y = self.card:getHeight()*0.5
end

--Called every frame for updating AI, etc
function ControlMenu:update(dt)
	
	--Camera movement calculation
	local targetwidth = (#self.players)*self.card:getWidth()*1.1  - self.card:getWidth()*0.1
	local targetx =  targetwidth*0.5
	local targetzoomx = ( targetwidth / love.graphics.getWidth() ) * 1.05
	local targetzoomy = ( self.card:getHeight()*1.5 / love.graphics.getHeight() )
	
	local targetzoom = targetzoomy
	if targetzoomx > targetzoomy then
		targetzoom = targetzoomx
	end
	
	if cam.x < targetx then
		cam.x = cam.x + 400*dt
	end
	
	if cam.x > targetx then
		cam.x = cam.x - 400*dt
	end
	
	if #self.players > 0 then
		if cam.zoom < targetzoom then	
			cam.zoom = cam.zoom + dt
		else
			cam.zoom = targetzoom
		end
	end
	
	--Loop through all the joysticks
	local joysticks = love.joystick.getJoysticks()
	for i, joystick in ipairs(joysticks) do
	
		--Loop through all the buttons on that joystick
		for j=1,joystick:getButtonCount() do
			if joystick:isDown( j ) and HAS_PLAYER[i] == nil then
				HAS_PLAYER[i] = true
				table.insert( self.players, GamepadPlayer:new(joysticks[i]) )
			end
		end
	end

	--Update player cursors
	_.each(self.players, function(player)
		player:updateCursor(dt)

		if player:cursorReleased() then
			local button = self.ready_buttons[player]
			local world_x, world_y = cam:project(player.cursor_x, player.cursor_y)
			
			if world_x > button.x and world_x < button.x + button.width then
				if world_y > button.y and world_y < button.y + button.height then
					--Toggle whether or not the player is ready
					if player.ready == nil then player.ready = true
					else player.ready = nil end
				end
			end
		end
	end)

	--Check if all players are ready
	local all_ready = _.all(self.players, function(player) return player.ready ~= nil end)

	if all_ready and #self.players > 0 then
		currentstate = MapMenu:new(self.players)
	end
end


--Called every frame to draw stuff onto screen
--[[
Note: calls that occur between the cam:set() and
cam::unset() functions draw objects that scroll with the camera
UI elements and background stuff should obviously not scroll with the camera
]]--
function ControlMenu:draw()
	--Draw background elements
	
	cam:set() --Set camera matrix
	
	--Draw player cards
	for i,player in ipairs(self.players) do
		local card_x = (i - 1)*self.card:getWidth()*1.1
		local card_y  = 0
		love.graphics.draw(self.card, card_x, card_y)

		local readybutton_x = card_x + self.card:getWidth()/2 - self.ready_off:getWidth()/2
		local readybutton_y = card_y + self.card:getHeight() - 50

		self.ready_buttons[player] = {
			x = readybutton_x,
			y = readybutton_y,
			width = self.ready_off:getWidth(),
			height = self.ready_off:getHeight()
		}

		if player.ready == nil then
			love.graphics.draw(self.ready_off, readybutton_x, readybutton_y)
		else
			love.graphics.draw(self.ready_on, readybutton_x, readybutton_y)
		end
	end
	
	cam:unset() --Unset camera
	
	
	--Draw title
	love.graphics.setFont(caesardressing40)
	
	local width = love.graphics.getWidth()/2
	local x = love.graphics.getWidth()/2 - width/2
	local y = love.graphics.getHeight()*0.02
	love.graphics.setColor(0,0,0,255)
	love.graphics.printf( "Press any key to join...", x + 5, y + 5, width, "center")
	
	love.graphics.setColor(255,255,255,255)
	love.graphics.printf( "Press any key to join...", x, y, width, "center")

	--Draw player cursors
	local i = 1
	_.each(self.players, function(player)
		--Make sure the player knows what its index is (this is for colors)
		player.index = i
		i = i + 1

		--Draw the cursor
		player:drawCursor()
	end)
end

--Called whenever a key is pressed
function ControlMenu:keypressed(key, unicode)
end

--Called whenever a key is released
function ControlMenu:keyreleased(key, unicode)
	if HAS_PLAYER["keyboard"] == nil then
		local keyplayer = KeyboardPlayer:new()
		table.insert(self.players, keyplayer)
		HAS_PLAYER["keyboard"] = keyplayer
	end
end


--When any mouse button has been released
function ControlMenu:mousepressed(x, y, button)
end

--When any mouse button is released
function ControlMenu:mousereleased(x, y, button)
	if HAS_PLAYER["mouse"] == nil then
		local mouseplayer = MousePlayer:new()
		table.insert(self.players, mouseplayer)
		HAS_PLAYER["mouse"] = mouseplayer
	end
end