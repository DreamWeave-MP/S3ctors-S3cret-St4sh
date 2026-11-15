---@omw-context global

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local TICKS_TO_DELETE = 3

--- How many frames delayed work waits for a target that reports no count before letting go.
local MAX_TRANSIT_WAITS = 8

local next, pcall, tostring = next, pcall, tostring
local remove = table.remove
local StrFormat = string.format

---@type table<string, true>
local IssuedWarnings = {}

--- Adds an object to the delete queue, to be processed on another frame
---@param object openmw.GObject
---@param removeOrDisable boolean true removes the object, false disables it
local function addObjectToDeleteQueue(self, object, removeOrDisable)
  self.queue[#self.queue + 1] = {
    object = object,
    ticks = TICKS_TO_DELETE,
    removeOrDisable = removeOrDisable,
  }
end

--- An object being moved reports a count of zero until the move lands at the end of the
--- frame, exactly as a removed object does. A target with no count is therefore waited for,
--- for a while, before its entry is let go.
---@param objectInfo ObjectDeleteData
---@return boolean isFinished false while the work still has to wait for its target
local function finishDelayedWork(objectInfo)
  local object = objectInfo.object
  if not object:isValid() then return true end

  if object.count < 1 then
    objectInfo.transitWaits = (objectInfo.transitWaits or 0) + 1
    return objectInfo.transitWaits > MAX_TRANSIT_WAITS
  end

  if objectInfo.removeOrDisable then
    object:remove()
  else
    object.enabled = false
  end

  return true
end

--- Processes delayed object deletion/disable work and removes completed queue entries.
--- An entry the engine refuses is reported and dropped. Leaving it queued would raise again on
--- every frame and keep everything behind it from being processed.
local function processDeleteQueue(self)
  for i = #self.queue, 1, -1 do
    local objectInfo = self.queue[i]

    if objectInfo.ticks > 0 then
      objectInfo.ticks = objectInfo.ticks - 1
    else
      local didRun, isFinished = pcall(finishDelayedWork, objectInfo)

      if not didRun then
        local warning =
          StrFormat('A queued removal was refused and dropped: %s', tostring(isFinished))

        if not IssuedWarnings[warning] then
          IssuedWarnings[warning] = true
          WarnLog(warning)
        end
      end

      if not didRun or isFinished then remove(self.queue, i) end
    end
  end
end

---@return boolean isEmpty whether the delete queue has no pending objects
local function queueIsEmpty(self) return next(self.queue) == nil end

---@type SSSDeleteManager
return {
  addObjectToDeleteQueue = addObjectToDeleteQueue,
  processDeleteQueue = processDeleteQueue,
  queueIsEmpty = queueIsEmpty,
  queue = {},
}
