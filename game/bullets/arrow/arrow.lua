
--Define class
Arrow = class('Arrow', Bullet)

ARROW_SPEED = 400
ARROW_POWER = 5
ARROW_LIFE = 6

function Arrow:initialize(side, x, y, angle, game, owner)
	Bullet.initialize(self, {
		side = side,
		owner = owner,
		game = game,
		x = x,
		y = y,
		power = ARROW_POWER,
		life_max = ARROW_LIFE
	})

	--Direction
	self.angle = angle

	--Visuals
	self.image = getImage("bullets/arrow/arrow.png")
end

function Arrow:draw()
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.draw(self.image, self.x, self.y, -self.angle, 1, 1, self.image:getWidth()/2, self.image:getHeight()/2 )

	Bullet.draw(self)
end

function Arrow:update(dt)
	self.x = self.x + dt*ARROW_SPEED*math.sin(self.angle)
	self.y = self.y + dt*ARROW_SPEED*math.cos(self.angle)

	if BULLETS_COLLIDE and self.game.map:collidePoint(self.x, self.y) then
		self.game:removeGameObject(self)
	end

	--Update collision bounds
	self.collx = self.x - 4
	self.colly = self.y - 6
	self.collwidth = 8
	self.collheight = 12

	Bullet.update(self, dt)

	self:collideVictims()
end