KeyboardDevice = class('KeyboardDevice')

function KeyboardDevice:initialize()
	self._attackKey = 'z'
	self._specialKey = 'x'
	self._upKey = 'up'
	self._downKey = 'down'
	self._rightKey = 'right'
	self._leftKey = 'left'
end

function KeyboardDevice:name() return "Keyboard" end

function KeyboardDevice:movement()
	local move = vector(0, 0)

	if love.keyboard.isDown(self._leftKey) then move.x = -1 end
	if love.keyboard.isDown(self._rightKey) then move.x = 1 end
	if love.keyboard.isDown(self._upKey) then move.y = -1 end
	if love.keyboard.isDown(self._downKey) then move.y = 1 end

	return move:normalized()
end

function KeyboardDevice:attack()
  return love.keyboard.isDown(self._attackKey)
end

function KeyboardDevice:special()
	return love.keyboard.isDown(self._specialKey)
end

function KeyboardDevice:vibrate(strength, duration)
	-- No-op
end
