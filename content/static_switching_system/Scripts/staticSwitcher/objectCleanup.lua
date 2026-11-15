---@omw-context global

local world = require 'openmw.world'

local staticUtil = require 'Scripts.staticSwitcher.util'

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local next, pcall, tonumber, tostring, type = next, pcall, tonumber, tostring, type
local Min = math.min
local StrFormat = string.format

--- Corrections are worked off a few per frame, however many are waiting. An engine that keeps
--- refusing must cost a fixed amount per frame, not more with every object it refuses.
local CORRECTIONS_PER_FRAME = 4

--- How many frames a correction is tried on before it is given up.
local MAX_ATTEMPTS = 8

--- How many times an object that has been sent back may be looked for before it is taken to
--- have settled somewhere else. Counting only starts once the move back has been issued.
local RETURN_OBSERVATIONS = 6

--- Corrections SSS still owes the world: an object it created and could not use, to be
--- removed, or an object it moved in a pass that then failed, to be put back.
---
--- OpenMW applies a move at the end of the frame, and until then reports the object's count as
--- zero, refuses to move it again, and refuses to remove it. A zero count therefore does not
--- mean an object is gone, and a correction to an object in transit has to wait for it to land.
---@type SSSPendingCorrection[]
local PendingCorrections = {}
local firstPending, lastPending = 1, 0

--- Objects whose arrival somewhere is being watched by another part of SSS, by object ID.
--- Only these get a return record; a correction for anything else is carried out and forgotten.
---@type table<string, true>
local WatchedObjectIds = {}

--- Watched objects that are on their way back to where they were, by object ID.
---
--- A return is not the same thing as a correction and does not have the same lifetime. It
--- starts when the first move back is queued. It can cover several queued moves. It outlasts
--- the last of them, because a move that has been issued still has to land and its watcher
--- still has to see that it has. So it is counted, saved and loaded in its own right.
---@type table<string, SSSObjectReturn>
local Returns = {}

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

---@param object openmw.GObject
---@param cellId string where the move back that was just issued is taking the object
local function noteReturnIssued(object, cellId)
  local objectReturn = Returns[object.id]
  if not objectReturn then return end

  objectReturn.pendingMoves = objectReturn.pendingMoves - 1
  objectReturn.cellId, objectReturn.wasIssued = cellId, true
end

--- A move back that will never be carried out ends the return only if it was the last one
--- outstanding and none before it was issued; otherwise there is still an arrival to wait for.
---@param object openmw.GObject
local function noteReturnAbandoned(object)
  local objectReturn = Returns[object.id]
  if not objectReturn then return end

  objectReturn.pendingMoves = objectReturn.pendingMoves - 1

  if objectReturn.pendingMoves <= 0 and not objectReturn.wasIssued then Returns[object.id] = nil end
end

---@param correction SSSPendingCorrection
---@return boolean isSettled whether the correction is done or no longer needed
---@return string? refusal what the engine said when it refused
local function attemptCorrection(correction)
  local object = correction.object

  if not object:isValid() then
    Returns[object.id] = nil
    return true
  end

  if object.count < 1 then return false end

  local wasApplied, refusal = pcall(applyCorrection, correction)
  if not wasApplied then return false, tostring(refusal) end

  if correction.cell then noteReturnIssued(object, correction.cell.id) end

  return true
end

---@param correction SSSPendingCorrection
local function enqueue(correction)
  lastPending = lastPending + 1
  PendingCorrections[lastPending] = correction
end

--- A correction that puts a watched object back starts, or adds to, that object's return.
---@param correction SSSPendingCorrection
local function enqueueNew(correction)
  enqueue(correction)

  local object = correction.object
  if not correction.cell or not WatchedObjectIds[object.id] then return end

  local objectReturn = Returns[object.id]

  if not objectReturn then
    objectReturn = {
      object = object,
      cellId = correction.cell.id,
      pendingMoves = 0,
      wasIssued = false,
      observationsLeft = RETURN_OBSERVATIONS,
    }
    Returns[object.id] = objectReturn
  end

  objectReturn.pendingMoves = objectReturn.pendingMoves + 1
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
  local object = correction.object
  local recordId = object.recordId
  local task = correction.cell and 'put back where it was' or 'removed'

  if refusal then
    warnOnce(
      StrFormat('A stray %s could not be %s and will be retried: %s', recordId, task, refusal)
    )
  end

  correction.attemptsLeft = correction.attemptsLeft - 1

  if correction.attemptsLeft > 0 then
    enqueue(correction)
    return
  end

  if correction.cell then noteReturnAbandoned(object) end

  if refusal then warnOnce(StrFormat('Gave up: a stray %s was never %s', recordId, task)) end
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
  enqueueNew {
    object = object,
    attemptsLeft = MAX_ATTEMPTS,
    cell = cell,
    position = position,
    rotation = rotation,
    scale = scale,
  }
end

--- Registers an object whose arrivals another part of SSS acts on. Returns are only tracked
--- for watched objects, so nothing is kept for an object nobody will ever ask about.
---@param object openmw.GObject
local function watchReturns(object) WatchedObjectIds[object.id] = true end

--- Tells whether a watched object is being put back. While `pendingMoves` is above zero a
--- move back has still to be issued and the object may be anywhere, including where the
--- abandoned pass sent it.
---@param object openmw.GObject
---@return SSSObjectReturn? objectReturn
local function getReturn(object) return Returns[object.id] end

--- Reports where an object that is being put back was found. Once every move back has been
--- issued, the return is over when the object is seen in the cell it was sent to, or has been
--- looked for often enough that it must have settled elsewhere.
---@param object openmw.GObject
---@param cellId string cell the object is in now
local function observeReturn(object, cellId)
  local objectReturn = Returns[object.id]
  if not objectReturn or objectReturn.pendingMoves > 0 then return end

  objectReturn.observationsLeft = objectReturn.observationsLeft - 1

  if cellId == objectReturn.cellId or objectReturn.observationsLeft <= 0 then
    Returns[object.id] = nil
  end
end

--- Returns are saved separately from corrections. One whose move back has been issued has no
--- correction left to be rebuilt from, yet its watcher has not seen the arrival.
---@return SSSSavedReturn[] savedReturns
local function saveReturns()
  local savedReturns = {}

  for _, objectReturn in next, Returns do
    savedReturns[#savedReturns + 1] = {
      object = objectReturn.object,
      cellId = objectReturn.cellId,
      wasIssued = objectReturn.wasIssued,
      observationsLeft = objectReturn.observationsLeft,
    }
  end

  return savedReturns
end

---@param savedReturns SSSSavedReturn[]?
local function restoreReturns(savedReturns)
  Returns = {}

  if type(savedReturns) ~= 'table' then return end

  for returnIdx = 1, #savedReturns do
    local savedReturn = savedReturns[returnIdx]

    if
      type(savedReturn) == 'table'
      and staticUtil.isGObject(savedReturn.object)
      and type(savedReturn.cellId) == 'string'
      and WatchedObjectIds[savedReturn.object.id]
    then
      Returns[savedReturn.object.id] = {
        object = savedReturn.object,
        cellId = savedReturn.cellId,
        pendingMoves = 0,
        wasIssued = savedReturn.wasIssued == true,
        observationsLeft = tonumber(savedReturn.observationsLeft) or RETURN_OBSERVATIONS,
      }
    end
  end
end

--- A loaded return with no move issued and none waiting has nothing left to wait for; the
--- correction it belonged to could not be carried over.
local function dropStrandedReturns()
  for objectId, objectReturn in next, Returns do
    if objectReturn.pendingMoves <= 0 and not objectReturn.wasIssued then
      Returns[objectId] = nil
    end
  end
end

--- Corrections that are still waiting when the game is saved are saved with it. Without that,
--- a replacement that landed just before the save would be in the world after loading with
--- nothing left that knew it had to go. A cell cannot be saved, so its ID is, and the cell is
--- looked up again on load.
---@return SSSSavedCorrection[] savedCorrections
local function saveCorrections()
  local savedCorrections = {}

  for correctionIdx = firstPending, lastPending do
    local correction = PendingCorrections[correctionIdx]

    savedCorrections[#savedCorrections + 1] = {
      object = correction.object,
      attemptsLeft = correction.attemptsLeft,
      cellId = correction.cell and correction.cell.id,
      position = correction.position,
      rotation = correction.rotation,
      scale = correction.scale,
    }
  end

  return savedCorrections
end

---@param savedCorrection SSSSavedCorrection
---@return SSSPendingCorrection? correction nil when it can no longer be carried out
local function restoreCorrection(savedCorrection)
  if type(savedCorrection) ~= 'table' or not staticUtil.isGObject(savedCorrection.object) then
    return
  end

  ---@type SSSPendingCorrection
  local correction = {
    object = savedCorrection.object,
    attemptsLeft = tonumber(savedCorrection.attemptsLeft) or MAX_ATTEMPTS,
  }

  if savedCorrection.cellId == nil then return correction end

  local wasFound, cell = pcall(world.getCellById, savedCorrection.cellId)
  if not wasFound or not cell then return end

  correction.cell = cell
  correction.position = savedCorrection.position
  correction.rotation = savedCorrection.rotation
  correction.scale = savedCorrection.scale

  return correction
end

--- Returns are loaded first and the corrections after them, so each loaded move back is
--- counted against the return it belongs to.
---@param savedCorrections SSSSavedCorrection[]?
---@param savedReturns SSSSavedReturn[]?
local function loadCorrections(savedCorrections, savedReturns)
  PendingCorrections, firstPending, lastPending = {}, 1, 0
  restoreReturns(savedReturns)

  if type(savedCorrections) == 'table' then
    for correctionIdx = 1, #savedCorrections do
      local correction = restoreCorrection(savedCorrections[correctionIdx])
      if correction then enqueueNew(correction) end
    end
  end

  dropStrandedReturns()
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
  getReturn = getReturn,
  hasPending = hasPending,
  loadCorrections = loadCorrections,
  observeReturn = observeReturn,
  restoreLater = restoreLater,
  saveCorrections = saveCorrections,
  saveReturns = saveReturns,
  step = step,
  watchReturns = watchReturns,
}
