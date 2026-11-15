---@omw-context global

local staticUtil = require 'Scripts.staticSwitcher.util'

local randomGen = require 'scripts.s3.randomGen'

local types = require 'openmw.types'

local ObjectCleanup = require 'Scripts.staticSwitcher.objectCleanup'
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

---@param object openmw.GObject
---@param isEnabled boolean
local function setEnabled(object, isEnabled) object.enabled = isEnabled end

--- How many cell polls a player being put back is given to arrive before entries count again.
local PLAYER_RETURN_POLLS = 6

--- What the running pass has started and not yet committed. If the pass is abandoned, this is
--- what has to be put right.
---@type SSSUncommittedPass
local Uncommitted = {
  enabledWasChanged = false,
  sentPlayerElsewhere = false,
  wasMoved = false,
}

local function clearUncommitted()
  Uncommitted.original, Uncommitted.replacement = nil, nil
  Uncommitted.cell, Uncommitted.position, Uncommitted.rotation = nil, nil, nil
  Uncommitted.enabledWasChanged, Uncommitted.sentPlayerElsewhere, Uncommitted.wasMoved =
    false, false, false
end

---@param object openmw.GObject
---@param modifyTarget openmw.GObject
---@param replaceAction SSSReplaceAction
---@return openmw.GObject modifyTarget
---@return boolean wasModified
local function tryApplyReplacement(object, modifyTarget, replaceAction)
  local foundReplacement = actionHandlers.replace(object, replaceAction)
  if not foundReplacement then return modifyTarget, false end

  Uncommitted.replacement = foundReplacement
  return foundReplacement, true
end

--- Puts right whatever an abandoned pass had started, so the object is left as it was found.
---
--- A move the engine has accepted cannot be called off; it is applied at the end of the frame.
--- A replacement that is already on its way is therefore removed once it has landed, and an
--- object that was moved is put back once it has arrived. Both are left to ObjectCleanup,
--- which waits for that. The original's enabled state is restored to what it was, which is
--- not always enabled.
---
--- A player sent elsewhere arrives there first and is then put back. Neither arrival is an
--- entry, so the cell poll is told where the player is being returned to.
local function abandonUncommittedPass()
  local original, replacement = Uncommitted.original, Uncommitted.replacement

  if replacement then ObjectCleanup.discard(replacement) end

  if original then
    if Uncommitted.wasMoved then
      ObjectCleanup.restoreLater(
        original,
        Uncommitted.cell,
        Uncommitted.position,
        Uncommitted.rotation,
        Uncommitted.scale
      )
    end

    if Uncommitted.enabledWasChanged then
      local wasRestored, restoreError = pcall(setEnabled, original, Uncommitted.wasEnabled)
      if not wasRestored then reportActionFailure('rollback', restoreError) end
    end
  end

  if Uncommitted.sentPlayerElsewhere then
    TriggerContext.expectedPlayerCellId = nil
    TriggerContext.playerReturnCellId = Uncommitted.cell.id
    TriggerContext.playerReturnPollsLeft = PLAYER_RETURN_POLLS
  end

  clearUncommitted()
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

--- Placement is committed once, after every rule has had its say. It is the one step of a
--- commit the engine can refuse outright: the cell may not exist, or the object may already be
--- on its way somewhere. Once it returns, the move will happen at the end of the frame.
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

--- Placement asks for the scale before it asks for the move. When the move is refused, an
--- object that already existed must not keep that scale, or a relative scale would compound
--- on the next attempt.
---@param object openmw.GObject
---@param scale number the scale the object had before the rules ran
local function restoreScale(object, scale)
  local wasRestored, restoreError = pcall(object.setScale, object, scale)
  if not wasRestored then reportActionFailure('scale restore', restoreError) end
end

--- When a rule is recorded as applied depends on where each effect lives, not only on whether
--- its handler reported success:
---
--- * An effect outside the target (an event, a created object, a global, the weather) cannot be
---   taken back, so the rule is recorded the moment it happens. Whatever goes wrong afterwards,
---   it does not happen twice.
--- * An effect on the target lasts if the target is the original object. On a replacement it
---   lasts only if the replacement is placed.
--- * Replacing, transforming, teleporting, disabling and deleting only take effect when the
---   pass is committed at the end.
---
--- A rule with only the last two kinds is recorded once the commit has succeeded.
---@type SSSRuleExecution
local Execution = {
  hadAnyEffect = false,
  isRuleRecorded = false,
  ruleAwaitsCommit = false,
  ruleHadEffect = false,
}

---@param didApply boolean
local function noteLastingEffect(didApply)
  if not didApply then return end

  Execution.hadAnyEffect, Execution.ruleHadEffect = true, true

  if Execution.isRuleRecorded then return end
  Execution.isRuleRecorded = true

  recordRuleApplied(Execution.object, Execution.target, Execution.rule)
end

---@param didApply boolean
local function noteCommitEffect(didApply)
  if not didApply then return end

  Execution.hadAnyEffect, Execution.ruleHadEffect, Execution.ruleAwaitsCommit = true, true, true
end

---@param didApply boolean
local function noteTargetEffect(didApply)
  if Execution.target == Execution.object then
    noteLastingEffect(didApply)
  else
    noteCommitEffect(didApply)
  end
end

---@param object openmw.GObject
---@param instanceModificationList SSSInstanceModificationList
local function tryModifyObject(object, instanceModificationList)
  local needsPlacementUpdate = false
  local shouldDisable = false
  local shouldDelete = false
  local modifyTarget = object
  local objectId = object.id
  local moduleOnceApplied = {}

  ---@type SSSInstanceModificationList?
  local commitDependentRules
  --- Do replacements first, then transforms, then item additions/removals, then spells

  local originalRotation, originalPosition, originalCell, originalScale =
    object.rotation, object.position, object.cell, object.scale
  local newTransform, newPos, newCell, targetScale =
    originalRotation, originalPosition, originalCell, originalScale
  local teleportOnGround

  Execution.object, Execution.target, Execution.hadAnyEffect = object, object, false

  clearUncommitted()
  Uncommitted.original, Uncommitted.wasEnabled = object, object.enabled
  Uncommitted.cell, Uncommitted.position, Uncommitted.rotation, Uncommitted.scale =
    originalCell, originalPosition, originalRotation, originalScale

  DebugLog(
    'APPLY %d rule(s) to %s (%s)',
    #instanceModificationList,
    objectId,
    object.recordId or '?'
  )

  for modIndex = 1, #instanceModificationList do
    local instanceModification = instanceModificationList[modIndex]
    Execution.rule = instanceModification
    Execution.isRuleRecorded, Execution.ruleAwaitsCommit, Execution.ruleHadEffect =
      false, false, false

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
            needsPlacementUpdate = needsPlacementUpdate or didReplace
            Execution.target = modifyTarget
            noteCommitEffect(didReplace)
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
            needsPlacementUpdate = needsPlacementUpdate or didTransform
            noteCommitEffect(didTransform)
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

            noteCommitEffect(didTeleport)
            DebugLog('  teleport on %s: %s', objectId, didTeleport and 'OK' or 'failed')
          end

          if setOwnershipAction then
            local didSet = actionHandlers.set_ownership(modifyTarget, setOwnershipAction)
            noteTargetEffect(didSet)
            DebugLog('  set_ownership on %s: %s', objectId, didSet and 'OK' or 'noop')
          end

          if addTagAction then
            local didAddTag = actionHandlers.add_tag(modifyTarget, addTagAction)
            noteTargetEffect(didAddTag)
            DebugLog('  add_tag on %s: %s', objectId, didAddTag and 'OK' or 'unavailable')
          end

          if removeTagAction then
            local didRemoveTag = actionHandlers.remove_tag(modifyTarget, removeTagAction)
            noteTargetEffect(didRemoveTag)
            DebugLog('  remove_tag on %s: %s', objectId, didRemoveTag and 'OK' or 'unavailable')
          end

          if addAction then
            local didAdd = actionHandlers.add(modifyTarget, addAction)
            noteTargetEffect(didAdd)
            DebugLog('  add on %s: %s', objectId, didAdd and 'OK' or 'failed')
          end

          if removeAction then
            local didRemove = actionHandlers.remove(modifyTarget, removeAction)
            noteTargetEffect(didRemove)
            DebugLog('  remove on %s: %s', objectId, didRemove and 'OK' or 'nothing to remove')
          end

          if equipAction then
            local didEquip = actionHandlers.equip(modifyTarget, equipAction)
            noteTargetEffect(didEquip)
            DebugLog('  equip on %s: %s', objectId, didEquip and 'OK' or 'failed')
          end

          if unequipAction then
            local didUnequip = actionHandlers.unequip(modifyTarget, unequipAction)
            noteTargetEffect(didUnequip)
            DebugLog(
              '  unequip on %s: %s',
              objectId,
              didUnequip and 'OK' or 'failed (not equipped)'
            )
          end

          if addSpellAction then
            local didAddSpell = actionHandlers.add_spell(modifyTarget, addSpellAction)
            noteTargetEffect(didAddSpell)
            DebugLog('  add_spell on %s: %s', objectId, didAddSpell and 'OK' or 'noop')
          end

          if removeSpellAction then
            local didRemoveSpell = actionHandlers.remove_spell(modifyTarget, removeSpellAction)
            noteTargetEffect(didRemoveSpell)
            DebugLog('  remove_spell on %s: %s', objectId, didRemoveSpell and 'OK' or 'noop')
          end

          if addActiveSpellAction then
            local didAddActiveSpell =
              actionHandlers.add_active_spell(modifyTarget, addActiveSpellAction)
            noteTargetEffect(didAddActiveSpell)
            DebugLog('  add_active_spell on %s: %s', objectId, didAddActiveSpell and 'OK' or 'noop')
          end

          if lockLevelAction then
            local didLock = actionHandlers.lock_level(modifyTarget, lockLevelAction)
            noteTargetEffect(didLock)
            DebugLog(
              '  lock_level on %s: %s',
              objectId,
              didLock and 'OK' or 'failed (not lockable)'
            )
          end

          if keyAction then
            local didKey = actionHandlers.key(modifyTarget, keyAction)
            noteTargetEffect(didKey)
            DebugLog('  key on %s: %s', objectId, didKey and 'OK' or 'failed (not lockable)')
          end

          if trapAction then
            local didTrap = actionHandlers.trap(modifyTarget, trapAction)
            noteTargetEffect(didTrap)
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
              noteLastingEffect(true)
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
            noteLastingEffect(didSet)
            DebugLog('  global_set: %s', didSet and 'OK' or 'failed')
          end

          if setWeatherAction then
            local didSetWeather = actionHandlers.set_weather(modifyTarget, setWeatherAction)
            noteLastingEffect(didSetWeather)
            DebugLog('  set_weather: %s', didSetWeather and 'OK' or 'noop')
          end

          if playsoundAction then
            local didPlay = actionHandlers.playsound(modifyTarget, playsoundAction)
            noteLastingEffect(didPlay)
            DebugLog('  playsound on %s: %s', objectId, didPlay and 'OK' or 'miss')
          end

          if addLuaScriptAction then
            local didAdd = actionHandlers.add_lua_script(modifyTarget, addLuaScriptAction)
            noteTargetEffect(didAdd)
            DebugLog('  add_lua_script on %s: %s', objectId, didAdd and 'OK' or 'already attached')
          end

          if activateByPlayerAction then
            local didActivate = actionHandlers.activate_by_player(modifyTarget)
            noteLastingEffect(didActivate)
            DebugLog('  activate_by_player on %s: %s', objectId, didActivate and 'OK' or 'failed')
          end

          if removeLuaScriptAction then
            local didRemove = actionHandlers.remove_lua_script(modifyTarget, removeLuaScriptAction)
            noteTargetEffect(didRemove)
            DebugLog(
              '  remove_lua_script on %s: %s',
              objectId,
              didRemove and 'OK' or 'not attached'
            )
          end

          if runLuaScriptAction then
            local didRun = actionHandlers.run_lua_script(modifyTarget, runLuaScriptAction)
            noteLastingEffect(didRun)
            DebugLog('  run_lua_script on %s: %s', objectId, didRun and 'OK' or 'failed')
          end

          if callInterfaceAction then
            local didCall = actionHandlers.call_interface(modifyTarget, callInterfaceAction)
            noteLastingEffect(didCall)
            DebugLog('  call_interface on %s: %s', objectId, didCall and 'OK' or 'failed')
          end

          if sendEventAction then
            local didSend = actionHandlers.send_event(modifyTarget, sendEventAction)
            noteLastingEffect(didSend)
            DebugLog(
              '  send_event %s on %s: %s',
              sendEventAction.name,
              objectId,
              didSend and 'OK' or 'failed'
            )
          end

          if sendGlobalEventAction then
            local didSend = actionHandlers.send_global_event(modifyTarget, sendGlobalEventAction)
            noteLastingEffect(didSend)
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
              noteCommitEffect(true)
            end
          end

          if deleteAction then
            local didDelete =
              actionHandlers.delete(object, deleteAction, replaceAction, replaceActionSucceeded)
            if didDelete then
              shouldDelete = true
              noteCommitEffect(true)
              DebugLog('  delete on %s', objectId)
            end
          end
        else
          DebugLog('  chance miss on %s: %.2f', objectId, actionData.chance)
        end
      end

      if Execution.ruleAwaitsCommit and not Execution.isRuleRecorded then
        commitDependentRules = commitDependentRules or {}
        commitDependentRules[#commitDependentRules + 1] = instanceModification
      end

      if instanceModification.moduleOnce and Execution.ruleHadEffect then
        moduleOnceApplied[instanceModification.moduleName] = true
      end
    end
  end

  if not Execution.hadAnyEffect then
    clearUncommitted()
    return
  end

  local replacesObject = modifyTarget ~= object

  if shouldDisable and not replacesObject then
    Uncommitted.enabledWasChanged = true
    object.enabled = false
  end

  if needsPlacementUpdate then
    local sendsPlayerElsewhere = PlayerObjectIsInstance(modifyTarget)
      and newCell.id ~= originalCell.id

    local wasPlaced, placeError = pcall(
      commitPlacement,
      modifyTarget,
      newCell,
      newPos,
      newTransform,
      targetScale,
      teleportOnGround
    )

    if not wasPlaced then
      reportActionFailure('placement', placeError)

      if not replacesObject then restoreScale(object, originalScale) end
      abandonUncommittedPass()

      return
    end

    if not replacesObject then Uncommitted.wasMoved = true end

    if sendsPlayerElsewhere then
      TriggerContext.expectedPlayerCellId = newCell.id
      Uncommitted.sentPlayerElsewhere = true
    end
  end

  -- Nothing from here on can be refused by the engine: enabled changes are queued like the
  -- move, and the rest is SSS's own bookkeeping. If any of it raises all the same, the
  -- per-object guard abandons the pass and what was started above is put right.
  if replacesObject then
    Uncommitted.enabledWasChanged = true
    object.enabled = false

    if shouldDisable and modifyTarget:isValid() then modifyTarget.enabled = false end
  end

  if shouldDelete and object:isValid() then DeleteManager:addObjectToDeleteQueue(object, true) end

  if commitDependentRules then
    for ruleIdx = 1, #commitDependentRules do
      recordRuleApplied(object, modifyTarget, commitDependentRules[ruleIdx])
    end
  end

  if replacesObject then inheritOnceActions(object, modifyTarget) end

  clearUncommitted()
end

---@class SSSInstanceModifiers
local InstanceModifiers = {
  getMatchingInstanceModules = getMatchingInstanceModules,
  loadOnceCache = loadOnceCache,
  saveOnceCache = saveOnceCache,
  tryModifyObject = tryModifyObject,
  abandonUncommittedPass = abandonUncommittedPass,
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
