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

local assert, next, pcall, tostring = assert, next, pcall, tostring
local Max = math.max
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
local debounceEvictionThreshold = MAX_DEBOUNCE_ENTRIES

--- True while any rule is executing, whichever path started it: an activation, a sweep, or a
--- dispatched trigger. A trigger fired during that time comes from inside a rule's own actions.
local isRunningRules = false

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

--- Every rule execution goes through here. It marks rules as running for its whole duration,
--- so nothing a rule calls can start another execution, and it contains whatever is raised.
---@param applyToObject fun(object: openmw.GObject, triggerRules: SSSTriggerRule[])
---@param object openmw.GObject
---@param triggerRules SSSTriggerRule[]
local function runGuarded(applyToObject, object, triggerRules)
  isRunningRules = true
  local wasProcessed, processError = pcall(applyToObject, object, triggerRules)
  isRunningRules = false

  if wasProcessed then return end

  ErrorLog(StrFormat('Skipped %s (%s): %s', object.id, object.recordId, tostring(processError)))

  InstanceModifiers.abandonUncommittedPass()
end

---@param object openmw.GObject
---@param triggerRules SSSTriggerRule[]
local function runRules(object, triggerRules) runGuarded(applyRules, object, triggerRules) end

--- Only entries past the debounce window are dropped; a recent one must keep suppressing its
--- repeat. The threshold then moves past whatever is still live, so a burst is not rescanned
--- on every dispatch.
---@param now number
local function evictExpiredDebounceEntries(now)
  debounceEntryCount = 0

  for debounceKey, dispatchTime in next, LastDispatchTimes do
    if now - dispatchTime >= DEBOUNCE_SECONDS then
      LastDispatchTimes[debounceKey] = nil
    else
      debounceEntryCount = debounceEntryCount + 1
    end
  end

  debounceEvictionThreshold = Max(MAX_DEBOUNCE_ENTRIES, debounceEntryCount * 2)
end

--- Debouncing drops a repeat delivery of the same occurrence. What is used is part of the
--- occurrence: two different items used by one actor are two occurrences.
---@param triggerName string
---@param object openmw.GObject
---@param item openmw.GObject?
---@return boolean wasDispatchedRecently
local function isDebounced(triggerName, object, item)
  local debounceKey = StrFormat('%s:%s:%s', triggerName, object.id, item and item.id or '')
  local now = core.getSimulationTime()
  local lastDispatchTime = LastDispatchTimes[debounceKey]

  if lastDispatchTime and now - lastDispatchTime < DEBOUNCE_SECONDS then return true end

  if not lastDispatchTime then
    if debounceEntryCount >= debounceEvictionThreshold then evictExpiredDebounceEntries(now) end
    debounceEntryCount = debounceEntryCount + 1
  end

  LastDispatchTimes[debounceKey] = now
  return false
end

--- Runs the rules bound to a single-object trigger. A trigger fired while any rule is still
--- running is refused, so rules cannot start further rule execution from their own actions.
---@param triggerName string
---@param object openmw.GObject object the rules run on
---@param actor openmw.GObject? actor that caused the trigger
---@param item openmw.GObject? item used, for the `use` trigger
---@return boolean wasDispatched
local function dispatch(triggerName, object, actor, item)
  local triggerRules = ModuleCatalog.RulesByTrigger[triggerName]
  if not triggerRules or not isPlacedInWorld(object) then return false end

  if isRunningRules then
    if not ReentryWarnings[triggerName] then
      ReentryWarnings[triggerName] = true
      WarnLog(StrFormat('Trigger "%s" was fired while a rule was running; ignored', triggerName))
    end

    return false
  end

  if isDebounced(triggerName, object, item) then return false end

  TriggerContext.actor, TriggerContext.item = actor, item
  BatchCache.clear()

  runRules(object, triggerRules)

  TriggerContext.actor, TriggerContext.item = nil, nil

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
  runGuarded = runGuarded,
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
