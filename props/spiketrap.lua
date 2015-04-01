--Define Class
SpikeTrap = class('SpikeTrap')

SPIKE_WIDTH = 32
SPIKE_HEIGHT = 32

function SpikeTrap:initialize(mapobject, game)
	--Spawn position
	self.x = mapobject.x
	self.y = mapobject.y
	
	--Use the size of the rectangle to determine the number of rows and columns
	self.cols = math.floor( mapobject.width / SPIKE_WIDTH  )
	self.rows = math.floor( mapobject.height / SPIKE_HEIGHT  )

	--Reference to Game State
	self.game = game
	
	self.image = getImage("props/spike.png") --Image
	self.holeimage = getImage("props/spikehole.png") --Image
	
	self.mapobject = mapobject
	
	--Spiketrap starts out as enabled
	self.enabled = true
	self.mapobject.type = "collision"
end

function SpikeTrap:enable()
	self.enabled = true
	self.mapobject.type = "collision"
	
	self.game.map:updateCollision()
	
	love.audio.play(spike_sfx)
end

function SpikeTrap:disable()
	self.enabled = false
	self.mapobject.type = "spiketrap"
	
	self.game.map:updateCollision()
	
	love.audio.play(spike_sfx)
end

function SpikeTrap:toggle()
	if self.enabled then
		self:disable()
	else
		self:enable()
	end
end

function SpikeTrap:draw()

	for x=1,self.cols do
		for y=1,self.rows do
			local xpos = self.x + x*SPIKE_WIDTH - SPIKE_WIDTH/2
			local ypos = self.y + y*SPIKE_HEIGHT - SPIKE_HEIGHT/2
			
			if self.game.debug == true then
				love.graphics.setPointSize(10)
				love.graphics.setColor( 0, 255, 0, 255 )
				
				love.graphics.point( xpos, ypos )
			end
			
			love.graphics.setColor( 255, 255, 255, 255 )
			
			love.graphics.draw(self.holeimage, xpos, ypos  , 0, 1, 1, self.image:getWidth()/2, 47)
			
			if self.enabled then
				love.graphics.draw(self.image, xpos, ypos  , 0, 1, 1, self.image:getWidth()/2, 47)
			else
				--TODO: Draw a hole when spike trap is disabled
			end
		end
	end
end

function SpikeTrap:update(dt)
end

proptypes['spike'] = SpikeTrap
proptypes['spiketrap'] = SpikeTrap