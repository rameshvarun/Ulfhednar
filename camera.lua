cam = {}
cam.x = 0
cam.y = 0
cam.zoom = 1
cam.rotation = 0
cam.zoom_factor = 1

function cam:set()
	love.graphics.push()
	
	love.graphics.rotate(-self.rotation)
	love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
	love.graphics.scale(1 / self.zoom, 1 / self.zoom)
	
	love.graphics.translate(-self.x, -self.y)
end

function cam:unset()
	love.graphics.pop()
end

function cam:project(mx, my)
	return ( mx - love.graphics.getWidth()/2) * self.zoom + self.x , (my - love.graphics.getHeight()/2) * self.zoom + self.y
end

--[[ Fits camera to include all players. ]]--
function cam:fitPlayers(gameobjects, dt)
	local minx = -1
	local maxx = -1
	local miny = -1
	local maxy = -1

	local alive_count = 0

	for _,gameobject in pairs(gameobjects) do
		if gameobject.type == "player" and gameobject.hp > 0 then
			alive_count = alive_count + 1

			if gameobject.x < minx or minx == -1 then minx = gameobject.x end
			if gameobject.x > maxx or maxx == -1 then maxx = gameobject.x end
			if gameobject.y < miny or miny == -1 then miny = gameobject.y end
			if gameobject.y > maxy or maxy == -1 then maxy = gameobject.y end
		end
	end

	if not (minx == -1 or maxx == -1 or miny == -1 or maxy == -1) then
		--Camera moves to center of all players
		local target = vector((minx + maxx)/2, (miny + maxy)/2)
		local lerpFactor = 3.0
		self.x = lume.lerp(self.x, target.x, lerpFactor*dt)
		self.y = lume.lerp(self.y, target.y, lerpFactor*dt)
		
		--Calculated zoom factors for both x and y direction
		local zoomx = ((maxx - minx) + 300)/love.graphics.getWidth()
		local zoomy = ((maxy - miny) + 500)/love.graphics.getHeight()
		
		--Zoom out a bit more if only one player is alive
		if alive_count == 1 then
			zoomx = zoomx * 1.5
			zoomy = zoomy * 1.5
		end

		zoomx = zoomx * self.zoom_factor
		zoomy = zoomy * self.zoom_factor
		
		--Set the camera's zoom to whichever zoom is larger
		local zoom_target = nil
		if zoomx > zoomy then zoom_target = zoomx else zoom_target = zoomy end
		self.zoom = lume.lerp(self.zoom, zoom_target, lerpFactor*dt)
	end
end