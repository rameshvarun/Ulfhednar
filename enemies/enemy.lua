
--Base class enemy
Enemy = class('Enemy')

function Enemy:initialize(x,y,game, spawner)
	--Geenrate random id unique to this enemy
	self.id = generateID()

	--Spawn position
	self.x = x
	self.y = y

	--Keep a reference to the spawner that spawned you
	self.spawner = spawner

	--Enemy Type
	self.type = "enemy"

	--Reference to Game State
	self.game = game

	--Set collision bounds to empty for now
	self.collx = 0
	self.colly = 0
	self.collwidth = 0
	self.collheight = 0

	--Used for AI Behavior
	self.target = nil
end

function Enemy:shoot(bullet)
	if collideRect(self.collx, self.colly, self.collx + self.collwidth, self.colly + self.collheight, bullet.collx, bullet.colly,  bullet.collx + bullet.collwidth, bullet.colly + bullet.collheight) then
		self.hp = self.hp - bullet.power
		self.killer = bullet.owner

		love.timer.sleep( 0.02 )

		return true
	end

	return false
end

function Enemy:draw()
	--Debug drawing
	if self.game.debug == true then
		love.graphics.setPointSize(10)
		love.graphics.setColor( 0, 255, 0, 255 )

		--Mark location with point
		love.graphics.point( self.x, self.y)

		--Draw rectangle around collision area
		love.graphics.rectangle("line", self.collx , self.colly, self.collwidth, self.collheight)
	end
end

--[[
This function goes through a list of players within the provided range, and randomly
assigns one to the field self.target.
@return Returns true if a target was selected, false if no enemies were in range to be selected
]]--
function Enemy:selectTarget(range)
	local players = self.game:getObjectsByType("player")
	local inrange_players = _.filter(players, function(player)
		local dist = math.dist(self.x, self.y, player.x, player.y)
		return (dist < range) and (player.hp > 0)
	end)

	if #inrange_players > 0 then
		self.target = inrange_players[ math.random(1, #inrange_players ) ]
		return true
	else
		return false
	end
end

--[[
This helper function looks for all players within the given range, and melees them with
a certain power.
@param range The distance that players must be from the enemy to be melee'd
@param power The amount of damage done by the melee attack
]]--
function Enemy:meleeNearby(range, power)
	local players = self.game:getObjectsByType("player")
	for _,player in pairs(players) do
		local diffx = self.x - player.x
		local diffy = self.y - player.y
		local dist = math.norm(diffx, diffy)

		if dist < range then
			player:melee(power)
		end
	end
end

--[[
Handles the common logic of enemy death. Checks if hp is less than zero,
if so if removes the object from the scene, increments the killers score, and also
notifies the spawner that one of it's children has died.
@param score The score that the killer gains if this enemy dies
@return Returns true if the enemy died, false if still alive
]]--
function Enemy:handleDeath(score)
	if self.hp < 0 then
		self.game:removeGameObject(self)

		--Increment killer's score
		if self.killer ~= nil then
			self.killer.score = self.killer.score + score
		end

		--Tell spawner that this enemy has been removed
		if self.spawner ~= nil then
			self.spawner:removeChild(self)
		end

		return true
	end

	return false
end
