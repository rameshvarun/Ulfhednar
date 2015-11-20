# Input Devices

Input device objects must satisfy the following interfaces.

## `InputDevice#name(): string`
This function returns a string which describes which physical device this virtual device corresponds to. This may not be easy though, so a best effort is enough.

## `InputDevice#movement(): vector`
This function returns a vector of magnitude `[0, 1]`, which corresponds to the direction the character should move in.

## `InputDevice#attack(): boolean`
This function returns a `boolean` corresponding to the characters attack / select button.

## `InputDevice#special(): boolean`
Returns `true` if the special button is pressed.

## `InputDevice#pause(): boolean`

## `InputDevice#vibrate(strength: number, duration: number): void`
This instructs the device to rumble with a certain strength for a certain time. For many devices, this is simply a no-op.

## `InputDevice#isFullyBound(): boolean`

## `InputDevice#bindings(): table`

## `InputDevice#bindings(): table`
