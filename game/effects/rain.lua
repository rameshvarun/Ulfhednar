Rain = class('Rain')

function Rain:initialize(game)
	
	self.wind = -1000
	self.grav = 1000 --arbitary but seems to work
	self.t = 0
	self.game = game
	self.rain = {}
	self.raining = true
	
end

function Rain:draw()
	for i=1,#self.rain do
		love.graphics.setColor(41,7,212,200)
		love.graphics.line(self.rain[i].x,self.rain[i].y,self.rain[i].x2,self.rain[i].y2)
	end
end

function Rain:update(dt)
	self.t=self.t+dt
	if self.raining == true then
		for i=1,5 do
			self.x = math.random(-800,love.window.getWidth() + 800)
			self.y = -10
			self.x2 = self.x - 5
			self.y2 = self.y + 5
			self.rain[#self.rain+1] = {x = self.x, y = self.y, x2 = self.x2, y2 = self.y2}
		end
	end
	for i=#self.rain,1,-1 do
		self.rain[i].x = self.rain[i].x+ self.wind * dt
		self.rain[i].y = self.rain[i].y+ self.grav * dt
		self.rain[i].x2 = self.rain[i].x - 5
		self.rain[i].y2 = self.rain[i].y + 5
		if self.rain[i].y>love.window.getHeight() then --or self.rain[i].x<-1000 or self.rain[i].x>2000 then
			table.remove(self.rain,i)
		end
	end
end

function Rain:start()
	self.raining = true
end

function Rain:stop()
	self.raining = false
end
