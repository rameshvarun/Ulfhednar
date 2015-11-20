JoystickDevice = class('JoystickDevice')

function JoystickDevice:initialize(joystick)
  assert(self._joystick:isGamepad(),
    "Only supports joysticks that are registered as full gamepads.")

  self._joystick = joystick
  self._name = joystick:getName()
end

function JoystickDevice:name() return self._name end

function JoystickDevice:movement()
  return vector(self._joystick:getGamepadAxis("leftx"), self._joystick:getGamepadAxis("lefty"))
end

function JoystickDevice:attack()
  return self._joystick:isGamepadDown("a")
end

function JoystickDevice:special()
  return self._joystick:isGamepadDown("b")
end

function JoystickDevice:vibrate(strength, duration)
  if self._joystick:isVibrationSupported() then
    self._joystick:setVibration(strength, strength, duration)
  end
end
