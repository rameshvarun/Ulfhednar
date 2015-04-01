--Define class
Forcefield = class('Forcefield')

function Forcefield:initialize(mapobject, game)
	--References
	self.game = game
	self.mapobject = mapobject
	self.x = mapobject.x
	self.y = mapobject.y
end

function  Forcefield:draw()

end

function Forcefield:update(dt)
	--Iterate through all bodues
	_.each(self.game.world:getBodyList(), function( body )
		--Only operate on dynamic bodies
		if body:getType() == "dynamic" then
			if body:getX() > self.mapobject.x and body:getX() < self.mapobject.x + self.mapobject.width then
				if body:getY() > self.mapobject.y and body:getY() < self.mapobject.y + self.mapobject.height then
					body:applyForce( self.mapobject.fx, self.mapobject.fx )
				end
			end
		end
	end)
end

proptypes['forcefield'] = Forcefield