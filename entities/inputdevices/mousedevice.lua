MouseDevice = class('MouseDevice')

function MouseDevice:initialize() end
function MouseDevice:name() return "Mouse" end

function MouseDevice:movement()
  error("Not implemented.")
end

function MouseDevice:attack() return love.mouse.isDown("l") end
function MouseDevice:special() return love.mouse.isDown("r") end
function MouseDevice:vibrate(strength, duration) --[[ No-op ]] end
