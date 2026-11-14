---@omw-context global

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local TICKS_TO_DELETE = 3

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

---@param objectInfo ObjectDeleteData
local function finishDelayedWork(objectInfo)
  local object = objectInfo.object
  if not object:isValid() or object.count < 1 then return end

  if objectInfo.removeOrDisable then
    object:remove()
  else
    object.enabled = false
  end
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
      local wasFinished, refusal = pcall(finishDelayedWork, objectInfo)

      if not wasFinished then
        local warning = StrFormat('A queued removal was refused and dropped: %s', tostring(refusal))

        if not IssuedWarnings[warning] then
          IssuedWarnings[warning] = true
          WarnLog(warning)
        end
      end

      remove(self.queue, i)
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
