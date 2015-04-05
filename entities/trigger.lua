--Define class
Trigger = class('Trigger')

function Trigger:initialize(game, pos , size, triggertype)
	self.type = "trigger" --Set object type
	self.game = game
	
	--Initial position
	self.x = pos[1]
	self.y = pos[2]
	
	--print(self.x, self.y)

	--Dimensions
	self.width = size[1]
	self.height = size[2]
	
	self.triggertype = triggertype
	
	self.active = true
	
	print("Created trigger of type " .. self.triggertype)
	
	--Variables to keep track of whether or not the trigger has been triggered
	self.triggered = false
	self.oldtriggered = false
	
	--Callbacks
	self.whiletriggered = nil
	self.whilereleased = nil
	self.onstart = nil
	self.onend = nil
	
	self.limit = nil --Limit how many times the trigger can be activated
	self.activation_count = 0 --How many times the trigger has been activated so far
end

function Trigger:update(dt)
	if self.active == true then
		if self.triggertype == "anyplayer" then --Logic for anyplayer trigger type
		
			self.triggered = false --Triggered starts out as false
			for _, player in pairs(self.game.players) do --Iterate through each player
				if player.x > self.x and player.y > self.y then
					if player.x < self.x + self.width and player.y < self.y + self.height then
						self.triggered = true --If the player is inside the trigger, set the value to true and break
						break
					end
				end
			end
			
		end
		
		if self.triggertype == "allplayers" then --Logic for allplayers trigger type
			local count = 0
			
			for _, player in pairs(self.game.players) do --Iterate through each player
				if player.x > self.x and player.y > self.y then
					if player.x < self.x + self.width and player.y < self.y + self.height and player:isAlive() then
						count = count + 1 --If the player is inside the trigger, add to the count
					end
				end
			end
			
			if count > 0 and count == self.game:alivePlayers() then
				self.triggered = true
			else
				self.triggered = false
			end
		end
		
		if self.triggered == true then
			if not (self.whiletriggered == nil) then
				game = self.game 
				trigger = self
				
				self.whiletriggered() --While triggered, call the whiletriggered() callback every frame
			end
		else
			if not (self.whilereleased == nil) then
				game = self.game 
				trigger = self
				
				self.whilereleased() --While not triggered, call the whilereleased() callback every frame
			end
		end
		
		if self.triggered == true and self.oldtriggered == false then
			
			if not (self.onstart == nil) then
				game = self.game 
				trigger = self
				
				self.onstart()
			end
		end
		
		if self.triggered == false and self.oldtriggered == true then
			self.activation_count = self.activation_count + 1
			
			if not (self.limit == nil) and self.activation_count >= self.limit then
				self.active = false
			end
			
			if not (self.onend == nil) then
				game = self.game 
				trigger = self
				
				self.onend()
			end
		end
	
		self.oldtriggered = self.triggered
	end
end