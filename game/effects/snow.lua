Snow = class('Snow')

function Snow:initialize(game)
	
	self.wind = -25
	self.grav = 34 --arbitary but seems to work
	self.t = 0
	self.game = game
	self.snow = {}
	self.snowing = true
	
end

function Snow:draw()
	for i=1,#self.snow do
		love.graphics.setColor(255,255,255,200)
		love.graphics.circle("fill",self.snow[i].x,self.snow[i].y,self.snow[i].size)
	end
end

function Snow:update(dt)
	self.t=self.t+dt
	if self.snowing == true then
		if math.random(1+self.t)>0.2 then
			self.snow[#self.snow+1] = {size = math.random(2,5),x = math.random(-800,1600),y = -10}
		end
	end
	for i=#self.snow,1,-1 do
		self.snow[i].x = self.snow[i].x+ self.wind * dt
		self.snow[i].y = self.snow[i].y+ self.grav * self.snow[i].size * dt
		if self.snow[i].y>720 or self.snow[i].x<-1000 or self.snow[i].x>2000 then
			table.remove(self.snow,i)
		end
	end
end

function Snow:start()
	self.snowing = true
end

function Snow:stop()
	self.snowing = false
end
