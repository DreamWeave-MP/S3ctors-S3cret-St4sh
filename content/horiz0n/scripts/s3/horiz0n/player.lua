---@omw-context player

local self = require 'openmw.self'

local hasTag
local getRealFrameDuration, horiz0nSettings, setViewDistance =
  require('openmw.core').getRealFrameDuration,
  require('openmw.storage').playerSection 'SettingsPlayerHoriz0n',
  require('openmw.camera').setViewDistance

local CELL_SIZE = 8192
local MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE =
  CELL_SIZE * horiz0nSettings:get 'Horiz0nMinViewDistance',
  CELL_SIZE * horiz0nSettings:get 'Horiz0nMaxViewDistance'

setViewDistance(MIN_VIEW_DISTANCE)

local ENABLE, BAD_FRAME_RATIO, OKAYISH_FRAME_RATIO, SEVERE_MULT, VD_STEP, UPDATE_INTERVAL =
  horiz0nSettings:get 'Horiz0nToggle',
  1 + horiz0nSettings:get 'Horiz0nPercentAdjustSevere' / 100,
  1 + horiz0nSettings:get 'Horiz0nPercentAdjustNormal' / 100,
  horiz0nSettings:get 'Horiz0nViewDistanceSevereMult',
  horiz0nSettings:get 'Horiz0nViewDistanceStep',
  1 / horiz0nSettings:get 'Horiz0nAdjustFramerate'

local viewDistance = MIN_VIEW_DISTANCE

local fastestFrameTime, updateTimer = math.huge, 0.0

local function nullFunction() end
local frameFunction = nullFunction

---@param value number
---@param min number
---@param max number
---@return number clamped
local function clamp(value, min, max) return value <= min and min or value >= max and max or value end

---@return boolean isOutdoors
local function isOutdoors()
  local currentCell = self.cell
  ---@cast currentCell openmw.core.LCell
  return currentCell.isExterior or hasTag(currentCell, 'QuasiExterior')
end

local function tick(simTime)
  if simTime <= 0 or not isOutdoors() then return end

  local frameTime = getRealFrameDuration()

  updateTimer = updateTimer + frameTime

  if updateTimer < UPDATE_INTERVAL then return end

  updateTimer = 0.0

  if frameTime < fastestFrameTime then fastestFrameTime = frameTime end

  local frameRatio = frameTime / fastestFrameTime
  local decreaseOrIncrease = frameRatio >= OKAYISH_FRAME_RATIO
  local doSevereStep = frameRatio >= BAD_FRAME_RATIO

  local step = VD_STEP
  if doSevereStep then step = step * SEVERE_MULT end
  if decreaseOrIncrease then step = -step end

  viewDistance = clamp(viewDistance + step, MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE)

  setViewDistance(viewDistance)
end

local function initFunction(_)
  if not self.cell then return end
  hasTag, frameFunction = self.cell.hasTag, tick
end

if ENABLE then frameFunction = initFunction end

horiz0nSettings:subscribe(require('openmw.async'):callback(function(_, key)
  local value = horiz0nSettings:get(key)

  if key == 'Horiz0nToggle' then
    ENABLE, frameFunction = value, value and initFunction or nullFunction
  elseif key == 'Horiz0nMaxViewDistance' then
    MAX_VIEW_DISTANCE = CELL_SIZE * value

    if MAX_VIEW_DISTANCE < viewDistance then
      viewDistance = MAX_VIEW_DISTANCE
      setViewDistance(viewDistance)
    end
  elseif key == 'Horiz0nMinViewDistance' then
    MIN_VIEW_DISTANCE = CELL_SIZE * value

    if MIN_VIEW_DISTANCE > viewDistance then
      viewDistance = MIN_VIEW_DISTANCE
      setViewDistance(viewDistance)
    end
  elseif key == 'Horiz0nPercentAdjustSevere' then
    BAD_FRAME_RATIO = 1 + value / 100
  elseif key == 'Horiz0nPercentAdjustNormal' then
    OKAYISH_FRAME_RATIO = 1 + value / 100
  elseif key == 'Horiz0nViewDistanceSevereMult' then
    SEVERE_MULT = value
  elseif key == 'Horiz0nViewDistanceStep' then
    VD_STEP = value
  elseif key == 'Horiz0nAdjustFramerate' then
    UPDATE_INTERVAL = 1 / value
  end
end))

return {
  engineHandlers = {
    onFrame = function(simTime) frameFunction(simTime) end,
    onLoad = function(data)
      if not data then return end

      local oldDist = data.viewDistance

      if oldDist then
        viewDistance = clamp(oldDist, MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE)
        setViewDistance(viewDistance)
      end
    end,
    onSave = function()
      return {
        viewDistance = viewDistance,
      }
    end,
  },
}
