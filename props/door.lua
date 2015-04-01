--Define Class
Door = class('Door')

function Door:initialize(mapobject, game)
	--Spawn position
	self.x = mapobject.x
	self.y = mapobject.y + mapobject.height

	--Reference to Game State
	self.game = game
	
	self.closed = getImage("props/doorclosed.png") --Closed Door Image
	self.open = getImage("props/dooropen.png") --Open Door Image
	
	self.mapobject = mapobject
	
	--Door starts out as closed
	self.isclosed = true
	self.mapobject.type = "collision"
end

function Door:close()
	self.isclosed = true
	self.mapobject.type = "collision"
	
	self.game.map:updateCollision()
	
	love.audio.play(door_sfx)
end

function Door:unlock()
	self.isclosed = false
	self.mapobject.type = "door"
	
	self.game.map:updateCollision()
	
	love.audio.play(door_sfx)
end

function Door:toggle()
	if self.isclosed then
		self:unlock()
	else
		self:close()
	end
end

function Door:draw()

	love.graphics.setColor( 255, 255, 255, 255 )
	
	if self.isclosed then
		love.graphics.draw(self.closed, self.x, self.y  , 0, 1, 1, 0, self.closed:getHeight())
	else
		love.graphics.draw(self.open, self.x, self.y  , 0, 1, 1, 0, self.closed:getHeight())
	end
end

function Door:update(dt)
end

proptypes['door'] = Door