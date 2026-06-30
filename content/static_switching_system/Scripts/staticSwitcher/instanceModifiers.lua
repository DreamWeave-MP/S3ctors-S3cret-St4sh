---@omw-context global

local util = require 'openmw.util'

local randomGen = require 'scripts.s3.randomGen'

local staticUtil = require 'scripts.staticSwitcher.util'

local actionHandlers = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers = require 'Scripts.staticSwitcher.conditionHandlers'

--- Migration/default handling: versioned separately from the global save shape;
--- missing or unknown once-cache versions are treated as empty caches so old saves load safely.
local ONCE_CACHE_SCHEMA_VERSION = 1

---@type SSSOnceCache
local OnceCache = {
	entries = {},
	byObjectId = {},
}

---@type SSSModuleCatalog
local ModuleCatalog

---@type SSSDeleteManager
local DeleteManager

local assert, error, ipairs, pairs, type = assert, error, ipairs, pairs, type

local rotateX = util.transform.rotateX
local rotateY = util.transform.rotateY
local rotateZ = util.transform.rotateZ
local rad = math.rad

local function resetOnceCache()
	OnceCache = {
		entries = {},
		byObjectId = {},
	}
end

local function pruneOnceCache()
	local prunedEntries, prunedEntryCount, prunedByObjectId = {}, 0, {}

	for _, entry in ipairs(OnceCache.entries) do
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

	for _, savedEntry in ipairs(savedOnceCache.entries) do
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
	for _, conditionData in ipairs(conditions) do
		for conditionName, conditionValue in pairs(conditionData) do
			local conditionHandler = conditionHandlers[conditionName]

			if type(conditionHandler) ~= 'function' then
				error(('Condition %s is an invalid condition for the handler!'):format(conditionName))
			end

			if type(conditionValue) == 'table' then
				local matchedAnyValue = false

				for _, individualCondition in ipairs(conditionValue) do
					if not matchedAnyValue and conditionHandler(object, individualCondition) then
						matchedAnyValue = true
						break
					end
				end

				if not matchedAnyValue then
					return false
				end
			else
				if not conditionHandler(object, conditionValue) then
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

	for moduleName, actionList in pairs(ModuleCatalog.ObjectModificationStore) do
		for _, actionData in ipairs(actionList) do
			local actionTableHash = actionData.actionHash

			local shouldProcess = not actionData.conditions or matchesAllConditions(object, actionData.conditions)

			-- Action conditions have been evaluated already, and this action can only run once
			if actionData.once and onceActionWasApplied(object, moduleName, actionTableHash) then
				shouldProcess = false
			end

			if shouldProcess then
				matchingActions = matchingActions or {}
				actionIndex = (actionIndex or 0) + 1
				matchingActions[actionIndex] = {
					moduleName = moduleName,
					actionHash = actionTableHash,
					once = actionData.once,
					actions = actionData.actions,
				}
			end
		end
	end

	return matchingActions
end

---@param numberOrTable SSSNumericRange?
---@return number rangeOrValue
local function getRangeValue(numberOrTable)
	local actionDataType, rangeOrValue = type(numberOrTable)

	if actionDataType == 'number' then
		rangeOrValue = numberOrTable
	elseif actionDataType == 'table' then
		assert(numberOrTable.max, 'An upper bound is required when selecting a numeric range!')
		rangeOrValue = randomGen.range(numberOrTable.min or 0, numberOrTable.max)
	elseif actionDataType == 'nil' then
		return 0
	else
		error('Incorrect type provided to getPerAxisRotation: ' .. actionDataType)
	end

	return rangeOrValue
end

---@param isRelative boolean
---@param rotateActionDetails SSSVector3Range
---@param currentTransform openmw.util.Transform
---@return openmw.util.Transform transform
local function getRotationValue(isRelative, rotateActionDetails, currentTransform)
	local rootTransform = isRelative and currentTransform or util.transform.identity

	local z = rotateActionDetails.z
	if z then
		rootTransform = rotateZ(rad(getRangeValue(z))) * rootTransform
	end

	local y = rotateActionDetails.y
	if y then
		rootTransform = rotateY(rad(getRangeValue(y))) * rootTransform
	end

	local x = rotateActionDetails.x
	if x then
		rootTransform = rotateX(rad(getRangeValue(x))) * rootTransform
	end

	return rootTransform
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

---@param scaleAction SSSNumericRange
---@param referenceScale number
---@return number targetScale
local function getScaleValue(scaleAction, referenceScale)
	local scaleType = type(scaleAction)

	if scaleType == 'number' then
		return referenceScale * scaleAction
	elseif scaleType == 'table' then
		return referenceScale * randomGen.range(scaleAction.min or 1.0, scaleAction.max)
	end

	error('Invalid type for scale parameter: ' .. scaleType)
end

---@param transformAction SSSTransformAction
---@param newTransform openmw.util.Transform
---@param newPos openmw.util.Vector3
---@param targetScale number
---@return boolean wasModified
---@return openmw.util.Transform newTransform
---@return openmw.util.Vector3 newPos
---@return number targetScale
local function accumulateTransformAction(transformAction, newTransform, newPos, targetScale)
	local wasModified = false
	local useRelativeTransform = transformAction.transform_type == nil or transformAction.transform_type == 'relative'

	local scaleAction = transformAction.scale
	if scaleAction then
		local referenceScale = useRelativeTransform and targetScale or 1.0
		targetScale = getScaleValue(scaleAction, referenceScale)
		wasModified = true
	end

	local rotateAction = transformAction.rotate
	if rotateAction then
		newTransform = getRotationValue(useRelativeTransform, rotateAction, newTransform)

		wasModified = true
	end

	local positionAction = transformAction.position
	if positionAction then
		local actionTargetPos = util.vector3(
			getRangeValue(positionAction.x),
			getRangeValue(positionAction.y),
			getRangeValue(positionAction.z)
		)

		if useRelativeTransform then
			newPos = newPos + actionTargetPos
		else
			newPos = actionTargetPos
		end

		wasModified = true
	end

	return wasModified, newTransform, newPos, targetScale
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

	for _, instanceModification in ipairs(instanceModificationList) do
		local currentRuleApplied = false

		for _, actionData in ipairs(instanceModification.actions) do
			local replaceAction, transformAction, addAction, removeAction, equipAction, disableAction, deleteAction =
				actionData.replace,
				actionData.transform,
				actionData.add,
				actionData.remove,
				actionData.equip,
				actionData.disable,
				actionData.delete
			local replaceActionSucceeded = false

			--- Should we allow only one successful replacement???
			if replaceAction and modifyTarget == object then
				local didReplace
				modifyTarget, didReplace = tryApplyReplacement(object, modifyTarget, replaceAction)
				replaceActionSucceeded = didReplace
				anyActionApplied = anyActionApplied or didReplace
				needsPlacementUpdate = needsPlacementUpdate or didReplace
				currentRuleApplied = currentRuleApplied or didReplace
			end

			if transformAction then
				local didTransform
				didTransform, newTransform, newPos, targetScale =
					accumulateTransformAction(transformAction, newTransform, newPos, targetScale)
				anyActionApplied = anyActionApplied or didTransform
				needsPlacementUpdate = needsPlacementUpdate or didTransform
				currentRuleApplied = currentRuleApplied or didTransform
			end

			if addAction then
				local didAdd = actionHandlers.add(modifyTarget, addAction)
				anyActionApplied = anyActionApplied or didAdd
				currentRuleApplied = currentRuleApplied or didAdd
			end

			if removeAction then
				local didRemove = actionHandlers.remove(modifyTarget, removeAction)
				anyActionApplied = anyActionApplied or didRemove
				currentRuleApplied = currentRuleApplied or didRemove
			end

			if equipAction then
				local didEquip = actionHandlers.equip(modifyTarget, equipAction)
				anyActionApplied = anyActionApplied or didEquip
				currentRuleApplied = currentRuleApplied or didEquip
			end

			if disableAction then
				shouldDisable = true
				anyActionApplied = true
				currentRuleApplied = true
			end

			if deleteAction and (not replaceAction or replaceActionSucceeded) then
				shouldDelete = true
				anyActionApplied = true
				currentRuleApplied = true
			end
		end

		if instanceModification.once and currentRuleApplied then
			markOnceActionApplied(object, instanceModification.moduleName, instanceModification.actionHash)
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
}

---@param moduleCatalog SSSModuleCatalog
---@param deleteManager SSSDeleteManager
---@return SSSInstanceModifiers
return function(moduleCatalog, deleteManager)
	ModuleCatalog = assert(moduleCatalog)
	DeleteManager = assert(deleteManager)
	return InstanceModifiers
end
