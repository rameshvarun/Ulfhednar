
--Define class
Axe = class('Axe')

AXE_SPEED = 500
AXE_POWER = 5
AXE_RELOAD = 0.2
AXE_LIFE = 5

function Axe:initialize(side, x, y, velx, vely, dirx, diry, game, owner)
	self.side = side --This tells us if it was a player spawned bullet, or an enemy spawned bullet

	self.owner = owner --Keep a reference back to the entity that initially shot you

	--Initial position
	self.x = x
	self.y = y

	self.game = game --Reference back to the game state

	if dirx == 0 then dirx = love.math.random()*0.25 - 0.125 end
	if diry == 0 then diry = love.math.random()*0.25 - 0.125 end

	--Direction
	self.dirx = dirx
	self.diry = diry

	--Velocity of player
	self.velx = velx
	self.vely = vely

	self.life = 0

	self.image = getImage("bullets/axe/axe.png")

	self.offx = self.image:getWidth()/2
	self.offy = self.image:getHeight()/2

	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0

	self.power = AXE_POWER
end

function Axe:draw()
	if self.game.debug == true then
		love.graphics.setPointSize(1)
		love.graphics.setColor( 0, 255, 0, 255 )

		love.graphics.point( self.x, self.y)

		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end

	love.graphics.setColor( 255, 255, 255, 255 )

	if self.dirx < 0  then
		love.graphics.draw(self.image, self.x, self.y, -self.life*2, 4, 4, self.offx, self.offy )
	else
		love.graphics.draw(self.image, self.x, self.y, self.life*2, -4, 4, self.offx, self.offy )
	end
end

function Axe:update(dt)
	self.life = self.life + dt

	if self.life > AXE_LIFE then
		self.game:removeGameObject(self)
	end

  local player_speed = math.sqrt(self.velx*self.velx + self.vely*self.vely)
  if player_speed > 0 then
    local dot = self.dirx*(self.velx/player_speed) + self.diry*(self.vely/player_speed)

    if dot > 0 then
      self.x = self.x + self.velx*dot*dt
      self.y = self.y + self.vely*dot*dt
    end
  end

	self.x = self.x + (self.dirx*AXE_SPEED)*dt
	self.y = self.y + (self.diry*AXE_SPEED)*dt

	--TODO: This is a bit wonky
	if BULLETS_COLLIDE and self.game.map:collidePoint(self.x, self.y) then
		self.game:removeGameObject(self)
	end

	--Update collision bounds
	self.collx = self.x - 4
	self.colly = self.y - 6
	self.collwidth = 8
	self.collheight = 12

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
