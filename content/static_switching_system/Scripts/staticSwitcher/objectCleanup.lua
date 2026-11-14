---@omw-context global

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local pcall, tostring = pcall, tostring
local Min = math.min
local StrFormat = string.format

--- Corrections are worked off a few per frame, however many are waiting. An engine that keeps
--- refusing must cost a fixed amount per frame, not more with every object it refuses.
local CORRECTIONS_PER_FRAME = 4

--- How many frames a correction is tried on before it is given up.
local MAX_ATTEMPTS = 8

--- Corrections SSS still owes the world: an object it created and could not use, to be
--- removed, or an object it moved in a pass that then failed, to be put back.
---
--- OpenMW applies a move at the end of the frame, and until then reports the object's count as
--- zero, refuses to move it again, and refuses to remove it. A zero count therefore does not
--- mean an object is gone, and a correction to an object in transit has to wait for it to land.
---@type SSSPendingCorrection[]
local PendingCorrections = {}
local firstPending, lastPending = 1, 0

---@type table<string, true>
local IssuedWarnings = {}

---@param warning string
local function warnOnce(warning)
  if IssuedWarnings[warning] then return end
  IssuedWarnings[warning] = true

  WarnLog(warning)
end

---@param correction SSSPendingCorrection
local function applyCorrection(correction)
  local object = correction.object

  if not correction.cell then
    object:remove()
    return
  end

  object:setScale(correction.scale)
  object:teleport(correction.cell, correction.position, { rotation = correction.rotation })
end

---@param correction SSSPendingCorrection
---@return boolean isSettled whether the correction is done or no longer needed
---@return string? refusal what the engine said when it refused
local function attemptCorrection(correction)
  local object = correction.object
  if not object:isValid() then return true end

  if object.count < 1 then return false end

  local wasApplied, refusal = pcall(applyCorrection, correction)
  if wasApplied then return true end

  return false, tostring(refusal)
end

---@param correction SSSPendingCorrection
local function enqueue(correction)
  lastPending = lastPending + 1
  PendingCorrections[lastPending] = correction
end

---@return SSSPendingCorrection correction
local function dequeue()
  local correction = PendingCorrections[firstPending]
  PendingCorrections[firstPending] = nil
  firstPending = firstPending + 1

  return correction
end

---@param correction SSSPendingCorrection
---@param refusal string? what the engine said, when it refused rather than was not ready
local function retryLater(correction, refusal)
  local recordId = correction.object.recordId
  local task = correction.cell and 'put back where it was' or 'removed'

  if refusal then
    warnOnce(
      StrFormat('A stray %s could not be %s and will be retried: %s', recordId, task, refusal)
    )
  end

  correction.attemptsLeft = correction.attemptsLeft - 1

  if correction.attemptsLeft > 0 then
    enqueue(correction)
  elseif refusal then
    warnOnce(StrFormat('Gave up: a stray %s was never %s', recordId, task))
  end
end

--- Removes an object that SSS created but that did not end up where it was meant to be: a
--- replacement that never took its original's place, a created object that could not be
--- placed, an item that could not be put in an inventory. One attempt is made at once; what
--- is left over is worked off by `step`, never rescanned here.
---@param object openmw.GObject
local function discard(object)
  ---@type SSSPendingCorrection
  local correction = { object = object, attemptsLeft = MAX_ATTEMPTS }

  local isSettled, refusal = attemptCorrection(correction)
  if not isSettled then retryLater(correction, refusal) end
end

--- Puts an object back where it was before a pass that moved it and then failed. The move it
--- undoes is still in flight when this is called, so it always waits for a later frame.
---@param object openmw.GObject
---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@param rotation openmw.util.Transform
---@param scale number
local function restoreLater(object, cell, position, rotation, scale)
  enqueue {
    object = object,
    attemptsLeft = MAX_ATTEMPTS,
    cell = cell,
    position = position,
    rotation = rotation,
    scale = scale,
  }
end

---@return boolean hasPending whether any correction is still waiting
local function hasPending() return lastPending >= firstPending end

--- Works off a fixed number of waiting corrections. Called once per frame.
local function step()
  for _ = 1, Min(CORRECTIONS_PER_FRAME, lastPending - firstPending + 1) do
    local correction = dequeue()

    local isSettled, refusal = attemptCorrection(correction)
    if not isSettled then retryLater(correction, refusal) end
  end
end

---@class SSSObjectCleanup
return {
  discard = discard,
  hasPending = hasPending,
  restoreLater = restoreLater,
  step = step,
}
