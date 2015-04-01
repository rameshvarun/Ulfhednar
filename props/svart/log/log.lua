Log = class('Log')

LOG_IMAGES = {
	"props/svart/log/log1.png",
	"props/svart/log/log2.png",
	"props/svart/log/log3.png"
}

function Log:initialize(mapobject, game)
	--References
	self.game = game
	self.mapobject = mapobject

	--Visual image
	self.image_file = LOG_IMAGES[tonumber(mapobject.logtype)]
	self.image = getImage(self.image_file)
	self.layer = -1

	--Log scaling
	if mapobject.scale ~= nil then
		self.scale = mapobject.scale
	else
		self.scale = 1
	end



	--Create phsyics body
	self.body = love.physics.newBody(game.world, mapobject.x + mapobject.width/2, mapobject.y + mapobject.height/2, mapobject.initialtype)
	self.shape = love.physics.newRectangleShape(self.scale* self.image:getWidth(), self.scale*self.image:getHeight() )
	self.fixture = love.physics.newFixture(self.body, self.shape, 0.3)

	--Damping to prevent infinite acceleration
	self.body:setLinearDamping( 0.1 )
	self.body:setAngularDamping( 0.1 )

	--Initial rotation
	if mapobject.rotation ~= nil then
		self.body:setAngle(tonumber(mapobject.rotation))
	end

	--Log initial velocity
	local vx, vy = 0, 0
	if mapobject.vx ~= nil then vx = tonumber(mapobject.vx) end
	if mapobject.vy ~= nil then vy = tonumber(mapobject.vy) end
	self.body:setLinearVelocity(vx, vy)

	--Ability to set linear damping
	if mapobject.lineardamping ~= nil then
		self.body:setLinearDamping( tonumber(mapobject.lineardamping) )
	end

end

function Log:draw()
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.draw(self.image, self.body:getX(), self.body:getY(), self.body:getAngle(), self.scale, self.scale, self.image:getWidth()/2, self.image:getHeight()/2)
end

function Log:update(dt)
end

function Log:setBodyType(type)
	self.body:setType(type)
end

proptypes['log'] = Log