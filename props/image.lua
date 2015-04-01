--Define Class
ImageProp = class('ImageProp')

function ImageProp:initialize(mapobject, game)
	--Spawn position
	self.x = mapobject.x
	self.y = mapobject.y

	--Reference to Game State
	self.game = game
	
	self.image = getImage( mapobject.file )
	
	self.mapobject = mapobject
end


function ImageProp:draw()

	love.graphics.setColor( 255, 255, 255, 255 )
	
	love.graphics.draw(self.image, self.x, self.y, 0, 1, 1)
end

function ImageProp:update(dt)
end

proptypes['image'] = ImageProp
proptypes['imageprop'] = ImageProp