Bat = class('Bat', Enemy)

BAT_HP_MAX = 75
BAT_SCORE = 5
BAT_SPEED = 300
BAT_POWER= 2.5
BAT_ROTATION=21


function Bat:initialize(x, y, game, spawner)
	Enemy.initialize(self, x, y, game, spawner)
	self.image = getImage("enemies/bat/bat.png") --Enemy Sprite
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
	
	--Health
	self.maxhp = BAT_HP_MAX
	self.hp = self.maxhp

	--Time
	self.time = 0

	self.frame_width = 32
	self.frame_height = self.image:getHeight()
	self.frames = self.image:getWidth() / self.frame_width
	self.scale = 3

	self.quads = _.map(_.range(self.frames):to_array(), function(i)
		return love.graphics.newQuad((i - 1) * self.frame_width, 0, self.frame_width, self.frame_height, self.image:getWidth(), self.image:getHeight())
	end)
end

function Bat:draw()
	love.graphics.setColor( 255, 255, 255 )

	local frame = math.floor(self.time / 0.2) % self.frames

	love.graphics.draw(self.shadow_image, self.x, self.y + 15, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	love.graphics.draw(self.image, self.quads[frame  + 1],self.x, self.y, 0, self.scale, self.scale, self.frame_width/2, self.frame_height)
	Enemy.draw(self)
	
	
	--Health bar?
	--love.graphics.setColor( 255, 0, 0, 255 )
	--love.graphics.rectangle("fill", self.x- 25, self.y- 60, 50, 5)	
	--love.graphics.setColor( 0, 255, 0, 255 )
	--love.graphics.rectangle("fill", self.x- 25, self.y- 60, (self.hp/self.maxhp)*50, 5)
		
end

function Bat:update(dt)
	--Increment global time count
	self.time = self.time + dt

	if self.target == nil then
		self.pass = 0 --bat has not passed target
		
		if self:selectTarget(800) then
			self.state = "approach"
		end
	else

		--Distance and angle frm player
		local dist = math.dist( self.x, self.y, self.target.x, self.target.y )
		local theta = math.getAngle( self.x, self.y, self.target.x, self.target.y )

		 --bat approaches target
		if self.state == "approach" then
			dist = dist - dt*BAT_SPEED
			self.x = self.target.x - dist*math.sin(theta)
			self.y = self.target.y - dist*math.cos(theta)
			if dist < 350 then --once bat is close enough, it breaks approach and orbits
				self.state = "orbit"
			end
		end

		--bat decaying orbit
		if self.state == "orbit" then
			theta = theta + dt*2
			dist= dist - dt*(BAT_ROTATION)
			self.x = self.target.x - dist*math.sin(theta)
			self.y = self.target.y - dist*math.cos(theta)
			if dist < 200 then --if bat gets close enough, charges
				self.state = "charge"
			end
			if dist > 500 then --if the bat gets too far away, it will re-initiate approach
				self.state = "approach"
			end
		end

		--Charging state
		if self.state == "charge" then
			local tracker = dist
			tracker = tracker - dt*BAT_SPEED*3
			if tracker > 0 and tracker < 350 and self.pass~=1 then --bat charges
				dist = dist - dt*BAT_SPEED*3
				self.x = self.target.x - dist*math.sin(theta)
				self.y = self.target.y - dist*math.cos(theta)
			elseif tracker <= 0 and self.pass~=1 then --this ensures that bat passes target in most cases
				dist = dist - dt*BAT_SPEED*3
				self.x = self.target.x - 2*dist*math.sin(theta)
				self.y = self.target.y - 2*dist*math.cos(theta)
				self.pass = 1
			elseif tracker > 325 then --bat has finished charge and is breaking off
				tracker = 0
				self.state = "orbit"
				self.pass = 0
			else --bat continues past target
				dist = dist + dt*BAT_SPEED*3
				self.x = self.target.x - (dist*math.sin(theta))
				self.y = self.target.y - (dist*math.cos(theta))
			end
		end
		
		if not (self.target.hp > 0) then
			self.target = nil --If the target has died, move on to someone else
		end
	end

	--Collision bounds
	self.collx = self.x - self.scale*self.frame_width/2
	self.colly = self.y - self.scale*self.frame_height
	self.collwidth = self.scale*self.frame_width
	self.collheight = self.scale*self.frame_height
	
	--Attack nearby players
	self:meleeNearby(20, BAT_POWER)

	--On Death shake camera and explode
	if self:handleDeath(BAT_SCORE) then
		self.game:shakeCamera(0.2, 1)
		
		self.game:addGameObject( Explosion:new(self.x, self.y - self.image:getHeight()/2, self.game,  {255, 0, 0}) )

		drop(self.x, self.y, self.game)
		
		self.source = love.audio.newSource(explosion1)
		self.source:setVolume(0.2)
		self.source:play()
	end

end

enemytypes['bat'] = Bat