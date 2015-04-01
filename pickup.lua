--Base class player
Pickup = class('Pickup')

CHEESE_HEALTH = 5

function Pickup:initialize(x, y, pickuptype, game)
	--Position
	self.x = x
	self.y = y
	
	self.type = "pickup"
	
	self.game = game
	
	self.pickuptype = pickuptype
	
	self.time = 0
	
	--Cheese
	if pickuptype == 1 then
		self.image = getImage("pickups/cheese" .. math.random(1,2) .. ".png")
	end
	
	--Mead
	if pickuptype == 2 then
		self.image = getImage("pickups/mead" .. math.random(1,2) .. ".png")
	end
	
	--Shield
	if pickuptype == 3 then
		self.image = getImage("pickups/shield" .. math.random(1,2) .. ".png")
	end
	
	--Revives
	if pickuptype == 4 then
		self.image = getImage("pickups/revive.png")
	end
	
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
end

function Pickup:draw()
	love.graphics.setColor( 255, 255, 255, 180 )
	love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.draw(self.image, self.x , self.y - 5 + 3*math.sin(self.time*3), 0, 1, 1, self.image:getWidth()/2, self.image:getHeight())
end

function Pickup:update(dt)
	self.time = self.time + dt
	
	local players = self.game:getObjectsByType("player")
	for _, player in pairs(players) do
		if player.hp > 0 then --Only alive players can recieve pickups
			local dist = math.dist(self.x, self.y, player.x, player.y)
			
			if dist < 30 then
				self.game:removeGameObject(self)
				
				self.source = love.audio.newSource(pickup1)
				self.source:setVolume(0.2)
				self.source:play()
				
				if self.pickuptype == 1 then
					player.hp = player.hp + CHEESE_HEALTH
					
					if player.hp > player.maxhp then
						player.hp = player.maxhp
					end
				end
				
				if self.pickuptype == 2 then
					player.reloaddivider = 2
					player.dividertimer = 5
				end
				
				if self.pickuptype == 3 then
					player.shieldtimer = 5
				end
				
				if self.pickuptype == 4 then
					--Revive all dead players
					for _, dead_player in pairs( players ) do
						if dead_player:isAlive() == false then
							dead_player:revive( player.x, player.y)
						end
					end
				end
			end
		end
	end
end

function drop(x, y, game)

	--If there are dead players, there is a chance that a revive will spawn
	if game:deadPlayers() > 0 and math.random(1,3) == 1 then
		game:addGameObject( Pickup:new(x, y, 4, game) )
		
	else
		if math.random(1,5) == 1 then
			game:addGameObject( Pickup:new(x, y, math.random(1,3), game) )
		end
	end
end