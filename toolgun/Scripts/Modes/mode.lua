local time = require('openmw_aux.time')
local ui = require('openmw.ui')

local common = require('openmw.interfaces').toolGun_p

local Mode = {}

function Mode:new(modeData)
  modeData = modeData or {}
  setmetatable(modeData, self)
  self.__index = self
  self.undoTable = {}
  self.undoIndex = 1
  return modeData
end

function Mode:setDefaults(key)
  if not self.scaleVar or not self.defaultScale then
    ui.showMessage(common.colors.warn .. "Error! " ..
                   common.colors.white .. "Mode not configured properly. No defaults to reset")
    return
  end

  if key.symbol == common.keys.switchMode and key.withShift then
    self.scaleVar = self.defaultScale
    ui.showMessage(common.colors.white .. "Reset "..
                   common.colors.green .. self.name ..
                   common.colors.white .. " settings to default.")
  end
end

function Mode:getSubmode()
  return self.subModes[self.submodeIndex]
end

function Mode:switchSubmode(key)
  if key.symbol ~= common.keys.switchMode or key.withShift then return end

  self.submodeIndex = (self.submodeIndex % #self.subModes) + 1
  ui.showMessage(common.colors.white .. "Switched to " ..
                 common.colors.green .. self.subModes[self.submodeIndex] ..
                 common.colors.white .." mode.")

end

function Mode:increment(scaleExtra, negate)
  local increment

  if scaleExtra then increment = self.incrementor * self.scaleMult
  else increment = self.incrementor end

  if negate then
    if self.scaleVar - increment >= self.limit.low then
      self.scaleVar = self.scaleVar - increment
    else
      self.scaleVar = self.defaultScale
    end
  else
    if self.scaleVar + increment <= self.limit.high then
      self.scaleVar = self.scaleVar + increment
    else
      self.scaleVar = self.defaultScale
    end
  end
end

function Mode:handleAdjustments(key)

  if key.symbol ~= common.keys.scaleDown and key.symbol ~= common.keys.scaleUp or
    not self.scaleVar then return end

  self.safeRunRepeatedly(
    function()
      self:increment(key.withShift, key.symbol == common.keys.scaleDown)
      ui.showMessage(common.colors.white .. "Adjusted " ..
                     common.colors.green .. self.name ..
                     common.colors.white .. " scaler to " .. self.scaleVar)
    end,
    key.symbol,
    time.second / 5
  )
end

function Mode.safeRunRepeatedly(func, key, delay)
  if common.adjustStopFn.func then common.adjustStopFn.func() common.adjustStopFn.func = nil end
  common.adjustStopFn.key = key
  common.adjustStopFn.func = time.runRepeatedly(func, delay)
end

Mode.getTarget = common.getTarget

return Mode
