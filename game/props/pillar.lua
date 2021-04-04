--Define Class
Pillar = class('Pillar')

function Pillar:initialize(mapobject, game)
	--Spawn position
	self.x = mapobject.x + mapobject.width/2
	self.y = mapobject.y + mapobject.height/2

	--Reference to Game State
	self.game = game
	
	self.image = getImage("props/pillar.png")
	
	self.mapobject = mapobject
	
	--Collision
	self.mapobject.type = "collision"
end


function Pillar:draw()

	love.graphics.setColor( 255, 255, 255, 255 )
	
	love.graphics.draw(self.image, self.x, self.y  , 0, 1, 1, 77, 254)
end

function Pillar:update(dt)
end

proptypes['pillar'] = Pillar