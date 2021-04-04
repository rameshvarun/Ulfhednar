Fog = class('Fog')

function Fog:initialize(game)

	self.t = 0
	self.t2 = 0
	
	self.game = game
	
	self.visible = true
	
	self.image = getImage("effects/fog.png")
	
	self.speed = 50
end

function Fog:draw()
	if self.visible then
		
		love.graphics.setColor( 255, 255, 255, 60 )
		
		love.graphics.draw( self.image, self.t, 0, 0,  love.graphics.getWidth()/self.image:getWidth(), love.graphics.getHeight()/self.image:getHeight() )
		love.graphics.draw( self.image, self.t - love.graphics.getWidth(), 0, 0,  love.graphics.getWidth()/self.image:getWidth(), love.graphics.getHeight()/self.image:getHeight() )
		
		love.graphics.setColor( 255, 255, 255, 20 )
		
		love.graphics.draw( self.image, self.t2, 0, 0,  love.graphics.getWidth()/self.image:getWidth(), love.graphics.getHeight()/self.image:getHeight() )
		love.graphics.draw( self.image, self.t2 - love.graphics.getWidth(), 0, 0,  love.graphics.getWidth()/self.image:getWidth(), love.graphics.getHeight()/self.image:getHeight() )
	end
end

function Fog:update(dt)
	self.t = self.t + self.speed*dt
	self.t2 = self.t2 + self.speed*dt*3
	
	if self.t > love.graphics.getWidth() then
		self.t = self.t - love.graphics.getWidth()
	end
	
	if self.t2 > love.graphics.getWidth() then
		self.t2 = self.t2 - love.graphics.getWidth()
	end
end

function Rain:start()
	self.visible = true
end

function Rain:stop()
	self.visible = false
end
