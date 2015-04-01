--Define class
Explosion = class('Explosion')

function Explosion:initialize(x,y,game, color, endcolor, life)

	if endcolor == nil then
		endcolor = {58, 58, 58}
	end
	
	if color[4] == nil then color[4] = 255 end
	if endcolor[4] == nil then endcolor[4] = 0 end
	
	self.life = life
	if self.life == nil then self.life = 0.5 end
	
	--Spawn position
	self.x = x
	self.y = y
	
	self.type = "explosion"
	
	--Reference to Game State
	self.game = game
	
	self.time = 0
	
	--Particle system
	self.p = love.graphics.newParticleSystem( getImage("enemies/ghost/fire.png") , 1000)
	self.p:setEmissionRate(100)
	self.p:setSpeed(80, 100)
	self.p:setLinearAcceleration(0, 10)
	self.p:setSizes(2, 0.5)
	
	self.p:setColors(color[1], color[2], color[3], color[4], endcolor[1], endcolor[2], endcolor[3], endcolor[4])
	
	self.p:setParticleLifetime( self.life )
	
	self.p:setDirection(-3.14/2)
	self.p:setSpread(3.14*2)
	
	self.p:setPosition(self.x, self.y)
end

function Explosion:draw()
	love.graphics.draw( self.p, 0, 0)
end

function Explosion:update(dt)
	--Makes the ghost bob up and down
	self.time = self.time + dt
	
	self.p:update(dt)
	
	if self.time > self.life then
		self.p:stop()
	end
	
	if self.time > self.life*2 then
		self.game:removeGameObject( self )
	end
end