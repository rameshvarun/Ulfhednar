--Define class
Boat = class('Boat')

function Boat:initialize(mapobject, game)
	--References
	self.game = game
	self.mapobject = mapobject

	--Visuals
	self.image = getImage("props/boat.png")
	self.layer = -1
	local w = self.image:getWidth()
	local h = self.image:getHeight()

	--Create phsyics body
	self.body = love.physics.newBody(game.world, mapobject.x + mapobject.width/2, mapobject.y + mapobject.height/2, "dynamic")

	self.shapes = {
		love.physics.newPolygonShape(0 - w/2, 80 - h/2, 49 - w/2, 36 - h/2, 121 - w/2, 0 - h/2, 121 - w/2, h - h/2, 49 - w/2, h - 36 - h/2, 0 - w/2, 306 - h/2),
		love.physics.newPolygonShape(121 - w/2, 0 - h/2, 327 - w/2, 0 - h/2,484 - w/2, 30 - h/2,556 - w/2, 56 - h/2,556 - w/2, h - 56 - h/2,484 - w/2, h - 30 - h/2,327 - w/2, h - h/2 , 121 - w/2, h - h/2),
		love.physics.newPolygonShape(556 - w/2, 56 - h/2,616 - w/2, 87 - h/2,659 - w/2, 139 - h/2,674 - w/2, 184 - h/2,674 - w/2, h - 184 - h/2,659 - w/2, h - 139 - h/2,616 - w/2, h - 87 - h/2,556 - w/2, h - 56 - h/2)
	}

	--Turn shapes into fixtures
	self.fixtures = _.map(self.shapes, function(shape)
		local fixture = love.physics.newFixture(self.body, shape, 0.1)
		fixture:setRestitution(0.9)
		return fixture
	end)

	--Damping to prevent infinite acceleration
	self.body:setLinearDamping( 0.2 )
	self.body:setAngularDamping( 0.2 )

	--Initial values for the 'last_state' object
	self.last_state = {}
	self.last_state.x = self.body:getX()
	self.last_state.y = self.body:getY()
	self.last_state.angle = self.body:getAngle()
end

function Boat:draw()

	love.graphics.setColor( 255, 255, 255, 255 )

	love.graphics.draw(self.image, self.body:getX(), self.body:getY()  , self.body:getAngle(), 1, 1, self.image:getWidth()/2, self.image:getHeight()/2)
end

function Boat:update(dt)
	TORQUE_FACTOR = 200
	FORCE_FACTOR = 2

	--[[ Keep track of a sum of the positions of all of
	the players. This is used for calculating the steering ]]--
	local x_sum = 0
	local y_sum = 0

	for i,gameobject in pairs(self.game.gameobjects) do
		if gameobject.type == "player" and gameobject:isAlive() then

			--Get distance and angle to player
			local dist = math.dist(self.last_state.x, self.last_state.y, gameobject.x,gameobject.y)
			local angle = math.getAngle(self.last_state.x, self.last_state.y, gameobject.x,gameobject.y)

			--Rotate player to match the rotation of the boat from its previous state
			angle = angle - ( self.body:getAngle() - self.last_state.angle)
			gameobject.x = self.body:getX() + dist*math.sin(angle)
			gameobject.y = self.body:getY() + dist*math.cos(angle)

			--Check if player is in the boat
			local in_boat = _.any(self.fixtures, function(fixture)
				if fixture:testPoint( gameobject.x, gameobject.y ) then return true
				else return false end
			end)

			--If not, we have to push them so that they are on the boat
			if not in_boat then
				--Cast ray against all fixtures
				local raycast_points = _.map(self.fixtures, function (fixture)
					xn, yn, fraction = fixture:rayCast( gameobject.x, gameobject.y, self.body:getX(), self.body:getY(), 1, 1 )
					return fraction
				end)
				--Drop missed rays (fraction == nil)
				_.select(raycast_points, function(fraction) return fraction ~= nil end)

				--Get the nearest hit
				local fraction = _.first(_.sort(raycast_points))

				--Push player to the hit
				gameobject.x, gameobject.y =  gameobject.x + ( self.body:getX()-  gameobject.x) * fraction,  gameobject.y + (self.body:getY()-  gameobject.y) * fraction
			end
			
			--Sum up all of the positions
			x_sum = x_sum + gameobject.x
			y_sum = y_sum + gameobject.y
		end
	end

	--Calculate average position of all players
	local x_avg = x_sum / self.game:alivePlayers()
	local y_avg = y_sum / self.game:alivePlayers()

	--Calculate distance and angle to average position
	local dist_avg = math.dist(self.body:getX(), self.body:getY(), x_avg, y_avg)
	local angle_avg = math.getAngle(self.body:getX(), self.body:getY(), x_avg, y_avg) + self.body:getAngle()
	
	--Torque for rotational control
	self.body:applyTorque(TORQUE_FACTOR*dist_avg*math.cos(angle_avg))

	--Force for acceleration and decceleration
	local world_x, world_y = self.body:getWorldPoint( 1, 0 )
	world_x = world_x - self.body:getX()
	world_y = world_y - self.body:getY()
	self.body:applyForce(FORCE_FACTOR*world_x*dist_avg*math.sin(angle_avg), FORCE_FACTOR*world_y*dist_avg*math.sin(angle_avg))

	--Update the 'last_state' object
	self.last_state.x = self.body:getX()
	self.last_state.y = self.body:getY()
	self.last_state.angle = self.body:getAngle()
end

proptypes['boat'] = Boat