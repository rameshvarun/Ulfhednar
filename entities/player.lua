PLAYER_COLORS = { {200, 200, 200}, {39, 173, 227}, {238, 54, 138}, {176, 209, 54}, {10, 10, 10} }

--Base class player
Player = class('Player')

--Static properties
Player.static.MOVE_SPEED = 250

Player.static.COLLISION_WIDTH = 50*0.3
Player.static.COLLISION_HEIGHT = 20*0.4

MAX_HEALTH_PLAYER = {20}
HIT_TIME = 2

CURSOR_IMAGE = getImage("menu/cursor.png")
CURSOR_SPEED = 10

function Player:initialize()
	self.character = 1 --Store the character type in this value

	self.id = generateID()

	self.type = "player" --This value is to let other objects know what type of object it is

	self.x = 0
	self.y = 0

	print ("Created new " .. self.controltype .. " player of id " .. self.id)

	self.reloadtimer = 0

	self.direction = "down"

	self.shadow_image = getImage("characters/dropshadow.png")

	self.maxhp = MAX_HEALTH_PLAYER[self.character]
	self.hp = self.maxhp

	self.hittimer = 0 --This is to ensure that, once you are hit, you are invincible for a couple seconds

	--For fire rate
	self.reloaddivider = 1
	self.dividertimer = 0

	--Particle effects for shield
	self.p = love.graphics.newParticleSystem( getImage("enemies/ghost/fire.png") , 1000)
	self.p:setEmissionRate(100)
	self.p:setSpeed(300, 400)
	self.p:setSizes(3,2)
	self.p:setColors(255, 255, 255, 50, 58, 128, 255, 50)
	self.p:setParticleLifetime(.25)
	self.p:setSpread(360)
	self.p:setRadialAcceleration(-4000)
	self.p:setOffset(self.x,self.y)

	--Shielding variables
	self.shieldtimer = 0
	self.hittable = true

	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0

	--Score keeping
	self.score = 0

	--Cursor position (used for menus)
	self.cursor_x = love.graphics.getWidth()/2
	self.cursor_y = love.graphics.getHeight()/2

	self.cursor_down = false
end

function Player:drawCursor()
	local color = PLAYER_COLORS[self.index]
	love.graphics.setColor( color[1] , color[2], color[3], 255 )
	love.graphics.draw(CURSOR_IMAGE, self.cursor_x, self.cursor_y, 0, 1.4, 1.4)

	love.graphics.setFont(caesardressing30)
	love.graphics.printf( "P" .. self.index, self.cursor_x - 5, self.cursor_y - 40, 25, "center")
end

function Player:updateCursor(dt)
	--Get movement vector based off of the input
	local movex, movey = self:movement()
	self.cursor_x = self.cursor_x + CURSOR_SPEED*movex
	self.cursor_y = self.cursor_y + CURSOR_SPEED*movey

	--Clamp cursor onto screen
	self.cursor_x = math.clamp(self.cursor_x, 0, love.graphics.getWidth())
	self.cursor_y = math.clamp(self.cursor_y, 0, love.graphics.getHeight())
end

function Player:cursorReleased()
	local cursor_released = (not self:attack()) and (self.cursor_down)

	self.cursor_down = self:attack()
	return cursor_released
end

function Player:useColor()
	local color = PLAYER_COLORS[1]
	if self.index ~= nil then color = PLAYER_COLORS[self.index] end
	love.graphics.setColor( color[1] , color[2], color[3], 255 )
end

function Player:draw()

	if self:isAlive() then
		love.graphics.setColor( 255, 255, 255, 180 )
		love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)

		if self.game.debug == true then
			--Point represents center (feet) of character
			love.graphics.setPointSize(10)
			love.graphics.setColor( 0, 255, 0, 255 )
			love.graphics.point( self.x, self.y )

			love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)

			--This is the collision rectangle
			love.graphics.rectangle("line", self.x- Player.COLLISION_WIDTH /2, self.y- Player.COLLISION_HEIGHT/2, Player.COLLISION_WIDTH, Player.COLLISION_HEIGHT)
		end

		self:useColor()
		if not (self.image == nil) then
			if self.hittimer < 0 or math.floor(self.hittimer*6) % 2 == 0 then
				love.graphics.draw(self.image, self.x, self.y, 0, 2, 2, self.image:getWidth()/2, self.image:getHeight())
			end
		end

		--Draw Player Tag
		love.graphics.setFont(caesardressing30)
		love.graphics.printf( "P" .. self.index, self.x - 15, self.y - 100, 25, "center")

		--Draw health bar
		love.graphics.setColor( 255, 0, 0, 255 )
		love.graphics.rectangle("fill", self.x- 25, self.y- 60, 50, 5)

		love.graphics.setColor( 0, 255, 0, 255 )
		love.graphics.rectangle("fill", self.x- 25, self.y- 60, (self.hp/self.maxhp)*50, 5)

		love.graphics.draw( self.p, 0, 0)
	end
end

function Player:explode()
	self.game:addGameObject( Explosion:new(self.x, self.y, self.game, {255, 0, 0} ) )

	self.game:addGameObject( Explosion:new(self.x + 10, self.y, self.game, {255, 0, 0} ) )
	self.game:addGameObject( Explosion:new(self.x - 10, self.y, self.game, {255, 0, 0} ) )

	self.game:addGameObject( Explosion:new(self.x, self.y + 10, self.game, {255, 0, 0} ) )
	self.game:addGameObject( Explosion:new(self.x, self.y - 10, self.game, {255, 0, 0} ) )

	self.source = love.audio.newSource(explosion1)
	self.source:setVolume(0.2)
	self.source:play()
end

--This function is called if the player is attacked by a melee character
function Player:melee(power)
	if self.hittable == true then
		if self.hittimer < 0 then
			self.hp = self.hp - power

			self.hittimer = HIT_TIME

			self.game:shakeCamera(0.2, 2)

			hurt1_sfx:stop()
			hurt1_sfx:play()

			if not self:isAlive() then self:explode() end
		end
	end
end

--This function is called if the player gets shot.
function Player:shoot(bullet)

	if collideRect(self.collx, self.colly, self.collx + self.collwidth, self.colly + self.collheight, bullet.collx, bullet.colly,  bullet.collx + bullet.collwidth, bullet.colly + bullet.collheight) then
		if self.hittable == true then
			if self.hittimer < 0 then
				self.hp = self.hp - bullet.power

				self.hittimer = HIT_TIME

				self.game:shakeCamera(0.2, 2)

				if not self:isAlive() then self:explode() end
			end
		end

		return true
	end

	return false
end

function Player:revive(new_x, new_y)
	if self:isAlive() == false then
    self.hp = self.maxhp / 2
    self.x = new_x
    self.y = new_y
	end
end

function Player:isAlive()
	if self.hp > 0 then
		return true
	else
		return false
	end
end

function Player:update(dt)

  self.hittimer = self.hittimer - dt
  --Vibrate if hit
  if self.controltype == "gamepad" and self.joystick:isVibrationSupported() then
    if self.hittimer > HIT_TIME - 0.2 then
      self.joystick:setVibration( 0.8, 0.8)
    else
      self.joystick:setVibration( 0, 0)
    end
  end

	if self.hp > 0 then

		--Get movement vector based off of the input
		local movex, movey = self:movement()

		--Figure out the direction of movement (used to determine what sprite will be loaded)
		self.direction = angletodirection(movex, movey, self.direction)

		--Fire rate
		if self.dividertimer > 0 then
			self.dividertimer = self.dividertimer - dt
		end
		if self.dividertimer <= 0 then
			self.reloaddivider = 1
		end

		self.velx = movex*Player.MOVE_SPEED
		self.vely = movey*Player.MOVE_SPEED

		--Get the target location
		local newx = self.x + self.velx*dt
		local newy = self.y + self.vely*dt

		--Use the target location to calculate where the collided position should be
		self.x, self.y = self.game.map:collideRectangle(self.x, self.y, Player.COLLISION_WIDTH, Player.COLLISION_HEIGHT, newx, newy)

		--If this character type 1, then figure out what sprite should be displayed
		if self.character == 1 then

			self.RELOAD_TIME = AXE_RELOAD

			if self.reloadtimer > AXE_RELOAD/(2*self.reloaddivider) then
				self.axe = "thrown"
			else
				self.axe = "axe"
			end

			self.image = getImage("characters/1/" .. self.direction .. "still" .. self.axe .. ".png")
		end

		--Bullet firing
		if self.reloadtimer > 0 then
			self.reloadtimer = self.reloadtimer - dt
		else
			if self:attack() then
				--Create the four bullets and add them to the game objects list
				if self.character == 1 then --Character 1 throws axes
					table.insert( self.game.gameobjects, Axe:new(0, self.x + 20, self.y - 32, self.velx, self.vely, 1, 0, self.game, self) ) --Right
					table.insert( self.game.gameobjects, Axe:new(0, self.x - 20, self.y - 32, self.velx, self.vely,  -1, 0, self.game, self) ) --Left
					table.insert( self.game.gameobjects, Axe:new(0, self.x, self.y - 32, self.velx, self.vely,  0, -1, self.game, self) ) --Up
					table.insert( self.game.gameobjects, Axe:new(0, self.x + 4, self.y - 18, self.velx, self.vely,  0, 1, self.game, self) ) --Down
				end

				self.reloadtimer = self.RELOAD_TIME/self.reloaddivider --Reset reload timer
			else
        if self:special() then
          --Create the four bullets and add them to the game objects list
          if self.character == 1 then --Character 1 throws axes
            table.insert( self.game.gameobjects, Axe:new(0, self.x + 20, self.y - 32, self.velx, self.vely, 0.7, 0.7, self.game, self) ) --Right
            table.insert( self.game.gameobjects, Axe:new(0, self.x - 20, self.y - 32, self.velx, self.vely,  0.7, -0.7, self.game, self) ) --Left
            table.insert( self.game.gameobjects, Axe:new(0, self.x, self.y - 32, self.velx, self.vely,  -0.7, 0.7, self.game, self) ) --Up
            table.insert( self.game.gameobjects, Axe:new(0, self.x + 4, self.y - 18, self.velx, self.vely,  -0.7, -0.7, self.game, self) ) --Down
          end

          self.reloadtimer = self.RELOAD_TIME/self.reloaddivider --Reset reload timer
        end
      end
		end



		--Shielding
		if self.shieldtimer > 0 then
			self.hittable = false
			self.shieldtimer = self.shieldtimer - dt
			self.p:start()
			self.p:setPosition(self.x-30, self.y-50)
			self.p:update(dt)
		end
		if self.shieldtimer <= 0 then
			self.hittable = true
			self.p:reset()
			self.p:stop()
		end

		self.collwidth = 30
		self.collheight = 40
		self.collx = self.x - self.collwidth/2
		self.colly = self.y - self.collheight
	else
		self.collx = 0
		self.colly = 0
		self.collwidth = 0
		self.collheight = 0
	end
end
