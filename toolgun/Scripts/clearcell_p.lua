local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')

local Clone = require('scripts.modes.clone')
local Delete = require('scripts.modes.delete')
local Grab = require('scripts.modes.grab')
local Rotate = require('scripts.modes.rotate')
local Scale = require('scripts.modes.scale')
local toolInterface = require('openmw.interfaces').toolGun_p
local colors = toolInterface.colors

local ammoSlot = types.Actor.EQUIPMENT_SLOT.Ammunition
local soundOnce = false
local ToolIndex = 1
local Tools = {
  Delete,
  Scale,
  Clone,
  Grab,
  Rotate,
}

local function isUsingToolGun()

  local inventory = types.Actor.inventory(self)

  local toolGun = inventory:find('toolgun')

  if not toolGun or
    not types.Actor.hasEquipped(self, toolGun) or
    types.Actor.stance(self) ~= types.Actor.STANCE.Weapon then
    return false end

  return true
end
-- CTRL-C switches toolmode, ctrl-x, ctrl-y, ctrl-z changes axis
local function sendToolData(target, tool)

  local eventData = {}

  eventData.target = target.hitObject

  if tool.auxD and tool:auxD() then eventData.data = tool:auxD() end

  core.sendGlobalEvent(tool.name, eventData)

end

local function overrideSound()

  if not isUsingToolGun() then return end

  if types.Actor.getEquipment(self, ammoSlot) then
    local tempEquip = types.Actor.getEquipment(self)
    tempEquip[ammoSlot] = nil
    types.Actor.setEquipment(self, tempEquip)
  end

  if not input.isActionPressed(input.ACTION.Use) then
    if toolInterface.grabStopFn.func then
      toolInterface.grabStopFn.func()
      toolInterface.clipboard.rayHit = nil
    end
    if soundOnce then
      soundOnce = false
    end
  else
    if not soundOnce then
      soundOnce = true
      core.sound.playSoundFile3d("Sounds\\S3\\airboat_gun_lastshot" .. math.random(1, 2) .. ".wav", self)
    end
  end

end

local function switchToolMode()
  ToolIndex = ( ToolIndex % #Tools ) + 1
  ui.showMessage(colors.white .. "Switched to " ..
                 colors.green .. Tools[ToolIndex].name ..
                 colors.white .." tool.")
end

local function triggerToolTime()
  local tool = Tools[ToolIndex]

  if tool.func then tool:func() return end

  local target = toolInterface.getTarget()

  if not target or not target.hitObject or target.hitObject.recordId == "player" then return end

  if tool.shouldRepeat then
    toolInterface.grabStopFn.func = time.runRepeatedly(
      function()
        sendToolData(target, tool)
      end,
      time.second / 2
    )
  else
    sendToolData(target, tool)
  end
end

return {
  interfaceName = "toolTime",
  interface = {
    tools = Tools
  },
  engineHandlers = {
    onInputAction = function(id)
      if id == input.ACTION.Use and isUsingToolGun() then
        triggerToolTime()
      end
    end,
    onFrame = overrideSound,
    onKeyPress = function(key)
      if not isUsingToolGun() then return end

      if key.withCtrl then
        if key.symbol == toolInterface.keys.switchMode then switchToolMode()

        elseif key.symbol == 'x'
        or key.symbol == 'y'
        or key.symbol == 'z' then

          ui.showMessage( colors.white .. "Changed axis to " ..
                          colors.green .. string.upper(key.symbol) ..
                          colors.white .. ".")

          toolInterface.axis.last = toolInterface.axis.current
          toolInterface.axis.current = key.symbol

        end
      elseif Tools[ToolIndex].input then Tools[ToolIndex]:input(key)
      end

    end,
    onKeyRelease = function(key)
      if toolInterface.adjustStopFn.func and
        key.symbol == toolInterface.adjustStopFn.key then
        toolInterface.adjustStopFn.func()
      end
    end
  }
}
