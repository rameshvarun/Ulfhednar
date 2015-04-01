--Define class
DarkElf = class('DarkElf', Enemy)

DARKELF_HP_MAX = 15
DARKELF_SCORE = 5
DARKELF_RELOAD_TIME = 3

DARKELF_SPRITE_WIDTH = 44
DARKELF_SPRITE_HEIGHT = 64

function DarkElf:initialize(x,y,game, spawner)
	Enemy.initialize(self, x,y,game, spawner) --Superclass constructor

	self.image = getImage("enemies/darkelf/darkelf.png") --Enemy Sprite
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow

	--Health
	self.maxhp = DARKELF_HP_MAX
	self.hp = self.maxhp

	--Shooting
	self.reloadtimer = 0

	--Default draw direction
	self.direction = "up"

	--Direction to image mapping
	self.DIRECTION_TO_QUAD = {
		up = love.graphics.newQuad(0, 0, DARKELF_SPRITE_WIDTH, DARKELF_SPRITE_HEIGHT, self.image:getWidth(), self.image:getHeight()),
		down = love.graphics.newQuad(0, DARKELF_SPRITE_HEIGHT*2, DARKELF_SPRITE_WIDTH, DARKELF_SPRITE_HEIGHT, self.image:getWidth(), self.image:getHeight()),
		left = love.graphics.newQuad(0, DARKELF_SPRITE_HEIGHT, DARKELF_SPRITE_WIDTH, DARKELF_SPRITE_HEIGHT, self.image:getWidth(), self.image:getHeight()),
		right = love.graphics.newQuad(0, DARKELF_SPRITE_HEIGHT*3, DARKELF_SPRITE_WIDTH, DARKELF_SPRITE_HEIGHT, self.image:getWidth(), self.image:getHeight())
	}
end

function DarkElf:draw()
	love.graphics.setColor( 255, 255, 255 )

	love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	love.graphics.draw(self.image, self.DIRECTION_TO_QUAD[self.direction], self.x, self.y, 0, 1, 1, self.image:getWidth()/2, DARKELF_SPRITE_HEIGHT)

	Enemy.draw(self)
end

function DarkElf:update(dt)
	--Update collision bounds
	self.collx = self.x - self.image:getWidth()/2
	self.colly = self.y - DARKELF_SPRITE_HEIGHT
	self.collwidth = self.image:getWidth()
	self.collheight = DARKELF_SPRITE_HEIGHT

	if self.target == nil then
		self:selectTarget(800)
	else
		if self.reloadtimer < DARKELF_RELOAD_TIME then
			self.reloadtimer = self.reloadtimer + dt
		else
			self.game:addGameObject( Arrow:new(1, self.x, self.y, math.getAngle(self.x, self.y, self.target.x, self.target.y - 15),self.game, self) )
			self.reloadtimer = 0
		end

		self.direction = angletodirection( (self.target.x - self.x), (self.target.y - self.y), self.direction )
	end

	--Death
	if self:handleDeath(DARKELF_SCORE) then
		self.game:shakeCamera(0.2, 1)
		
		self.game:addGameObject( Explosion:new(self.x, self.y - DARKELF_SPRITE_HEIGHT/2, self.game,  {255, 0, 0}) )
		
		self.source = love.audio.newSource(explosion1)
		self.source:setVolume(0.2)
		self.source:play()
	end
end

enemytypes['darkelf'] = DarkElf