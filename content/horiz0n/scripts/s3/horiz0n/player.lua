---@omw-context player

local self = require 'openmw.self'

local getBaseViewDistance, getViewDistance, setViewDistance =
  require('openmw.camera').getBaseViewDistance,
  require('openmw.camera').getViewDistance,
  require('openmw.camera').setViewDistance

local getRealFrameDuration, getSimulationTimeScale, horiz0nSettings =
  require('openmw.core').getRealFrameDuration,
  require('openmw.core').getSimulationTimeScale,
  require('openmw.storage').playerSection 'SettingsPlayerHoriz0n'

local mathFloor, mathMax, mathMin = math.floor, math.max, math.min

---@alias Horiz0nMode 'disabled'|'indoors'|'managing'

local CELL_SIZE = 8192
local MAX_GROW_COOLDOWN = 60.0
local SUSTAINED_BAD_WINDOWS = 2

local MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE =
  CELL_SIZE * horiz0nSettings:get 'Horiz0nMinViewDistance',
  CELL_SIZE * horiz0nSettings:get 'Horiz0nMaxViewDistance'

local ENABLE, TARGET_FRAME_TIME, BAD_FRAME_RATIO, OKAYISH_FRAME_RATIO, SEVERE_MULT, VD_STEP_FRACTION, UPDATE_INTERVAL, GROW_COOLDOWN =
  horiz0nSettings:get 'Horiz0nToggle',
  1 / horiz0nSettings:get 'Horiz0nTargetFramerate',
  1 + horiz0nSettings:get 'Horiz0nPercentAdjustSevere' / 100,
  1 + horiz0nSettings:get 'Horiz0nPercentAdjustNormal' / 100,
  horiz0nSettings:get 'Horiz0nViewDistanceSevereMult',
  horiz0nSettings:get 'Horiz0nViewDistanceStepPercent' / 100,
  1 / horiz0nSettings:get 'Horiz0nAdjustFramerate',
  horiz0nSettings:get 'Horiz0nGrowCooldown'

---@type Horiz0nMode
local mode = 'disabled'

local viewDistance = getBaseViewDistance()

local windowDuration, windowFrames, badWindows = 0.0, 0, 0

local growCooldown, cooldownRemaining, isProbing = GROW_COOLDOWN, 0.0, false

---@type number?
local failedViewDistance

---@param cell openmw.core.LCell
---@return Horiz0nMode
local function modeIn(cell)
  if not ENABLE then return 'disabled' end
  if cell.isExterior or cell:hasTag 'QuasiExterior' then return 'managing' end

  return 'indoors'
end

---@return number
local function maxViewDistance() return mathMin(MAX_VIEW_DISTANCE, getBaseViewDistance()) end

---@param distance number
---@return number clamped
local function clampViewDistance(distance)
  local maximum = maxViewDistance()

  return mathMax(mathMin(MIN_VIEW_DISTANCE, maximum), mathMin(distance, maximum))
end

--- The engine stores view distance as a 32-bit float, and whole units survive that round trip exactly.
---@param distance number
local function applyViewDistance(distance)
  local wholeUnits = mathFloor(distance + 0.5)

  if getViewDistance() ~= wholeUnits then setViewDistance(wholeUnits) end
end

---@param step number
local function shrink(step)
  if isProbing and failedViewDistance then
    growCooldown = mathMin(growCooldown * 2, MAX_GROW_COOLDOWN)
  end

  isProbing, failedViewDistance, cooldownRemaining = false, viewDistance, growCooldown
  viewDistance = clampViewDistance(viewDistance - step)
end

---@param step number
local function grow(step)
  isProbing = true
  viewDistance = clampViewDistance(viewDistance + step)

  if failedViewDistance and viewDistance > failedViewDistance then
    failedViewDistance, growCooldown = nil, GROW_COOLDOWN
  end
end

local function measureFrame()
  --- getRealFrameDuration is multiplied by the simulation time scale, which is positive whenever the world is unpaused.
  windowDuration = windowDuration + getRealFrameDuration() / getSimulationTimeScale()
  windowFrames = windowFrames + 1

  if windowDuration < UPDATE_INTERVAL then return end

  local elapsed, frameRatio = windowDuration, windowDuration / windowFrames / TARGET_FRAME_TIME
  windowDuration, windowFrames = 0.0, 0

  local step = viewDistance * VD_STEP_FRACTION

  if frameRatio >= OKAYISH_FRAME_RATIO then
    badWindows = badWindows + 1
    if badWindows < SUSTAINED_BAD_WINDOWS then return end

    if frameRatio >= BAD_FRAME_RATIO then step = step * SEVERE_MULT end
    shrink(step)
    return
  end

  badWindows = 0

  if cooldownRemaining > 0 then
    cooldownRemaining = cooldownRemaining - elapsed
  else
    grow(step)
  end
end

---@param newMode Horiz0nMode
local function enterMode(newMode)
  mode = newMode
  windowDuration, windowFrames, badWindows = 0.0, 0, 0

  if mode == 'disabled' then applyViewDistance(getBaseViewDistance()) end
end

horiz0nSettings:subscribe(require('openmw.async'):callback(
  ---@param _ string
  ---@param key string
  function(_, key)
    local value = horiz0nSettings:get(key)

    if key == 'Horiz0nToggle' then
      ENABLE = value
    elseif key == 'Horiz0nTargetFramerate' then
      TARGET_FRAME_TIME = 1 / value
    elseif key == 'Horiz0nMaxViewDistance' then
      MAX_VIEW_DISTANCE = CELL_SIZE * value
    elseif key == 'Horiz0nMinViewDistance' then
      MIN_VIEW_DISTANCE = CELL_SIZE * value
    elseif key == 'Horiz0nPercentAdjustSevere' then
      BAD_FRAME_RATIO = 1 + value / 100
    elseif key == 'Horiz0nPercentAdjustNormal' then
      OKAYISH_FRAME_RATIO = 1 + value / 100
    elseif key == 'Horiz0nViewDistanceSevereMult' then
      SEVERE_MULT = value
    elseif key == 'Horiz0nViewDistanceStepPercent' then
      VD_STEP_FRACTION = value / 100
    elseif key == 'Horiz0nAdjustFramerate' then
      UPDATE_INTERVAL = 1 / value
    elseif key == 'Horiz0nGrowCooldown' then
      GROW_COOLDOWN, growCooldown = value, value
    end
  end
))

return {
  engineHandlers = {
    ---@param frameDuration number
    onFrame = function(frameDuration)
      local cell = self.cell
      if not cell then return end

      local currentMode = modeIn(cell)
      if currentMode ~= mode then enterMode(currentMode) end

      if mode == 'disabled' then return end

      if mode == 'indoors' then
        applyViewDistance(maxViewDistance())
        return
      end

      if frameDuration > 0 then measureFrame() end

      viewDistance = clampViewDistance(viewDistance)
      applyViewDistance(viewDistance)
    end,
    ---@param data { viewDistance: number? }?
    onLoad = function(data)
      if data and data.viewDistance then viewDistance = data.viewDistance end
    end,
    ---@return { viewDistance: number }
    onSave = function()
      return {
        viewDistance = viewDistance,
      }
    end,
  },
}
