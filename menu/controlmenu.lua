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

	self.close_button = getImage("menu/buttonroundbrown.png")
	self.cross_icon = getImage("menu/iconcross.png")
	self.leave_buttons = {}

	self.joystick_button_previous = {}
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
	_.each(love.joystick.getJoysticks(), function(joystick)
		for j=1, joystick:getButtonCount() do
			local current_state = joystick:isDown(j)
			if not current_state and self.joystick_button_previous[joystick:getGUID() .. j] == true then
				if HAS_PLAYER[joystick:getGUID()] == nil then
					local player = GamepadPlayer:new(joystick)
					HAS_PLAYER[joystick:getGUID()] = player
					table.insert(self.players, player)
				else
					HAS_PLAYER[joystick:getGUID()]:bind(j)
				end
			end
			self.joystick_button_previous[joystick:getGUID() .. j] = current_state
		end
	end)

	-- Loop through remotes
	for id, state in pairs(REMOTES) do
		if HAS_PLAYER[id] == nil and (state.attack or state.special) then
			local player = RemotePlayer:new(id)
			HAS_PLAYER[id] = player
			table.insert(self.players, player)
		end
	end

	--Update player cursors
	_.each(self.players, function(player)
		player:updateCursor(dt)

		if player:cursorReleased() then
			-- Check if the player has pressed their own ready button
			if cursorInButton(player, self.ready_buttons[player]) then
				--Toggle whether or not the player is ready
				if player.ready == nil then player.ready = true
				else player.ready = nil end
			end

			-- Check if a player has pressed their leave button
			if cursorInButton(player, self.leave_buttons[player]) then
				player.leave = true
			end
		end
	end)

	--Check if all players are ready
	local all_ready = _.all(self.players, function(player) return player.ready ~= nil end)
	if all_ready and #self.players > 0 then
		currentstate = MapMenu:new(self.players)
	end

	-- Remove players that want to leave
	local removed_players = _.select(self.players, function(player) return player.leave == true end)
	local retained_players = _.reject(self.players, function(player) return player.leave == true end)
	_.each(removed_players, function(player)
		if player.controltype == "keyboard" then HAS_PLAYER["keyboard"] = nil end
		if player.controltype == "mouse" then HAS_PLAYER["mouse"] = nil end
		if player.controltype == "gamepad" then HAS_PLAYER[player.joystick:getGUID()] = nil end
	end)

	self.players = retained_players
end

function cursorInButton(player, button)
	local world_x, world_y = cam:project(player.cursor_x, player.cursor_y)
	if world_x > button.x and world_x < button.x + button.width then
		if world_y > button.y and world_y < button.y + button.height then
			return true
		end
	end
	return false
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
	for i, player in ipairs(self.players) do
		love.graphics.setColor(255,255,255)

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

		-- Close button
		local leave_button = {
			x = card_x + 220,
			y = card_y - 15,
			width = self.close_button:getWidth(),
			height = self.close_button:getHeight()
		}
		self.leave_buttons[player] = leave_button

		love.graphics.draw(self.close_button, leave_button.x, leave_button.y)
		love.graphics.draw(self.cross_icon, leave_button.x + 10, leave_button.y + 10)

		player:useColor()
		love.graphics.setFont(caesardressing30)

		local playernum = "P"
		if player.index ~= nil then playernum = playernum .. player.index end
		love.graphics.printf( playernum, card_x + 10, card_y + 25, 210, "center")

		local control_name = "Unknown Controller"
		if player.controltype == "keyboard" then control_name = "Keyboard" end
		if player.controltype == "mouse" then control_name = "Mouse" end
		if player.controltype == "gamepad" then control_name = player.joystick:getName() end
		if player.controltype == "remote" then control_name = "Remote Player" end

		love.graphics.setFont(caesardressing20)
		love.graphics.printf( control_name , card_x + 10, card_y + 180, 210, "center")

		-- Binding process
		if player:toBind() ~= nil then
			love.graphics.setFont(caesardressing20)
			love.graphics.setColor(0,0,0)
			love.graphics.printf( "Press the " .. player:toBind() , card_x + 10, card_y + 235, 210, "center")
		else
			-- TODO: Draw Rebind Button
		end
	end
	
	cam:unset() --Unset camera
	
	--Draw title
	love.graphics.setFont(caesardressing40)
	
	local width = love.graphics.getWidth()/2
	local x = love.graphics.getWidth()/2 - width/2
	local y = love.graphics.getHeight()*0.02
	love.graphics.setColor(0,0,0,255)
	love.graphics.printf( "Press any key/button to join...", x + 5, y + 5, width, "center")
	
	love.graphics.setColor(255,255,255,255)
	love.graphics.printf( "Press any key/button to join...", x, y, width, "center")

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

-- Called whenever a key is pressed
function ControlMenu:keypressed(key, unicode)
end

-- Called whenever a key is released
function ControlMenu:keyreleased(key, unicode)
	if HAS_PLAYER["keyboard"] == nil then
		local keyplayer = KeyboardPlayer:new()
		table.insert(self.players, keyplayer)
		HAS_PLAYER["keyboard"] = keyplayer
	elseif HAS_PLAYER["keyboard"]:toBind() ~= nil then
		HAS_PLAYER["keyboard"]:bind(key)
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