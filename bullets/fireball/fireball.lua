
--Define class
Fireball = class('Fireball')

FIREBALL_SPEED = 200
FIREBALL_POWER = 5
FIREBALL_RELOAD = 1
FIREBALL_LIFE = 5


function Fireball:initialize(side, x, y, angle, game, target)
	self.target = target

	self.side = side --This tells us if it was a player spawned bullet, or an enemy spawned bullet
	
	--Initial position
	self.x = x
	self.y = y
	
	self.game = game --Reference back to the game state
	
	self.life = 0
	
	self.power = FIREBALL_POWER
	
	self.rotation = angle
	
	
	self.image = getImage("bullets/fireball/fireball.png")
	self.offx = self.image:getWidth()/2
	self.offy = self.image:getHeight()/2
	
	self.p = love.graphics.newParticleSystem( getImage("enemies/ghost/fire.png") , 1000)
	self.p:setEmissionRate(100)
	self.p:setSpeed(0,0)
	self.p:setSizes(0.5, 1)
	self.p:setColors( 255, 240, 94, 100, 255, 110, 4, 0)
	self.p:setParticleLifetime(0.25)
	self.p:setSpread(0.3)
	
	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = self.image:getWidth()*2
	self.collheight = self.image:getHeight()*2

	self.rotspeed = 0.5
	
	
end

function Fireball:draw()
	if self.game.debug == true then
		love.graphics.setPointSize(10)
		
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
	
	love.graphics.setColor( 255, 255, 255, 255 )
	
	love.graphics.draw(self.image, self.x, self.y, 0, 2, 2, self.offx, self.offy )
	
	love.graphics.draw( self.p, 0, 0)
end

function Fireball:update(dt)
	self.life = self.life + dt
	
	if self.life > FIREBALL_LIFE then
		self.game:removeGameObject(self)
	end
	
	if self.game.map:collidePoint(self.x, self.y) then
		self.game:removeGameObject(self)
	end
	
	self.x = self.x + ( math.sin(self.rotation)*FIREBALL_SPEED)*dt
	self.y = self.y + ( math.cos(self.rotation)*FIREBALL_SPEED)*dt
	
	self.p:setPosition(self.x, self.y)
	self.p:update(dt)
	
	self.collx = self.x - self.offx*2
	self.colly = self.y - self.offy*2
	
	if self.side == 0 then
		victims = self.game:getObjectsByType("enemy")
	else
		victims = self.game:getObjectsByType("player")
	end
	
	for _, victim in pairs(victims) do
		if victim:shoot(self) == true then
			self.game:removeGameObject(self)
		end
	end
	
	self.targetangle = math.getAngle(self.x, self.y, self.target.x, self.target.y)
	
	if self.targetangle > 2*math.pi then self.targetangle = self.targetangle - 2*math.pi end
	if self.targetangle < 0 then self.targetangle = self.targetangle + 2*math.pi end
	
	if self.rotation > 2*math.pi then self.rotation = self.rotation - 2*math.pi end
	if self.rotation < 0 then self.rotation = self.rotation + 2*math.pi end
	
	if math.abs( self.targetangle - self.rotation) < math.pi then
		if self.rotation < self.targetangle then
			self.rotation = self.rotation + self.rotspeed*dt
		end
		if self.rotation > self.targetangle then
			self.rotation = self.rotation - self.rotspeed*dt
		end
	else
		if self.rotation < self.targetangle then
			self.rotation = self.rotation - self.rotspeed*dt
		end
		if self.rotation > self.targetangle then
			self.rotation = self.rotation + self.rotspeed*dt
		end
	end
	
	
end