--Base class bullet
Bullet = class('Bullet')

function Bullet:initialize(args)
	self.side = args.side --This tells us if it was a player spawned bullet, or an enemy spawned bullet
	self.owner = args.owner --Keep a reference back to the entity that initially shot you
	self.game = args.game --Reference back to the game state

	--Iniitial position
	self.x = args.x
	self.y = args.y

	--Power stores the amount of damage that this bullet does to an actor
	self.power = args.power

	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0

	--Store a life variable, used for deleting bullets before they fly to infinity
	self.life = 0

	--Store when to expire
	self.life_max = args.life_max
end

function Bullet:draw()
	--Draw collision lines
	if self.game.debug == true then
		love.graphics.setPointSize(1)
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.point( self.x, self.y)
		
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
end

function Bullet:update(dt)
	self.life = self.life + dt

	if self.life_max ~= nil and self.life > self.life_max then
		self.game:removeGameObject(self)
	end
end

--[[ This function gets a list of possible victims, depending on the bullet's
listed side, calls victim:shoot, and removes itself if the function returns true]]--
function Bullet:collideVictims()
	local victims = nil
	
	if self.side == 0 then
		victims = self.game:getObjectsByType("enemy")
	else
		victims = self.game:getObjectsByType("player")
	end
	
	for _, victim in pairs(victims) do
		if victim:shoot(self) == true then
			self.game:removeGameObject(self) --If the shot was successful, remove the bullet
		end
	end
end