--Define class
Ghost = class('Ghost', Enemy)

GHOST_SPEED = 200 --The ghost's move speed
GHOST_DIST_OTHER = 25 --The distance the ghost tries to maintain from other ghosts
GHOST_HEALTH_MAX = 15 --Maximum health for ghosts
GHOST_COLLISION_BUFFER = 0.8

GHOST_COLORS = { {255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255} }

GHOST_POWER = 2

GHOST_SCORE = 5

function Ghost:initialize(x,y,game, spawner)
	Enemy.initialize(self, x,y,game, spawner)

	--For ghost bobbing
	self.time = 0

	self.image = getImage("enemies/ghost/ghost.png") --Enemy Sprite
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow

	self.color = GHOST_COLORS[ math.random(1, #GHOST_COLORS) ] --Pick a random color

	--Particle system
	self.p = love.graphics.newParticleSystem( getImage("enemies/ghost/fire.png") , 1000)
	self.p:setEmissionRate(100)
	self.p:setSpeed(50, 100)
	self.p:setLinearAcceleration(0, 10)
	self.p:setSizes(2, 0.5)
	self.p:setColors(self.color[1], self.color[2], self.color[3], 110, 58, 58, 58, 0)
	self.p:setParticleLifetime(1)
	self.p:setDirection(-3.14/2)
	self.p:setSpread(0.3)

	--AI Behavior
	self.target = nil

	--Health
	self.maxhp = GHOST_HEALTH_MAX
	self.hp = self.maxhp

	self.alpha = 255

end

function Ghost:draw()
	love.graphics.setColor( 255, 255, 255, 100 + 50*math.sin(self.time*2) )
	love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)

	love.graphics.setColor( 255, 255, 255, self.alpha )

	love.graphics.draw( self.p, 0, 0)

	love.graphics.draw(self.image, self.x, self.y - 10 + 3*math.sin(self.time*2), 0, 1, 1, self.image:getWidth()/2, self.image:getHeight())

	Enemy.draw(self)
end

function Ghost:update(dt)
	if self.game.map:collidePoint(self.x, self.y) then
		if self.alpha > 75 then
			self.alpha = self.alpha - dt*600
		end

		if self.p:isActive() then
			self.p:stop()
		end
	else
		if self.alpha < 255 then
			self.alpha = self.alpha + dt*600
		else
			self.alpha = 255
		end

		if self.p:isActive() == false then
			self.p:start()
		end
	end

	--Makes the ghost bob up and down
	self.time = self.time + dt

	self.p:setPosition(self.x - 3, self.y - 22 + 3*math.sin(self.time*2))
	self.p:update(dt)

	if self.target == nil then --If you don't have a target
		self:selectTarget(800)
	else --If you have a target
		local diffx = self.target.x - self.x
		local diffy = self.target.y - self.y

		local dist = math.norm(diffx, diffy)

		if dist > 5 then
			local movex = diffx / dist
			local movey = diffy / dist

			self.x = self.x + movex*dt*GHOST_SPEED
			self.y = self.y + movey*dt*GHOST_SPEED
		end

		if not (self.target.hp > 0) then
			self.target = nil --If the target has died, move on to someone else
		end
	end

	--Don't clump up with other enemies
	local enemies = self.game:getObjectsByType("enemy")
	for _,enemy in pairs(enemies) do
		if not (enemy == self) then
			local diffx = self.x - enemy.x
			local diffy = self.y - enemy.y
			local dist = math.norm(diffx, diffy)

			if dist < GHOST_DIST_OTHER then
				self.x = enemy.x + (diffx/dist)*GHOST_DIST_OTHER
				self.y = enemy.y + (diffy/dist)*GHOST_DIST_OTHER
			end
		end
	end


	--Attack nearby players
	self:meleeNearby(10, GHOST_POWER)

	--Calculate collision bounds
	self.collwidth = self.image:getWidth()*GHOST_COLLISION_BUFFER
	self.collheight =  self.image:getHeight()*GHOST_COLLISION_BUFFER

	self.collx = self.x - self.collwidth/2
	self.colly = self.y- 10 + 3*math.sin(self.time*2) - self.image:getHeight()/2 - self.collheight/2

	--Handle death
	if self:handleDeath(GHOST_SCORE) then

		self.game:shakeCamera(0.2, 1)

		self.game:addGameObject( Explosion:new(self.x, self.y, self.game, self.color) )

		drop(self.x, self.y, self.game)

		love.timer.sleep( 0.05 )

		self.source = love.audio.newSource(explosion1)
		self.source:setVolume(0.2)
		self.source:play()


	end
end

enemytypes['ghost'] = Ghost
