---@omw-context global

local staticUtil = require 'Scripts.staticSwitcher.util'

local randomGen = require 'scripts.s3.randomGen'

local actionHandlers = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers = require 'Scripts.staticSwitcher.conditionHandlers'
local logger = require 'Scripts.staticSwitcher.logger'

--- Migration/default handling: versioned separately from the global save shape;
--- missing or unknown once-cache versions are treated as empty caches so old saves load safely.
local ONCE_CACHE_SCHEMA_VERSION = 1

---@type SSSOnceCache
local OnceCache = {
	entries = {},
	byObjectId = {},
}

--- Runtime-only per-cell-load tracking set.
--- Tracks "objectId:moduleName:actionHash" for rules with once="per_cell".
--- Cleared at the start of each new activation batch (onObjectActive when the
--- stack was empty). Marked entries suppress re-processing of objects that
--- were already modified this cell load, including replacement objects.
--- Not saved — only lives for the current cell session.
---@type table<string, true>
local PerCellApplied = {}

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

---
--- Per-cell-load tracking helpers
---

---@param object openmw.GObject
---@param moduleName string
---@param actionHash string
---@return string
local function perCellKey(object, moduleName, actionHash)
	return ('%s:%s:%s'):format(object.id, moduleName, actionHash)
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
--- the ActiveObjectStack was empty, indicating a fresh cell-load batch.
local function clearPerCellTracking()
	logger.debug 'Cleared per-cell tracking for new cell-load batch'
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
		if type(savedEntry) ~= 'table' then
			error 'Once cache entry must be a table!'
		end

		local object, modules = savedEntry.object, savedEntry.modules

		if not staticUtil.isGObject(object) then
			error 'Once cache entry object must be an openmw.GObject!'
		end
		if type(modules) ~= 'table' then
			error 'Once cache entry modules must be a table!'
		end

		if object:isValid() then
			local entry = { object = object, modules = {} }

			for moduleName, moduleActions in pairs(modules) do
				if type(moduleName) ~= 'string' then
					error 'Once cache module name must be a string!'
				end
				if type(moduleActions) ~= 'table' then
					error 'Once cache module actions must be a table!'
				end

				local moduleId = ModuleCatalog.resolveModuleId(moduleName) or moduleName

				local copiedModuleActions = {}

				for actionHash, wasApplied in pairs(moduleActions) do
					if type(actionHash) ~= 'string' then
						error 'Once cache action hash must be a string!'
					end
					if wasApplied ~= true then
						error 'Once cache action value must be true!'
					end

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
				error(('Condition %s is an invalid condition for the handler!'):format(conditionName))
			end

			if type(conditionValue) == 'table' then
				-- Array-like tables are OR-lists: any element may match.
				-- Map-like tables (string/non-integer keys) are passed as-is to the handler.
				local firstKey = next(conditionValue)
				local isOrList = firstKey and type(firstKey) == 'number'

				if isOrList then
					local matchedAnyValue = false

					for indivIndex = 1, #conditionValue do
						if not matchedAnyValue and conditionHandler(object, conditionValue[indivIndex]) then
							matchedAnyValue = true
							break
						end
					end

					if not matchedAnyValue then
						logger.debug('Condition %s OR-list FAIL for %s', conditionName, object.id)
						return false
					end
				elseif not conditionHandler(object, conditionValue) then
					logger.debug('Condition %s FAIL for %s', conditionName, object.id)
					return false
				end
			else
				if not conditionHandler(object, conditionValue) then
					logger.debug('Condition %s=%s FAIL for %s', conditionName, tostring(conditionValue), object.id)
					return false
				end
			end
		end
	end

	return true
end

---@param object openmw.GObject
---@return SSSInstanceModificationList?
local function getMatchingInstanceModules(object)
	local matchingActions, actionIndex

	for modIdx = 1, #ModuleCatalog.SortedModuleIds do
		local moduleName = ModuleCatalog.SortedModuleIds[modIdx]
		local moduleData = ModuleCatalog.ObjectModificationStore[moduleName]
		local actionList = moduleData.rules
		local moduleOnce = moduleData.moduleOnce

		for listIdx = 1, #actionList do
			local actionData = actionList[listIdx]

			local actionTableHash = actionData.actionHash
			local skipReason

			local conditionsPassed = not actionData.conditions or matchesAllConditions(object, actionData.conditions)

			if not conditionsPassed then
				skipReason = 'conditions failed'
			end

			-- Action conditions have been evaluated already, and this action can only run once
			if
				not skipReason
				and actionData.once == true
				and onceActionWasApplied(object, moduleName, actionTableHash)
			then
				skipReason = 'once=true already applied'
			end

			-- Per-cell once: only skip for this cell-load session; not saved
			if
				not skipReason
				and actionData.once == 'per_cell'
				and wasAppliedThisLoad(object, moduleName, actionTableHash)
			then
				skipReason = 'once=per_cell already applied this load'
			end

			-- Module-level once: skip all rules for this module if any rule has already applied
			if not skipReason and moduleOnce and onceActionWasApplied(object, moduleName, '*') then
				skipReason = 'module once=true already applied'
			end

			if skipReason then
				logger.debug('SKIP %s/%s on %s: %s', moduleName, actionTableHash, object.id, skipReason)
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
	end

	if matchingActions then
		logger.debug('MATCH %d rule(s) for %s (%s)', #matchingActions, object.id, object.recordId or '?')
	end

	return matchingActions
end

---@param object openmw.GObject
---@param modifyTarget openmw.GObject
---@param replaceAction SSSReplaceAction
---@return openmw.GObject modifyTarget
---@return boolean wasModified
local function tryApplyReplacement(object, modifyTarget, replaceAction)
	local foundReplacement = actionHandlers.replace(object, replaceAction)
	if not foundReplacement then
		return modifyTarget, false
	end

	modifyTarget.enabled = false
	return foundReplacement, true
end

---@param object openmw.GObject
---@param instanceModificationList SSSInstanceModificationList
local function tryModifyObject(object, instanceModificationList)
	local anyActionApplied = false
	local needsPlacementUpdate = false
	local shouldDisable = false
	local shouldDelete = false
	local modifyTarget = object
	--- Do replacements first, then transforms, then item additions/removals, then spells

	local newTransform, newPos, newCell, targetScale = object.rotation, object.position, object.cell, object.scale

	logger.debug('APPLY %d rule(s) to %s (%s)', #instanceModificationList, object.id, object.recordId or '?')

	for modIndex = 1, #instanceModificationList do
		local instanceModification = instanceModificationList[modIndex]
		local currentRuleApplied = false

		for actIndex = 1, #instanceModification.actions do
			local actionData = instanceModification.actions[actIndex]
			if not actionData.chance or randomGen.float() <= actionData.chance then
				local replaceAction, transformAction, addAction, removeAction, equipAction, unequipAction, disableAction, deleteAction, createAction, lockLevelAction =
					actionData.replace,
					actionData.transform,
					actionData.add,
					actionData.remove,
					actionData.equip,
					actionData.unequip,
					actionData.disable,
					actionData.delete,
					actionData.create,
					actionData.lock_level
				local replaceActionSucceeded = false

				--- Should we allow only one successful replacement???
				if replaceAction and modifyTarget == object then
					local didReplace
					modifyTarget, didReplace = tryApplyReplacement(object, modifyTarget, replaceAction)
					replaceActionSucceeded = didReplace
					anyActionApplied = anyActionApplied or didReplace
					needsPlacementUpdate = needsPlacementUpdate or didReplace
					currentRuleApplied = currentRuleApplied or didReplace
					logger.debug('  replace on %s: %s', object.id, didReplace and 'OK' or 'failed (no matching roll)')
				end

				if transformAction then
					local didTransform
					didTransform, newTransform, newPos, targetScale =
						actionHandlers.transform(modifyTarget, transformAction, newTransform, newPos, targetScale)
					anyActionApplied = anyActionApplied or didTransform
					needsPlacementUpdate = needsPlacementUpdate or didTransform
					currentRuleApplied = currentRuleApplied or didTransform
					if didTransform then
						logger.debug('  transform on %s: scale=%.3f', object.id, targetScale)
					end
				end

				if addAction then
					local didAdd = actionHandlers.add(modifyTarget, addAction)
					anyActionApplied = anyActionApplied or didAdd
					currentRuleApplied = currentRuleApplied or didAdd
					logger.debug('  add on %s: %s', object.id, didAdd and 'OK' or 'failed')
				end

				if removeAction then
					local didRemove = actionHandlers.remove(modifyTarget, removeAction)
					anyActionApplied = anyActionApplied or didRemove
					currentRuleApplied = currentRuleApplied or didRemove
					logger.debug('  remove on %s: %s', object.id, didRemove and 'OK' or 'nothing to remove')
				end

				if equipAction then
					local didEquip = actionHandlers.equip(modifyTarget, equipAction)
					anyActionApplied = anyActionApplied or didEquip
					currentRuleApplied = currentRuleApplied or didEquip
					logger.debug('  equip on %s: %s', object.id, didEquip and 'OK' or 'failed')
				end

				if unequipAction then
					local didUnequip = actionHandlers.unequip(modifyTarget, unequipAction)
					anyActionApplied = anyActionApplied or didUnequip
					currentRuleApplied = currentRuleApplied or didUnequip
					logger.debug('  unequip on %s: %s', object.id, didUnequip and 'OK' or 'failed (not equipped)')
				end

				if lockLevelAction then
					local didLock = actionHandlers.lock_level(modifyTarget, lockLevelAction)
					anyActionApplied = anyActionApplied or didLock
					currentRuleApplied = currentRuleApplied or didLock
					logger.debug('  lock_level on %s: %s', object.id, didLock and 'OK' or 'failed (not lockable)')
				end

				if createAction then
					local numCreated = actionHandlers.create(modifyTarget, createAction)
					if numCreated > 0 then
						anyActionApplied = true
						currentRuleApplied = true
						logger.debug('  create on %s: %d spawned', object.id, numCreated)
					end
				end

				if disableAction then
					local didDisable = actionHandlers.disable(modifyTarget, disableAction)
					logger.debug('  disable on %s: roll=%s', object.id, didDisable and 'OK' or 'miss')
					if didDisable then
						shouldDisable = true
						anyActionApplied = true
						currentRuleApplied = true
					end
				end

				if deleteAction then
					local didDelete = actionHandlers.delete(object, deleteAction, replaceAction, replaceActionSucceeded)
					if didDelete then
						shouldDelete = true
						anyActionApplied = true
						currentRuleApplied = true
						logger.debug('  delete on %s', object.id)
					end
				end
			else
				logger.debug('  chance miss on %s: %.2f', object.id, actionData.chance)
			end
		end

		if instanceModification.once == true and currentRuleApplied then
			markOnceActionApplied(object, instanceModification.moduleName, instanceModification.actionHash)
			logger.debug('  once=true cached: %s/%s', instanceModification.moduleName, instanceModification.actionHash)
		end

		if instanceModification.once == 'per_cell' and currentRuleApplied then
			markAppliedThisLoad(object, instanceModification.moduleName, instanceModification.actionHash)
			-- Also mark the replacement target so fresh activations skip re-processing
			if modifyTarget ~= object then
				markAppliedThisLoad(modifyTarget, instanceModification.moduleName, instanceModification.actionHash)
			end
			logger.debug(
				'  once=per_cell marked: %s/%s',
				instanceModification.moduleName,
				instanceModification.actionHash
			)
		end

		if instanceModification.moduleOnce and currentRuleApplied then
			markOnceActionApplied(object, instanceModification.moduleName, '*')
			logger.debug('  module once=true cached: %s', instanceModification.moduleName)
		end
	end

	if not anyActionApplied then
		return
	end

	if needsPlacementUpdate then
		modifyTarget:setScale(targetScale)
		---@diagnostic disable-next-line: param-type-mismatch
		modifyTarget:teleport(newCell, newPos, newTransform)
	end

	if shouldDisable and modifyTarget:isValid() then
		modifyTarget.enabled = false
	end

	if shouldDelete and object:isValid() then
		DeleteManager:addObjectToDeleteQueue(object, true)
	end
end

---@class SSSInstanceModifiers
local InstanceModifiers = {
	getMatchingInstanceModules = getMatchingInstanceModules,
	loadOnceCache = loadOnceCache,
	saveOnceCache = saveOnceCache,
	tryModifyObject = tryModifyObject,
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
