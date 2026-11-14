---@omw-context global

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local pcall, tostring = pcall, tostring
local StrFormat = string.format
local Remove = table.remove

--- Objects SSS created, could not put where they were meant to go, and then could not remove
--- either. They are kept so the removal can be tried again; forgetting one would leave it
--- outside any cell, or in the world unaccounted for, for good.
---@type openmw.GObject[]
local UnremovedObjects = {}

---@type table<string, true>
local IssuedWarnings = {}

---@param object openmw.GObject
---@return boolean wasRemoved
local function tryRemove(object)
  if not object:isValid() or object.count < 1 then return true end

  local wasRemoved, removeError = pcall(object.remove, object)
  if wasRemoved then return true end

  local warning = StrFormat(
    'An unplaced %s could not be removed and will be retried: %s',
    object.recordId,
    tostring(removeError)
  )

  if not IssuedWarnings[warning] then
    IssuedWarnings[warning] = true
    WarnLog(warning)
  end

  return false
end

local function retryPending()
  for objectIdx = #UnremovedObjects, 1, -1 do
    if tryRemove(UnremovedObjects[objectIdx]) then Remove(UnremovedObjects, objectIdx) end
  end
end

--- Removes an object that SSS created but that did not end up where it was meant to be: a
--- replacement that never took its original's place, a created object that could not be
--- placed, an item that could not be put in an inventory.
---@param object openmw.GObject
local function discard(object)
  if UnremovedObjects[1] then retryPending() end

  if not tryRemove(object) then UnremovedObjects[#UnremovedObjects + 1] = object end
end

---@return boolean hasPending whether an earlier removal is still waiting to be retried
local function hasPending() return UnremovedObjects[1] ~= nil end

---@class SSSObjectCleanup
return {
  discard = discard,
  hasPending = hasPending,
  retryPending = retryPending,
}
