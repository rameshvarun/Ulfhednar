Vortex = class('Vortex')

VORTEX_LEVELS = 8
INITIAL_SCALE = 1
SCALE_PER_LEVEL = 1.5

INITIAL_ROTATE_SPEED = 0.2
SPEED_PER_LEVEL = 1.3

function Vortex:initialize(mapobject, game)
	--References
	self.game = game
	self.mapobject = mapobject

	self.x = mapobject.x
	self.y = mapobject.y

	self.layer = -2

	--Visual image
	self.image = getImage("props/svart/vortex/clouds.png")

	--Below castle
	self.castle_below = getImage("props/svart/vortex/castle_below.png")

	self.time = 0
end

function Vortex:draw()
	love.graphics.setColor( 255, 255, 255, 255 )

	for i=0,VORTEX_LEVELS do
		local scale = INITIAL_SCALE * math.pow(SCALE_PER_LEVEL, i - 1)
		local speed = INITIAL_ROTATE_SPEED * math.pow(SPEED_PER_LEVEL, i - 1)
		local angle = speed * self.time

		local parallax_mult = 0.1*(VORTEX_LEVELS - i)
		local parallax_x = self.x - cam.x
		local parallax_y = self.y - cam.y

		if i == 0 then
			love.graphics.draw(self.castle_below, self.x - 0.8*parallax_x, self.y - 0.8*parallax_y, 0, 2,2, self.castle_below:getWidth()/2, self.castle_below:getHeight()/2)
		else
			love.graphics.draw(self.image, self.x - parallax_mult*parallax_x, self.y - parallax_mult*parallax_y, angle, scale, scale, self.image:getWidth()/2, self.image:getHeight()/2)
		end
	end
end

function Vortex:update(dt)
	self.time = self.time + dt

	--Iterate through all bodues
	_.each(self.game.world:getBodyList(), function( body )
		--Only operate on dynamic bodies
		if body:getType() == "dynamic" then
			local delta_x = self.x - body:getX()
			local delta_y = self.y - body:getY()
			RADIAL_FORCE_MULTIPLIER = 0.0005
			--body:applyForce( RADIAL_FORCE_MULTIPLIER*math.sin(delta_x)*math.abs(delta_x), RADIAL_FORCE_MULTIPLIER*math.sin(delta_y)*math.abs(delta_y))
			body:applyForce( RADIAL_FORCE_MULTIPLIER*math.sign(delta_x)*math.pow(delta_x, 2), RADIAL_FORCE_MULTIPLIER*math.sign(delta_y)*math.pow(delta_y, 2))
		end
	end)
end

proptypes['vortex'] = Vortex