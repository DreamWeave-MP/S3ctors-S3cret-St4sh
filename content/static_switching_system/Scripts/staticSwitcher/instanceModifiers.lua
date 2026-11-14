---@omw-context global

local staticUtil = require 'Scripts.staticSwitcher.util'

local randomGen = require 'scripts.s3.randomGen'

local types = require 'openmw.types'

local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'
local conditionHandlers = require 'Scripts.staticSwitcher.conditionHandlers'

local DebugLog, WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  DebugLog = logger.debug
  WarnLog = logger.warn
end

local StrFormat = string.format

local next, pcall, tostring = next, pcall, tostring

local PlayerObjectIsInstance = types.Player.objectIsInstance

---@type table<string, true>
local ActionFailureWarnings = {}

---@param actionName string
---@param failure string
local function reportActionFailure(actionName, failure)
  local warning = StrFormat('Action %s failed and was skipped: %s', actionName, tostring(failure))
  if ActionFailureWarnings[warning] then return end
  ActionFailureWarnings[warning] = true

  WarnLog(warning)
end

--- Actions whose handler hands an authored ID or payload straight to the engine or to another
--- mod, and has no boundary of its own. Whether such a call succeeds depends on the load order
--- and cannot be checked when a module loads, so a refusal is an expected outcome, not a bug.
---
--- Everything else is left unwrapped on purpose. Handlers that already contain their own
--- boundary, including the item and spell actions that guard each entry, do not need a second one, and handlers that only compute must not have one: an
--- error there is a programming error and has to reach the per-object guard and be reported
--- as one, not be turned into a quietly skipped action.
local ENGINE_BOUNDARY_ACTIONS = {
  activate_by_player = true,
  add_lua_script = true,
  add_tag = true,
  global_set = true,
  key = true,
  lock_level = true,
  playsound = true,
  remove_lua_script = true,
  remove_tag = true,
  send_event = true,
  send_global_event = true,
  set_ownership = true,
  teleport = true,
  trap = true,
}

--- A refused engine call is treated as an action that did not apply. The rest of its rule
--- still runs and the rule is finalised, so `once` is recorded for whatever did apply.
---@param actionName string
---@param actionHandler function
---@return function guardedHandler
local function guardEngineBoundary(actionName, actionHandler)
  return function(object, actionData, third, fourth, fifth)
    local didRun, first, second, thirdResult, fourthResult, fifthResult =
      pcall(actionHandler, object, actionData, third, fourth, fifth)

    if didRun then return first, second, thirdResult, fourthResult, fifthResult end

    reportActionFailure(actionName, first)
    return false
  end
end

---@type table<string, function>
local actionHandlers = {}
for actionName, actionHandler in next, require 'Scripts.staticSwitcher.actionHandlers' do
  actionHandlers[actionName] = ENGINE_BOUNDARY_ACTIONS[actionName]
      and guardEngineBoundary(actionName, actionHandler)
    or actionHandler
end

--- Migration/default handling: versioned separately from the global save shape;
--- missing or unknown once-cache versions are treated as empty caches so old saves load safely.
local ONCE_CACHE_SCHEMA_VERSION = 1

---@type SSSOnceCache
local OnceCache = {
  entries = {},
  byObjectId = {},
}

--- Runtime-only activation-batch tracking set.
--- Tracks "object.id:moduleName:actionHash" for rules with once="per_cell".
--- Cleared at the start of each new activation batch (onObjectActive when the
--- stack was empty). Marked entries suppress re-processing of objects that
--- were already modified in this activation batch, including replacement objects.
--- Not saved — only lives for the current runtime session.
---@type table<string, true>
local PerCellApplied = {}

local AND_LIST_CONDITIONS = {
  global_value = true,
}

---@type SSSModuleCatalog
local ModuleCatalog

---@type SSSDeleteManager
local DeleteManager

local assert, error, pairs, type = assert, error, pairs, type

local function resetOnceCache()
  OnceCache = {
    entries = {},
    byObjectId = {},
  }
end

local function pruneOnceCache()
  local prunedEntries, prunedEntryCount, prunedByObjectId = {}, 0, {}

  for entryIndex = 1, #OnceCache.entries do
    local entry = OnceCache.entries[entryIndex]
    local object = entry.object

    if staticUtil.isGObject(object) and object:isValid() then
      prunedEntryCount = prunedEntryCount + 1
      prunedEntries[prunedEntryCount] = entry
      prunedByObjectId[object.id] = entry
    end
  end

  OnceCache.entries = prunedEntries
  OnceCache.byObjectId = prunedByObjectId
end

---@param object openmw.GObject
---@return SSSOnceCacheEntry entry
local function getOrCreateOnceCacheEntry(object)
  local objectId = object.id
  local entry = OnceCache.byObjectId[objectId]

  if not entry then
    entry = {
      object = object,
      modules = {},
    }

    OnceCache.byObjectId[objectId] = entry
    OnceCache.entries[#OnceCache.entries + 1] = entry
  end

  return entry
end

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
---@return boolean
local function onceActionWasApplied(object, moduleName, actionHash)
  local entry = OnceCache.byObjectId[object.id]
  local moduleActions = entry and entry.modules[moduleName]

  return (moduleActions and moduleActions[actionHash] == true) or false
end

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
local function markOnceActionApplied(object, moduleName, actionHash)
  local entry = getOrCreateOnceCacheEntry(object)
  local moduleActions = entry.modules[moduleName]

  if not moduleActions then
    moduleActions = {}
    entry.modules[moduleName] = moduleActions
  end

  moduleActions[actionHash] = true
end

--- A replacement stands in for the object it replaced, so every once mark follows it.
--- Otherwise the replacement is a fresh object that the same rule can match again.
---@param source openmw.GObject
---@param replacement openmw.GObject
local function inheritOnceActions(source, replacement)
  local sourceEntry = OnceCache.byObjectId[source.id]
  if not sourceEntry then return end

  local replacementModules = getOrCreateOnceCacheEntry(replacement).modules

  for moduleName, moduleActions in next, sourceEntry.modules do
    local replacementActions = replacementModules[moduleName]

    if not replacementActions then
      replacementActions = {}
      replacementModules[moduleName] = replacementActions
    end

    for actionHash in next, moduleActions do
      replacementActions[actionHash] = true
    end
  end
end

---
--- Activation-batch tracking helpers
---

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
---@return string
local function perCellKey(object, moduleName, actionHash)
  return StrFormat('%s:%s:%s', object.id, moduleName, actionHash)
end

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
---@return boolean
local function wasAppliedThisLoad(object, moduleName, actionHash)
  return PerCellApplied[perCellKey(object, moduleName, actionHash)] == true
end

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
local function markAppliedThisLoad(object, moduleName, actionHash)
  PerCellApplied[perCellKey(object, moduleName, actionHash)] = true
end

--- Clears the per-cell tracking table. Called from the activation listener when
--- the ActiveObjectStack was empty, indicating a fresh activation batch.
local function clearPerCellTracking()
  DebugLog 'Cleared per-cell tracking for new activation batch'
  PerCellApplied = {}
end

---@param savedOnceCache SSSOnceCacheSaved?
local function loadOnceCache(savedOnceCache)
  resetOnceCache()

  if
    type(savedOnceCache) ~= 'table'
    or savedOnceCache.schemaVersion ~= ONCE_CACHE_SCHEMA_VERSION
    or type(savedOnceCache.entries) ~= 'table'
  then
    return
  end

  for savedIndex = 1, #savedOnceCache.entries do
    local savedEntry = savedOnceCache.entries[savedIndex]
    if type(savedEntry) ~= 'table' then error 'Once cache entry must be a table!' end

    local object, modules = savedEntry.object, savedEntry.modules

    if not staticUtil.isGObject(object) then
      error 'Once cache entry object must be an openmw.GObject!'
    end
    if type(modules) ~= 'table' then error 'Once cache entry modules must be a table!' end

    if object:isValid() then
      local entry = { object = object, modules = {} }

      for moduleName, moduleActions in pairs(modules) do
        if type(moduleName) ~= 'string' then error 'Once cache module name must be a string!' end
        if type(moduleActions) ~= 'table' then
          error 'Once cache module actions must be a table!'
        end

        local moduleId = ModuleCatalog.resolveModuleId(moduleName) or moduleName

        local copiedModuleActions = {}

        for actionHash, wasApplied in pairs(moduleActions) do
          if type(actionHash) ~= 'string' then error 'Once cache action hash must be a string!' end
          if wasApplied ~= true then error 'Once cache action value must be true!' end

          copiedModuleActions[actionHash] = true
        end

        entry.modules[moduleId] = copiedModuleActions
      end

      OnceCache.byObjectId[object.id] = entry
      OnceCache.entries[#OnceCache.entries + 1] = entry
    end
  end
end

---@return SSSOnceCacheSaved
local function saveOnceCache()
  pruneOnceCache()

  return {
    -- Migration/default handling lives in loadOnceCache: unknown versions load as empty.
    schemaVersion = ONCE_CACHE_SCHEMA_VERSION,
    entries = OnceCache.entries,
  }
end

---@param object openmw.GObject
---@param conditions SSSConditionData[]
---@return boolean
local function matchesAllConditions(object, conditions)
  for condIndex = 1, #conditions do
    local conditionData = conditions[condIndex]
    for conditionName, conditionValue in pairs(conditionData) do
      local conditionHandler = conditionHandlers[conditionName]

      if type(conditionHandler) ~= 'function' then
        error(StrFormat('Condition %s is an invalid condition for the handler!', conditionName))
      end

      if type(conditionValue) == 'table' then
        -- Array-like tables are OR-lists: any element may match.
        -- Map-like tables (string/non-integer keys) are passed as-is to the handler.
        local firstKey = next(conditionValue)
        local isOrList = firstKey and type(firstKey) == 'number'

        if isOrList and not AND_LIST_CONDITIONS[conditionName] then
          local matchedAnyValue = false

          for indivIndex = 1, #conditionValue do
            if not matchedAnyValue and conditionHandler(object, conditionValue[indivIndex]) then
              matchedAnyValue = true
              break
            end
          end

          if not matchedAnyValue then
            DebugLog('Condition %s OR-list FAIL for %s', conditionName, object.id)
            return false
          end
        elseif not conditionHandler(object, conditionValue) then
          DebugLog('Condition %s FAIL for %s', conditionName, object.id)
          return false
        end
      else
        if not conditionHandler(object, conditionValue) then
          DebugLog(
            'Condition %s=%s FAIL for %s',
            conditionName,
            tostring(conditionValue),
            object.id
          )
          return false
        end
      end
    end
  end

  return true
end

---@param object openmw.GObject
---@param triggerRules SSSTriggerRule[] rules bound to the trigger being processed, in evaluation order
---@return SSSInstanceModificationList?
local function getMatchingInstanceModules(object, triggerRules)
  local matchingActions, actionIndex

  for ruleIdx = 1, #triggerRules do
    local triggerRule = triggerRules[ruleIdx]
    local moduleName, moduleOnce, actionData =
      triggerRule.moduleName, triggerRule.moduleOnce, triggerRule.rule

    local actionTableHash = actionData.actionHash
    local skipReason

    if actionData.once == true and onceActionWasApplied(object, moduleName, actionTableHash) then
      skipReason = 'once=true already applied'
    end

    -- Per-cell once: only skip for this activation batch; not saved
    if
      not skipReason
      and actionData.once == 'per_cell'
      and wasAppliedThisLoad(object, moduleName, actionTableHash)
    then
      skipReason = 'once=per_cell already applied this activation batch'
    end

    -- Module-level once: skip all rules for this module if any rule has already applied
    if not skipReason and moduleOnce and onceActionWasApplied(object, moduleName, '*') then
      skipReason = 'module once=true already applied'
    end

    if not skipReason then
      local conditionsPassed = not actionData.conditions
        or matchesAllConditions(object, actionData.conditions)

      if not conditionsPassed then skipReason = 'conditions failed' end
    end

    if skipReason then
      DebugLog('SKIP %s/%s on %s: %s', moduleName, actionTableHash, object.id, skipReason)
    else
      matchingActions = matchingActions or {}
      actionIndex = (actionIndex or 0) + 1
      matchingActions[actionIndex] = {
        moduleName = moduleName,
        actionHash = actionTableHash,
        once = actionData.once,
        moduleOnce = moduleOnce,
        actions = actionData.actions,
      }
    end
  end

  if matchingActions then
    DebugLog('MATCH %d rule(s) for %s (%s)', #matchingActions, object.id, object.recordId or '?')
  end

  return matchingActions
end

--- A replacement created by a rule that has not yet been placed in the world.
---@type openmw.GObject?
local UncommittedReplacement

---@param object openmw.GObject
---@param modifyTarget openmw.GObject
---@param replaceAction SSSReplaceAction
---@return openmw.GObject modifyTarget
---@return boolean wasModified
local function tryApplyReplacement(object, modifyTarget, replaceAction)
  local foundReplacement = actionHandlers.replace(object, replaceAction)
  if not foundReplacement then return modifyTarget, false end

  UncommittedReplacement = foundReplacement
  return foundReplacement, true
end

--- Removes a replacement that was created but never took its original's place. The original
--- is only disabled once its replacement has been placed, so whatever interrupts a rule in
--- between leaves the original exactly as it was and only this object to clear away.
local function discardUncommittedReplacement()
  local replacement = UncommittedReplacement
  if not replacement then return end
  UncommittedReplacement = nil

  if replacement:isValid() then replacement:remove() end
end

--- Records a rule as applied to an object under whichever once policy the rule declares.
---@param object openmw.GObject
---@param modifyTarget openmw.GObject the object or the replacement that now stands in for it
---@param instanceModification SSSInstanceModification
local function recordRuleApplied(object, modifyTarget, instanceModification)
  local moduleName, actionHash = instanceModification.moduleName, instanceModification.actionHash

  if instanceModification.once == true then
    markOnceActionApplied(object, moduleName, actionHash)
    DebugLog('  once=true cached: %s/%s', moduleName, actionHash)
  end

  if instanceModification.once == 'per_cell' then
    markAppliedThisLoad(object, moduleName, actionHash)
    -- Also mark the replacement target so fresh activations skip re-processing
    if modifyTarget ~= object then markAppliedThisLoad(modifyTarget, moduleName, actionHash) end
    DebugLog('  once=per_cell marked: %s/%s', moduleName, actionHash)
  end

  if instanceModification.moduleOnce then
    markOnceActionApplied(object, moduleName, '*')
    DebugLog('  module once=true cached: %s', moduleName)
  end
end

--- Placement is committed once, after every rule has had its say. The engine can refuse it.
---@param target openmw.GObject
---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@param rotation openmw.util.Transform
---@param scale number
---@param onGround boolean?
local function commitPlacement(target, cell, position, rotation, scale, onGround)
  target:setScale(scale)

  local teleportOptions = { rotation = rotation }
  if onGround then teleportOptions.onGround = true end

  target:teleport(cell, position, teleportOptions)
end

--- Replacing, transforming and teleporting only take effect when placement is committed at the
--- end, so a rule that did nothing else is recorded as applied only once that has succeeded.
--- A rule whose other actions applied is recorded straight away: those did happen and must
--- not repeat, whatever becomes of the placement.
---@param object openmw.GObject
---@param instanceModificationList SSSInstanceModificationList
local function tryModifyObject(object, instanceModificationList)
  local anyActionApplied = false
  local needsPlacementUpdate = false
  local shouldDisable = false
  local shouldDelete = false
  local modifyTarget = object
  local objectId = object.id
  local moduleOnceApplied = {}

  ---@type SSSInstanceModificationList?
  local placementDependentRules
  --- Do replacements first, then transforms, then item additions/removals, then spells

  local newTransform, newPos, newCell, targetScale =
    object.rotation, object.position, object.cell, object.scale
  local teleportOnGround

  DebugLog(
    'APPLY %d rule(s) to %s (%s)',
    #instanceModificationList,
    objectId,
    object.recordId or '?'
  )

  for modIndex = 1, #instanceModificationList do
    local instanceModification = instanceModificationList[modIndex]
    local currentRuleApplied = false
    local currentRuleNeedsPlacement = false

    if
      not (instanceModification.moduleOnce and moduleOnceApplied[instanceModification.moduleName])
    then
      for actIndex = 1, #instanceModification.actions do
        local actionData = instanceModification.actions[actIndex]
        if not actionData.chance or randomGen.float() <= actionData.chance then
          local replaceAction, transformAction, addAction, removeAction, equipAction, unequipAction, disableAction, deleteAction, createAction, lockLevelAction, setOwnershipAction, playsoundAction, keyAction, trapAction, addLuaScriptAction, activateByPlayerAction, removeLuaScriptAction, globalSetAction, teleportAction, addTagAction, removeTagAction, setWeatherAction =
            actionData.replace,
            actionData.transform,
            actionData.add,
            actionData.remove,
            actionData.equip,
            actionData.unequip,
            actionData.disable,
            actionData.delete,
            actionData.create,
            actionData.lock_level,
            actionData.set_ownership,
            actionData.playsound,
            actionData.key,
            actionData.trap,
            actionData.add_lua_script,
            actionData.activate_by_player,
            actionData.remove_lua_script,
            actionData.global_set,
            actionData.teleport,
            actionData.add_tag,
            actionData.remove_tag,
            actionData.set_weather
          local addSpellAction, removeSpellAction, addActiveSpellAction, runLuaScriptAction, callInterfaceAction, sendEventAction, sendGlobalEventAction =
            actionData.add_spell,
            actionData.remove_spell,
            actionData.add_active_spell,
            actionData.run_lua_script,
            actionData.call_interface,
            actionData.send_event,
            actionData.send_global_event
          local replaceActionSucceeded = false

          --- Should we allow only one successful replacement???
          if replaceAction and modifyTarget == object then
            local didReplace
            modifyTarget, didReplace = tryApplyReplacement(object, modifyTarget, replaceAction)
            replaceActionSucceeded = didReplace
            anyActionApplied = anyActionApplied or didReplace
            needsPlacementUpdate = needsPlacementUpdate or didReplace
            currentRuleNeedsPlacement = currentRuleNeedsPlacement or didReplace
            DebugLog(
              '  replace on %s: %s',
              objectId,
              didReplace and 'OK' or 'failed (no matching roll)'
            )
            if didReplace and instanceModification.once == 'per_cell' then
              markAppliedThisLoad(
                modifyTarget,
                instanceModification.moduleName,
                instanceModification.actionHash
              )
            end
          end

          if transformAction then
            local didTransform
            didTransform, newTransform, newPos, targetScale = actionHandlers.transform(
              modifyTarget,
              transformAction,
              newTransform,
              newPos,
              targetScale
            )
            anyActionApplied = anyActionApplied or didTransform
            needsPlacementUpdate = needsPlacementUpdate or didTransform
            currentRuleNeedsPlacement = currentRuleNeedsPlacement or didTransform
            if didTransform then
              teleportOnGround = nil
              DebugLog('  transform on %s: scale=%.3f', objectId, targetScale)
            end
          end

          if teleportAction then
            local didTeleport, targetCell, targetPos, targetTransform, onGround =
              actionHandlers.teleport(modifyTarget, teleportAction, newCell, newPos, newTransform)

            if didTeleport then
              newCell = targetCell
              newPos = targetPos
              newTransform = targetTransform
              teleportOnGround = onGround
              needsPlacementUpdate = true
            end

            anyActionApplied = anyActionApplied or didTeleport
            currentRuleNeedsPlacement = currentRuleNeedsPlacement or didTeleport
            DebugLog('  teleport on %s: %s', objectId, didTeleport and 'OK' or 'failed')
          end

          if setOwnershipAction then
            local didSet = actionHandlers.set_ownership(modifyTarget, setOwnershipAction)
            anyActionApplied = anyActionApplied or didSet
            currentRuleApplied = currentRuleApplied or didSet
            DebugLog('  set_ownership on %s: %s', objectId, didSet and 'OK' or 'noop')
          end

          if addTagAction then
            local didAddTag = actionHandlers.add_tag(modifyTarget, addTagAction)
            anyActionApplied = anyActionApplied or didAddTag
            currentRuleApplied = currentRuleApplied or didAddTag
            DebugLog('  add_tag on %s: %s', objectId, didAddTag and 'OK' or 'unavailable')
          end

          if removeTagAction then
            local didRemoveTag = actionHandlers.remove_tag(modifyTarget, removeTagAction)
            anyActionApplied = anyActionApplied or didRemoveTag
            currentRuleApplied = currentRuleApplied or didRemoveTag
            DebugLog('  remove_tag on %s: %s', objectId, didRemoveTag and 'OK' or 'unavailable')
          end

          if addAction then
            local didAdd = actionHandlers.add(modifyTarget, addAction)
            anyActionApplied = anyActionApplied or didAdd
            currentRuleApplied = currentRuleApplied or didAdd
            DebugLog('  add on %s: %s', objectId, didAdd and 'OK' or 'failed')
          end

          if removeAction then
            local didRemove = actionHandlers.remove(modifyTarget, removeAction)
            anyActionApplied = anyActionApplied or didRemove
            currentRuleApplied = currentRuleApplied or didRemove
            DebugLog('  remove on %s: %s', objectId, didRemove and 'OK' or 'nothing to remove')
          end

          if equipAction then
            local didEquip = actionHandlers.equip(modifyTarget, equipAction)
            anyActionApplied = anyActionApplied or didEquip
            currentRuleApplied = currentRuleApplied or didEquip
            DebugLog('  equip on %s: %s', objectId, didEquip and 'OK' or 'failed')
          end

          if unequipAction then
            local didUnequip = actionHandlers.unequip(modifyTarget, unequipAction)
            anyActionApplied = anyActionApplied or didUnequip
            currentRuleApplied = currentRuleApplied or didUnequip
            DebugLog(
              '  unequip on %s: %s',
              objectId,
              didUnequip and 'OK' or 'failed (not equipped)'
            )
          end

          if addSpellAction then
            local didAddSpell = actionHandlers.add_spell(modifyTarget, addSpellAction)
            anyActionApplied = anyActionApplied or didAddSpell
            currentRuleApplied = currentRuleApplied or didAddSpell
            DebugLog('  add_spell on %s: %s', objectId, didAddSpell and 'OK' or 'noop')
          end

          if removeSpellAction then
            local didRemoveSpell = actionHandlers.remove_spell(modifyTarget, removeSpellAction)
            anyActionApplied = anyActionApplied or didRemoveSpell
            currentRuleApplied = currentRuleApplied or didRemoveSpell
            DebugLog('  remove_spell on %s: %s', objectId, didRemoveSpell and 'OK' or 'noop')
          end

          if addActiveSpellAction then
            local didAddActiveSpell =
              actionHandlers.add_active_spell(modifyTarget, addActiveSpellAction)
            anyActionApplied = anyActionApplied or didAddActiveSpell
            currentRuleApplied = currentRuleApplied or didAddActiveSpell
            DebugLog('  add_active_spell on %s: %s', objectId, didAddActiveSpell and 'OK' or 'noop')
          end

          if lockLevelAction then
            local didLock = actionHandlers.lock_level(modifyTarget, lockLevelAction)
            anyActionApplied = anyActionApplied or didLock
            currentRuleApplied = currentRuleApplied or didLock
            DebugLog(
              '  lock_level on %s: %s',
              objectId,
              didLock and 'OK' or 'failed (not lockable)'
            )
          end

          if keyAction then
            local didKey = actionHandlers.key(modifyTarget, keyAction)
            anyActionApplied = anyActionApplied or didKey
            currentRuleApplied = currentRuleApplied or didKey
            DebugLog('  key on %s: %s', objectId, didKey and 'OK' or 'failed (not lockable)')
          end

          if trapAction then
            local didTrap = actionHandlers.trap(modifyTarget, trapAction)
            anyActionApplied = anyActionApplied or didTrap
            currentRuleApplied = currentRuleApplied or didTrap
            DebugLog('  trap on %s: %s', objectId, didTrap and 'OK' or 'failed (not lockable)')
          end

          if createAction then
            local numCreated, createdObjects = actionHandlers.create(
              modifyTarget,
              createAction,
              newCell,
              newPos,
              newTransform,
              targetScale
            )
            if numCreated > 0 then
              anyActionApplied = true
              currentRuleApplied = true
              DebugLog('  create on %s: %d spawned', objectId, numCreated)

              if instanceModification.once == 'per_cell' then
                for objIdx = 1, numCreated do
                  markAppliedThisLoad(
                    createdObjects[objIdx],
                    instanceModification.moduleName,
                    instanceModification.actionHash
                  )
                end
              end
            end
          end

          if globalSetAction then
            local didSet = actionHandlers.global_set(modifyTarget, globalSetAction)
            anyActionApplied = anyActionApplied or didSet
            currentRuleApplied = currentRuleApplied or didSet
            DebugLog('  global_set: %s', didSet and 'OK' or 'failed')
          end

          if setWeatherAction then
            local didSetWeather = actionHandlers.set_weather(modifyTarget, setWeatherAction)
            anyActionApplied = anyActionApplied or didSetWeather
            currentRuleApplied = currentRuleApplied or didSetWeather
            DebugLog('  set_weather: %s', didSetWeather and 'OK' or 'noop')
          end

          if playsoundAction then
            local didPlay = actionHandlers.playsound(modifyTarget, playsoundAction)
            anyActionApplied = anyActionApplied or didPlay
            currentRuleApplied = currentRuleApplied or didPlay
            DebugLog('  playsound on %s: %s', objectId, didPlay and 'OK' or 'miss')
          end

          if addLuaScriptAction then
            local didAdd = actionHandlers.add_lua_script(modifyTarget, addLuaScriptAction)
            anyActionApplied = anyActionApplied or didAdd
            currentRuleApplied = currentRuleApplied or didAdd
            DebugLog('  add_lua_script on %s: %s', objectId, didAdd and 'OK' or 'already attached')
          end

          if activateByPlayerAction then
            local didActivate = actionHandlers.activate_by_player(modifyTarget)
            anyActionApplied = anyActionApplied or didActivate
            currentRuleApplied = currentRuleApplied or didActivate
            DebugLog('  activate_by_player on %s: %s', objectId, didActivate and 'OK' or 'failed')
          end

          if removeLuaScriptAction then
            local didRemove = actionHandlers.remove_lua_script(modifyTarget, removeLuaScriptAction)
            anyActionApplied = anyActionApplied or didRemove
            currentRuleApplied = currentRuleApplied or didRemove
            DebugLog(
              '  remove_lua_script on %s: %s',
              objectId,
              didRemove and 'OK' or 'not attached'
            )
          end

          if runLuaScriptAction then
            local didRun = actionHandlers.run_lua_script(modifyTarget, runLuaScriptAction)
            anyActionApplied = anyActionApplied or didRun
            currentRuleApplied = currentRuleApplied or didRun
            DebugLog('  run_lua_script on %s: %s', objectId, didRun and 'OK' or 'failed')
          end

          if callInterfaceAction then
            local didCall = actionHandlers.call_interface(modifyTarget, callInterfaceAction)
            anyActionApplied = anyActionApplied or didCall
            currentRuleApplied = currentRuleApplied or didCall
            DebugLog('  call_interface on %s: %s', objectId, didCall and 'OK' or 'failed')
          end

          if sendEventAction then
            local didSend = actionHandlers.send_event(modifyTarget, sendEventAction)
            anyActionApplied = anyActionApplied or didSend
            currentRuleApplied = currentRuleApplied or didSend
            DebugLog(
              '  send_event %s on %s: %s',
              sendEventAction.name,
              objectId,
              didSend and 'OK' or 'failed'
            )
          end

          if sendGlobalEventAction then
            local didSend = actionHandlers.send_global_event(modifyTarget, sendGlobalEventAction)
            anyActionApplied = anyActionApplied or didSend
            currentRuleApplied = currentRuleApplied or didSend
            DebugLog(
              '  send_global_event %s: %s',
              sendGlobalEventAction.name,
              didSend and 'OK' or 'failed'
            )
          end

          if disableAction then
            local didDisable = actionHandlers.disable(modifyTarget, disableAction)
            DebugLog('  disable on %s: roll=%s', objectId, didDisable and 'OK' or 'miss')
            if didDisable then
              shouldDisable = true
              anyActionApplied = true
              currentRuleApplied = true
            end
          end

          if deleteAction then
            local didDelete =
              actionHandlers.delete(object, deleteAction, replaceAction, replaceActionSucceeded)
            if didDelete then
              shouldDelete = true
              anyActionApplied = true
              currentRuleApplied = true
              DebugLog('  delete on %s', objectId)
            end
          end
        else
          DebugLog('  chance miss on %s: %.2f', objectId, actionData.chance)
        end
      end

      if currentRuleApplied then
        recordRuleApplied(object, modifyTarget, instanceModification)
      elseif currentRuleNeedsPlacement then
        placementDependentRules = placementDependentRules or {}
        placementDependentRules[#placementDependentRules + 1] = instanceModification
      end

      if instanceModification.moduleOnce and (currentRuleApplied or currentRuleNeedsPlacement) then
        moduleOnceApplied[instanceModification.moduleName] = true
      end
    end
  end

  if not anyActionApplied then return end

  local wasPlacementCommitted = not needsPlacementUpdate

  if needsPlacementUpdate then
    local sendsPlayerElsewhere = PlayerObjectIsInstance(modifyTarget)
      and newCell.id ~= object.cell.id

    local placeError
    wasPlacementCommitted, placeError = pcall(
      commitPlacement,
      modifyTarget,
      newCell,
      newPos,
      newTransform,
      targetScale,
      teleportOnGround
    )

    if not wasPlacementCommitted then
      reportActionFailure('placement', placeError)
    elseif sendsPlayerElsewhere then
      TriggerContext.expectedPlayerCellId = newCell.id
    end
  end

  if not wasPlacementCommitted and modifyTarget ~= object then
    discardUncommittedReplacement()
    return
  end

  if wasPlacementCommitted then
    if placementDependentRules then
      for ruleIdx = 1, #placementDependentRules do
        recordRuleApplied(object, modifyTarget, placementDependentRules[ruleIdx])
      end
    end

    if modifyTarget ~= object then
      UncommittedReplacement = nil
      inheritOnceActions(object, modifyTarget)
      object.enabled = false
    end
  end

  if shouldDisable and modifyTarget:isValid() then modifyTarget.enabled = false end

  if shouldDelete and object:isValid() then DeleteManager:addObjectToDeleteQueue(object, true) end
end

---@class SSSInstanceModifiers
local InstanceModifiers = {
  getMatchingInstanceModules = getMatchingInstanceModules,
  loadOnceCache = loadOnceCache,
  saveOnceCache = saveOnceCache,
  tryModifyObject = tryModifyObject,
  discardUncommittedReplacement = discardUncommittedReplacement,
  clearPerCellTracking = clearPerCellTracking,
}

---@param moduleCatalog SSSModuleCatalog
---@param deleteManager SSSDeleteManager
---@return SSSInstanceModifiers
return function(moduleCatalog, deleteManager)
  ModuleCatalog = assert(moduleCatalog)
  DeleteManager = assert(deleteManager)
  return InstanceModifiers
end
