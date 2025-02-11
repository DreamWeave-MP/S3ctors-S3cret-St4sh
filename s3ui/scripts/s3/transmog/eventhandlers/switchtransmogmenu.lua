local camera = require('openmw.camera')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local prevCam = nil

local function teardownVanillaUserInterface()
  types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, false)
  types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, false)
  I.Controls.overrideUiControls(true)
  self.controls.sneak = false -- This is a special case, it's not covered by the control switch
  camera.showCrosshair(false)
  camera.setYaw(3.14)
  camera.setPitch(0)
  camera.setRoll(0)
  prevCam = camera.getMode()
  camera.setMode(camera.MODE.Static)
  camera.setStaticPosition(self.position + util.vector3(25, 75, 75))
  I.UI.setHudVisibility(false)
  I.UI.setPauseOnMode(I.UI.MODE.Interface, false)
  I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
end

local function restoreVanillaUserInterface()
  types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, true)
  types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, true)
  I.Controls.overrideUiControls(false)
  camera.showCrosshair(true)
  camera.setMode(prevCam)
  I.UI.setHudVisibility(true)
  I.UI.setPauseOnMode(I.UI.MODE.Interface, true)
  I.UI.setMode()
  prevCam = nil
end

local function switchTransmogMenu()
  if prevCam then restoreVanillaUserInterface() else teardownVanillaUserInterface() end
end

--- This file is somewhat misnamed
--- It's responsible for switching between states of the transmog menu
return {
  eventHandlers = {
    switchTransmogMenu = switchTransmogMenu,
  }
}
