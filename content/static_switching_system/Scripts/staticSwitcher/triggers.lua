---@omw-context global

local core = require 'openmw.core'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'
local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'

local ErrorLog, WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  ErrorLog = logger.error
  WarnLog = logger.warn
end

local assert, pcall, tostring = assert, pcall, tostring
local StrFormat = string.format

local DEBOUNCE_SECONDS = 0.25
local MAX_DEBOUNCE_ENTRIES = 256

---@type SSSModuleCatalog
local ModuleCatalog

---@type SSSInstanceModifiers
local InstanceModifiers

---@type table<string, number>
local LastDispatchTimes = {}
local debounceEntryCount = 0

local isDispatching = false

---@type table<string, true>
local ReentryWarnings = {}

--- An object taken into an inventory or container has no cell, and a removed stack has no count.
---@param object openmw.GObject
---@return boolean
local function isPlacedInWorld(object)
  return object:isValid() and object.count >= 1 and object.cell ~= nil
end

---@param object openmw.GObject
---@param triggerRules SSSTriggerRule[]
local function applyRules(object, triggerRules)
  local instanceModificationList =
    InstanceModifiers.getMatchingInstanceModules(object, triggerRules)

  if instanceModificationList then
    InstanceModifiers.tryModifyObject(object, instanceModificationList)
  end
end

--- Runs a trigger's rules on one object; a rule that throws is reported and contained.
---@param object openmw.GObject
---@param triggerRules SSSTriggerRule[]
local function runRules(object, triggerRules)
  local wasProcessed, processError = pcall(applyRules, object, triggerRules)
  if wasProcessed then return end

  ErrorLog(StrFormat('Skipped %s (%s): %s', object.id, object.recordId, tostring(processError)))
end

---@param triggerName string
---@param object openmw.GObject
---@return boolean wasDispatchedRecently
local function isDebounced(triggerName, object)
  local debounceKey = triggerName .. ':' .. object.id
  local now = core.getSimulationTime()
  local lastDispatchTime = LastDispatchTimes[debounceKey]

  if lastDispatchTime and now - lastDispatchTime < DEBOUNCE_SECONDS then return true end

  if not lastDispatchTime then
    if debounceEntryCount >= MAX_DEBOUNCE_ENTRIES then
      LastDispatchTimes = {}
      debounceEntryCount = 0
    end

    debounceEntryCount = debounceEntryCount + 1
  end

  LastDispatchTimes[debounceKey] = now
  return false
end

--- Runs the rules bound to a single-object trigger. A rule that fires another trigger while
--- this one is still running is refused, so triggers cannot recurse into each other.
---@param triggerName string
---@param object openmw.GObject object the rules run on
---@param actor openmw.GObject? actor that caused the trigger
---@param item openmw.GObject? item used, for the `use` trigger
---@return boolean wasDispatched
local function dispatch(triggerName, object, actor, item)
  local triggerRules = ModuleCatalog.RulesByTrigger[triggerName]
  if not triggerRules or not isPlacedInWorld(object) then return false end

  if isDispatching then
    if not ReentryWarnings[triggerName] then
      ReentryWarnings[triggerName] = true
      WarnLog(StrFormat('Trigger "%s" was fired from inside another trigger; ignored', triggerName))
    end

    return false
  end

  if isDebounced(triggerName, object) then return false end

  isDispatching = true
  TriggerContext.actor, TriggerContext.item = actor, item
  BatchCache.clear()

  runRules(object, triggerRules)

  TriggerContext.actor, TriggerContext.item = nil, nil
  isDispatching = false

  return true
end

---@param triggerName string
---@return boolean hasRules whether any loaded rule listens to this trigger
local function isArmed(triggerName) return ModuleCatalog.RulesByTrigger[triggerName] ~= nil end

---@class SSSTriggers
local Triggers = {
  dispatch = dispatch,
  isArmed = isArmed,
  isPlacedInWorld = isPlacedInWorld,
  runRules = runRules,
}

---@param moduleCatalog SSSModuleCatalog
---@param instanceModifiers SSSInstanceModifiers
---@return SSSTriggers
return function(moduleCatalog, instanceModifiers)
  ModuleCatalog = assert(moduleCatalog)
  InstanceModifiers = assert(instanceModifiers)
  return Triggers
end
