---@meta

---Gamepad control interface
---@class openmw.interfaces.GamepadControls
---@field version number
local GamepadControls = {}

---Interface version
---@type number
GamepadControls.version = nil

---Checks if the gamepad cursor is active. If it is active, the left stick can move the cursor, and A will be interpreted as a mouse click.
---@return boolean
function GamepadControls.isGamepadCursorActive() end

---Checks if the controller menu option is enabled. If true, UI is replaced with a more controller appropriate interface.
---@return boolean
function GamepadControls.isControllerMenusEnabled() end

---Sets if the gamepad cursor is active. If it is active, the left stick can move the cursor, and A will be interpreted as a mouse click.
---@param value boolean
function GamepadControls.setGamepadCursorActive(value) end

return GamepadControls
