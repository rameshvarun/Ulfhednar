
--Define class
Poison = class('Poison')

POISON_SPEED = 200

POISON_TARGET_TIME = 2

POISON_LIFE = 10

POISON_POWER = 5

POISON_RELOAD_TIME = 6

function Poison:initialize(x, y, targetx, targety, game, owner)
	
	self.owner = owner --Keep a reference back to the entity that initially shot you
	
	--Initial position
	self.initx = x
	self.inity = y

	self.x = x
	self.y = y
	
	self.shadowx = x
	self.shadowy = y
	
	--Target position
	self.targetx = targetx
	self.targety = targety
	
	self.game = game --Reference back to the game state
	
	self.life = 0
	
	self.angle = 0
	
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
	
	self.image = getImage("bullets/poison/poison" .. math.random(1,2) .. ".png")
	self.offx = self.image:getWidth()/2
	self.offy = self.image:getHeight()/2
	
	self.splat = getImage("bullets/poison/splat.png")
	self.splatoffx = self.splat:getWidth()/2
	self.splatoffy = self.splat:getHeight()/2
	
	self.alpha = 150
	
	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0
	
	self.splat_sound = false
end

function Poison:draw()
	if self.game.debug == true then
		love.graphics.setPointSize(5)
		love.graphics.setColor( 0, 255, 0, 255 )
		
		love.graphics.point( self.x, self.y)
		love.graphics.point( self.targetx, self.targety)
		
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
	
	
	
	if self.life < POISON_TARGET_TIME then
		love.graphics.setColor( 255, 255, 255, 255 )
		love.graphics.draw(self.image, self.x, self.y, self.angle, 2, 2, self.offx, self.offy )
		
		love.graphics.setColor( 255, 255, 255, 30 )
		love.graphics.draw(self.shadow_image, self.shadowx, self.shadowy, 0, 0.4, 0.4, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)
	else
		love.graphics.setColor( 255, 255, 255, self.alpha )
		love.graphics.draw(self.splat, self.x, self.y, 0, 2, 2, self.splatoffx, self.splatoffy )
		
		self.collx = self.x - self.splatoffx*1.4
		self.colly = self.y - self.splatoffy*1.4
		
		self.collwidth = self.splatoffx*2.8
		self.collheight = self.splatoffy*2.8
	end
end

function Poison:update(dt)
	self.life = self.life + dt
	
	if self.life < POISON_TARGET_TIME then
		local a = 16*10
		local A = POISON_TARGET_TIME
		local x = (self.life - A/2)
		
		local height = a* math.pow( x, 2) - a* math.pow( (A/2), 2)
		
		self.oldx = self.x
		self.oldy = self.y
		
		self.shadowx = (self.targetx - self.initx)*(self.life/POISON_TARGET_TIME) + self.initx
		self.shadowy = (self.targety - self.inity)*(self.life/POISON_TARGET_TIME) + self.inity
		
		self.x = self.shadowx
		self.y = self.shadowy + height
		
		self.angle = -math.getAngle( self.oldx, self.oldy, self.x, self.y) - 90
	else
		if self.splat_sound == false then
			self.splat_sound = true
			love.audio.play(splat_sfx)
		end
		
		if self.life > POISON_LIFE + 2 then
			self.game:removeGameObject(self)
		else
			if self.life > POISON_LIFE then
				if self.alpha > 0 then
					self.alpha = self.alpha - 100*dt
				end
				
				if self.alpha < 0 then
					self.alpha = 0
				end
			else
			
				--Attack nearby players
				local players = self.game:getObjectsByType("player")
				for _,player in pairs(players) do
					if collideRect(self.collx, self.colly, self.collx + self.collwidth, self.colly + self.collheight, player.collx, player.colly,  player.collx + player.collwidth, player.colly + player.collheight) then
						player:melee(POISON_POWER)
					end
				end
				
			end
		end
		

	end
end