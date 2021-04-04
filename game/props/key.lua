--Define Class
Key = class('Key')

function Key:initialize(mapobject, game)
	--Spawn position
	self.x = mapobject.x
	self.y = mapobject.y

	--Reference to Game State
	self.game = game
	
	self.image = getImage("props/key.png")
	self.shadow_image = getImage("characters/dropshadow.png") --Drop shadow
	
	self.mapobject = mapobject
	
	--Key starts out as invisible
	self.visible = false
	
	--callbacks
	if not (mapobject.oncollect == nil) then
		self.oncollect = assert( loadstring( mapobject.oncollect ) )
	end
	
	self.time = 0
end

function Key:show()
	self.visible = true
end

function Key:hide()
	self.visible = false
end

function Key:draw()

	if self.visible then
		love.graphics.setColor( 255, 255, 255, 100 )
		love.graphics.draw(self.shadow_image, self.x, self.y, 0, 0.8, 0.8, self.shadow_image:getWidth()/2, self.shadow_image:getHeight()/2)

		love.graphics.setColor( 255, 255, 255, 255 )
	
		love.graphics.draw(self.image, self.x, self.y - 5 + 3*math.sin(self.time*2) , 0, 1, 1, self.image:getWidth()/2, self.image:getHeight() )
	end
end

function Key:update(dt)
	self.time = self.time + dt
	
	if self.visible then
		local players = self.game:getObjectsByType("player")
		for _,player in pairs(players) do
			local diffx = self.x - player.x
			local diffy = self.y - player.y
			local dist = math.norm(diffx, diffy)
			
			if dist < 50 then
				if not (self.oncollect == nil) then
					self.oncollect()
				end
				
				self.game:removeGameObject(self)
			end
		end
	end
end

proptypes['key'] = Key