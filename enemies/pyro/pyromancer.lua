--Define class
Pyromancer = class('Pyromancer', Enemy)

PYRO_HEALTH_MAX = 25

PYRO_SPEED = 100

PYRO_DIST_OTHER = 55

PYRO_COLLISION_BUFFER_X = 0.7
PYRO_COLLISION_BUFFER_Y = 0.9

PYRO_SCORE = 10

function Pyromancer:initialize(x,y,game, spawner)
	Enemy.initialize(self, x,y,game, spawner)
	
	--AI Behavior
	self.target = nil
	
	--Health
	self.maxhp = PYRO_HEALTH_MAX
	self.hp = self.maxhp
	
	self.image = getImage("enemies/pyro/down1.png") --Enemy Sprite
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
	
	self.direction = "down"
	self.frame = 1
	
	--For bobbing
	self.time = 0
	
	--Spawn with an explosion
	self.game:addGameObject( Explosion:new( self.x, self.y - 30, self.game, {255, 247, 119, 255}, {255, 72, 0}, 0.2 ) )
	
	--Reload timer
	self.reloadtimer = 0
end

function Pyromancer:draw()

	if self.game.debug == true then
		love.graphics.setPointSize(10)
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.point( self.x, self.y)
		
		if not (self.path == nil) then
			for _, point in pairs(self.path) do
				love.graphics.setPointSize(10)
				love.graphics.setColor( 0, 255, 0, 255 )
				love.graphics.point( (point[1] - 0.5)*self.game.map.tilewidth, (point[2] - 0.5)*self.game.map.tileheight )
			end
		end
		
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
	
	love.graphics.setColor( 255, 255, 255, 120)
	love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	
	love.graphics.setColor( 255, 255, 255, 255)
	love.graphics.draw(self.image, self.x, self.y + 3*math.sin(self.time*2) , 0, 1.3, 1.3, self.image:getWidth()/2, self.image:getHeight())
end

function Pyromancer:update(dt)
	self.time = self.time + dt
	
	if self.target == nil then --If you don't have a target
		self:selectTarget(800)
	else --If you have a target
		if math.dist(self.x, self.y, self.target.x, self.target.y) > 100 then
		
			--Get the tile positions of you and the target
			local targetix, targetiy = self.game.map.collisionlayer:getIndex(self.target.x, self.target.y)
			local ix, iy = self.game.map.collisionlayer:getIndex(self.x, self.y)
			
      --If a request has not been sent
			if self.astar_request == nil then
        --Send the request to the a-star thread
        self.astar_request = {}
        self.astar_request.message = table.concat( {ix, iy, targetix ,targetiy}, ",")
        self.astar_request.senderid = self.id
        
        love.thread.getChannel( "astar_requests" ):push( self.astar_request )
      else
        local result = love.thread.getChannel( self.id ):pop()
        if not(result == nil) then
          if result.foundPath then
            self.path = {}
            local points = split( result.points, ";" )
            for _, point in ipairs(points) do
              local coords = split( point, "," )
              table.insert(self.path, { tonumber(coords[1]), tonumber(coords[2]) })
            end
          end
          
          self.astar_request = nil
        end
      end
			
			
			if not( self.path == nil ) and #self.path > 0 then
			
				local tilewidth, tileheight = self.game.map.tilewidth,  self.game.map.tileheight
			
				local diffx = (self.path[1][1] - 0.5)*tilewidth - self.x
				local diffy = (self.path[1][2] - 0.5)*tileheight - self.y
				
				local dist = math.norm(diffx, diffy)
				
				if dist > 5 then
					local movex = diffx / dist
					local movey = diffy / dist
					
					self.x = self.x + movex*dt*PYRO_SPEED
					self.y = self.y + movey*dt*PYRO_SPEED
				else
					table.remove(self.path, 1)
				end
			end
			
		end
		
		self.direction = angletodirection( (self.target.x - self.x), (self.target.y - self.y), self.direction )
		
		self.reloadtimer = self.reloadtimer - dt
		if self.reloadtimer < 0 then
			self.reloadtimer = FIREBALL_RELOAD
			
			if self.direction == "left" then
				table.insert( self.game.gameobjects, Fireball:new(1, self.x - 19, self.y - 50 + 3*math.sin(self.time*2) , -3.14/2, self.game, self.target) )
			end
			
			if self.direction == "up" or  self.direction == "down" then
				local angle = 0
				
				if self.direction == "up" then angle = 3.14 end
				
				if math.random(1, 2) == 1 then
					table.insert( self.game.gameobjects, Fireball:new(1, self.x - 19, self.y - 50 + 3*math.sin(self.time*2) , angle , self.game, self.target) )
				else
					table.insert( self.game.gameobjects, Fireball:new(1, self.x + 23, self.y - 50 + 3*math.sin(self.time*2) , angle , self.game, self.target) )
				end
			end
			
			if self.direction == "right" then
				table.insert( self.game.gameobjects, Fireball:new(1, self.x + 23, self.y - 50 + 3*math.sin(self.time*2) , 3.14/2, self.game, self.target) )
			end
		end
		
		if not (self.target.hp > 0) then
			self.target = nil --If the target has died, move on to someone else
		end
	end
	
	--Don't clump up with other enemies
	local enemies = self.game:getObjectsByType("enemy")
	for _,enemy in pairs(enemies) do
		if (not (enemy == self)) and (self.target == enemy.target) then
			local diffx = self.x - enemy.x
			local diffy = self.y - enemy.y
			local dist = math.norm(diffx, diffy)
			
			if dist < PYRO_DIST_OTHER then
				self.x = enemy.x + (diffx/dist)*PYRO_DIST_OTHER
				self.y = enemy.y + (diffy/dist)*PYRO_DIST_OTHER
			end
		end
	end
	
	--Animation
	self.frame = (math.floor(self.time*3) % 3 ) + 1
	self.image = getImage("enemies/pyro/" .. self.direction .. self.frame .. ".png")
	
	--Calculate collision bounds
	
	if self.direction == "up" or self.direction == "down" then
		self.collwidth = self.image:getWidth()*PYRO_COLLISION_BUFFER_X
		self.collheight =  self.image:getHeight()*PYRO_COLLISION_BUFFER_Y
		
		self.collx = self.x - self.collwidth/2
		self.colly = self.y + 3*math.sin(self.time*2) - self.image:getHeight()/2 - self.collheight/2
	end
	
	if self.direction == "left" then
		self.collwidth = self.image:getWidth()*PYRO_COLLISION_BUFFER_X*0.9
		self.collheight =  self.image:getHeight()*PYRO_COLLISION_BUFFER_Y
		
		self.collx = self.x - self.collwidth/2 - 5
		self.colly = self.y + 3*math.sin(self.time*2) - self.image:getHeight()/2 - self.collheight/2
	end
	
	if self.direction == "right" then
		self.collwidth = self.image:getWidth()*PYRO_COLLISION_BUFFER_X*0.9
		self.collheight =  self.image:getHeight()*PYRO_COLLISION_BUFFER_Y
		
		self.collx = self.x - self.collwidth/2 + 5
		self.colly = self.y + 3*math.sin(self.time*2) - self.image:getHeight()/2 - self.collheight/2
	end
	
	--Die
	if self:handleDeath(PYRO_SCORE) then
		self.game:shakeCamera(0.2, 1)
		
		self.game:addGameObject( Explosion:new(self.x, self.y - 30, self.game, {255, 247, 119}, {255, 72, 0} ) )
		
		drop(self.x, self.y, self.game)
		
		self.source = love.audio.newSource(explosion1)
		self.source:setVolume(0.2)
		self.source:play()
	end
	
	
end

enemytypes['pyromancer'] = Pyromancer
enemytypes['pyro'] = Pyromancer