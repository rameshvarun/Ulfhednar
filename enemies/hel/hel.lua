--Define class
Hel = class('Hel', Enemy)

HEL_HEALTH_MAX = 500

BONE_RELOAD_TIME = 0.3
HEL_ROTATE_SPEED = 0.6

HEL_SPIRAL_TIME = 8
HEL_CIRCLE_TIME = 3
HEL_TRANSITION_TIME = 1

HEL_TELEPORT_TIME = 3

HEL_DEATH_TIME = 4
HEL_DEATH_EXPLOSIONS = 20

function Hel:initialize(x,y,game, spawner)
	Enemy.initialize(self, x,y,game, spawner)
	
	print("Spawned Hell")

	--For bobbing
	self.time = 0
	
	--AI Behavior
	self.target = nil
	self.mode = "transition"
	
	--Health
	self.maxhp = HEL_HEALTH_MAX*counttable( self.game.players )
	self.hp = self.maxhp
	
	self.image = getImage("enemies/hel/hel.png") --Enemy Sprite
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
	
	--Tell the game state that this is a boss
	self.game.boss = self
	
	self.game:showText("Hel\nDaughter of Loki", 5)
	
	self.reloadtime = 0 --Reload timer for throwing bones
	
	self.poisonreloadtime = 0 --Reload timer for poison
	
	self.modetime = 0 --Time spent in the current mode
	
	self.alpha = 0 --Controls transparency of sprite
	
	--Velocity - controls the boss bouncing around
	self.velx = 50
	self.vely = 50
	
	self.red = 0
	
	--Movement bounds
	self.right = self.spawner.x + 600
	self.left = self.spawner.x - 600
	self.top = self.spawner.y + 400
	self.bottom = self.spawner.y - 400
	
	setMusic("boss.mp3")
end

function Hel:shoot(bullet)
	if self.alpha > 30 then
		local result = Enemy.shoot(self, bullet)
		
		if result then
			self.red = 100
		end
		
		return result
	end
	
	return false
end

function Hel:draw()

	if self.game.debug == true then
		love.graphics.setPointSize(10)
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.point( self.x, self.y)
		

		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
	
	love.graphics.setColor( 255, 255, 255, self.alpha*0.5)
	love.graphics.draw(self.shadow_image, self.x, self.y, 0, 1.5, 1.5, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	
	love.graphics.setColor( 255, 255 - self.red, 255 - self.red, self.alpha)
	love.graphics.draw(self.image, self.x, self.y - 20 + 5*math.sin(self.time*2) , 0, 3, 3, self.image:getWidth()/2, self.image:getHeight())
end

function Hel:update(dt)
	
	--Keep track of time from spawn
	self.time = self.time + dt
	
	self.modetime = self.modetime + dt
	
	if self.red > 0 then
		self.red = self.red - dt*300
	else
		self.red = 0
	end
	
	--Update collision bounds
	self.collwidth = self.image:getWidth()*3*PYRO_COLLISION_BUFFER_X
	self.collheight =  self.image:getHeight()*3*PYRO_COLLISION_BUFFER_Y
	
	self.collx = self.x - self.collwidth/2 + 5
	self.colly = self.y - 20 + 5*math.sin(self.time*2) - self.image:getHeight()*1.5 - self.collheight/2
	
	--Shoot 4 streams in a rotating spiral
	if self.mode == "spiral" then
		if self.reloadtime > 0 then
			self.reloadtime = self.reloadtime - dt
		else
			self.reloadtime = BONE_RELOAD_TIME
			
			local centerx = self.x + 80
			local centery = self.y - 180
			
			table.insert( self.game.gameobjects, Bone:new(1, centerx, centery, math.sin(self.time*HEL_ROTATE_SPEED), math.cos(self.time*HEL_ROTATE_SPEED), self.game, self) )
			table.insert( self.game.gameobjects, Bone:new(1, centerx, centery, math.sin(self.time*HEL_ROTATE_SPEED + math.pi/2), math.cos(self.time*HEL_ROTATE_SPEED + math.pi/2), self.game, self) )
			
			table.insert( self.game.gameobjects, Bone:new(1, centerx, centery, math.sin(self.time*HEL_ROTATE_SPEED + math.pi), math.cos(self.time*HEL_ROTATE_SPEED + math.pi), self.game, self) )
			table.insert( self.game.gameobjects, Bone:new(1, centerx, centery, math.sin(self.time*HEL_ROTATE_SPEED + math.pi*1.5), math.cos(self.time*HEL_ROTATE_SPEED + math.pi*1.5), self.game, self) )
		end
		
		if self.modetime > HEL_SPIRAL_TIME then
			self.modetime = 0
			self.mode = "transition"
		end
	end
	
	--Shoot bones outwards in a circle
	if self.mode == "circle" then
		if self.reloadtime > 0 then
			self.reloadtime = self.reloadtime - dt
		else
			self.reloadtime = BONE_RELOAD_TIME
			
			local centerx = self.x + 80
			local centery = self.y - 180
			
			local NUM_BONES = 10
			
			for i=1, NUM_BONES do
				local angle = (i/NUM_BONES)*math.pi*2
				local dirx = math.sin( angle )
				local diry = math.cos( angle )
				
				table.insert( self.game.gameobjects, Bone:new(1, centerx, centery, dirx, diry, self.game, self) )
			end
		end
		
		if self.modetime > HEL_CIRCLE_TIME then
			self.modetime = 0
			self.mode = "transition"
		end
	end
	
	--Spawn minions and then hide
	if self.mode == "minions" then
		if counttable( self.game.spawners["MinionSpawner"].children ) < 1 then
			self.modetime = 0
			self.mode = "transition"
		end
		
		if self.alpha > 20 then
			self.alpha = self.alpha - dt*100
		else
			self.alpha = 20
		end
	
	--Spawn minions and then hide
	elseif self.mode == "teleport" then
		if self.modetime < HEL_TELEPORT_TIME/2 then
			if self.alpha > 0 then
				self.alpha = self.alpha - dt*200
			end
			
			if self.alpha < 0 then
				self.alpha = 0
			end
		else
			self.x = math.random(self.left, self.right)
			self.y = math.random(self.bottom, self.top)
		end
	
		if self.modetime > HEL_TELEPORT_TIME then
			self.modetime = 0
			self.mode = "transition"
		end
	else
		if self.hp > 0 then
			if self.alpha < 255 then
				self.alpha = self.alpha + dt*100
			else
				self.alpha = 255
			end
		end
	end
	
	if self.mode == "death" then
		if self.modetime > HEL_DEATH_TIME then
			self.game.levelresult = 1
			self.game:removeGameObject(self)
			
			if not (self.spawner == nil) then
				self.spawner:removeChild(self)
			end
		else
			self.game.spawners["MinionSpawner"]:killall()
			
			self.alpha = self.alpha - (255/HEL_DEATH_TIME)*dt
			
			if self.num_explosions < HEL_DEATH_EXPLOSIONS * ( self.modetime / HEL_DEATH_TIME ) then
				local exp_x = math.random(self.collx, self.collx + self.collwidth)
				local exp_y = math.random(self.colly, self.colly + self.collheight)
				
				self.game:addGameObject( Explosion:new(exp_x, exp_y, self.game, {255, 247, 119}, {255, 72, 0}) )
				
				self.num_explosions = self.num_explosions + 1
				
				self.source = love.audio.newSource(explosion1)
				self.source:setVolume(0.2)
				self.source:play()
			end
		end
	else
		if self.hp <= 0 then
			self.modetime = 0
			self.mode = "death"
			
			self.game.boss = nil
			
			self.game:shakeCamera(HEL_DEATH_TIME, 10)
			
			self.num_explosions = 0
			
			self.alpha = 255
		end
	end
	
	if self.poisonreloadtime > POISON_RELOAD_TIME and self.hp > 0 and self.alpha > 200 then
		local centerx = self.x - 60
		local centery = self.y - 180
			
		local target_x = math.random(self.left, self.right)
		local target_y = math.random(self.bottom, self.top)
			
		self.game:addGameObject( Poison:new( centerx , centery, target_x, target_y, self.game, self) )

		self.poisonreloadtime = 0
	else
		self.poisonreloadtime = self.poisonreloadtime + dt
	end
	
	--Transition phase between other attacks
	if self.mode == "transition" then
		if self.modetime > HEL_TRANSITION_TIME then
			self.modetime = 0
			
			local choices = { 'spiral', 'minions', 'circle', 'teleport'}
			
			self.mode = choices[ math.random( #choices ) ]
			
			if self.mode == 'minions' then
				self.game.spawners["MinionSpawner"]:spawn()
			end
		end
	else
		if self.hp > 0 then
			self.x = self.x + self.velx*dt
			self.y = self.y + self.vely*dt
			
			if self.x > self.right then
				self.velx = -self.velx
			end
			if self.x < self.left then
				self.velx = -self.velx
			end
			
			if self.y > self.top then
				self.vely = -self.vely
			end
			if self.y < self.bottom then
				self.vely = -self.vely
			end
		end
	end
end

enemytypes['hel'] = Hel