
--Define class
Bone = class('Bone')

BONE_SPEED = 200
BONE_POWER = 5
BONE_LIFE = 5

function Bone:initialize(side, x, y, dirx, diry, game, owner)
	self.side = side --This tells us if it was a player spawned bullet, or an enemy spawned bullet
	
	self.owner = owner --Keep a reference back to the entity that initially shot you
	
	--Initial position
	self.x = x
	self.y = y
	
	self.game = game --Reference back to the game state
	
	--Direction
	self.dirx = dirx
	self.diry = diry
	
	--Velocity of player
	self.velx = velx
	self.vely = vely
	
	self.life = 0
	
	self.image = getImage("bullets/bone/bone1.png")
	
	self.offx = self.image:getWidth()/2
	self.offy = self.image:getHeight()/2
	
	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0
	
	self.power = BONE_POWER
end

function Bone:draw()
	if self.game.debug == true then
		love.graphics.setPointSize(1)
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.point( self.x, self.y)
		
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
	
	love.graphics.setColor( 255, 255, 255, 255 )
	
	love.graphics.draw(self.image, self.x, self.y, -self.life*2, 0.7, 0.7, self.offx, self.offy )
end

function Bone:update(dt)
	self.life = self.life + dt
	
	if self.life > BONE_LIFE then
		self.game:removeGameObject(self)
	end

	self.x = self.x + ( self.dirx*BONE_SPEED )*dt
	self.y = self.y + ( self.diry*BONE_SPEED )*dt
	
	--TODO: This is a bit wonky
	if self.game.map:collidePoint(self.x, self.y) then
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