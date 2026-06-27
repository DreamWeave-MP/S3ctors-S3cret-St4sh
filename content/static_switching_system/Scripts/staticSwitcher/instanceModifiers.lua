---@omw-context global

local util                               = require 'openmw.util'

local randomGen                          = require 'scripts.s3.randomGen'
local tableHash                          = require 'scripts.s3.tableHash'

local actionHandlers                     = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers                  = require 'Scripts.staticSwitcher.conditionHandlers'

--- Indexed first by object string, then contains
local ActionLookupCache                  = {}

---@type SSSModuleCatalog
local ModuleCatalog

local assert, error, ipairs, pairs, type = assert, error, ipairs, pairs, type

local AXES                               = { 'z', 'y', 'x', }
local ROTATE_FORMAT_STR                  = 'rotate%s'

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

        if not matchedAnyValue then return false end
      else
        if not conditionHandler(object, conditionValue) then return false end
      end
    end
  end

  return true
end

local function getMatchingInstanceModules(object)
  local matchingActions, actionIndex

  --- This is kind of terrible and appears to be a bug in the engine itself
  --- but, for now, using the tostring version works alright-ish until... we find out it doesn't, somehow
  --- like perhaps the ID changing due to load order fuckery (which is why we used the GO itself as a key in the first place)
  local objectString = object.id

  for _, actionList in pairs(ModuleCatalog.ObjectModificationStore) do
    for _, actionData in ipairs(actionList) do
      local actionTableHash = tableHash(actionData)
      local shouldProcess = actionData.conditions and matchesAllConditions(object.actionData.conditions)

      -- Action conditions have been evaluated already, and this action can only run once
      if actionData.once and
          ActionLookupCache[objectString]
          and ActionLookupCache[objectString][actionTableHash] then
        shouldProcess = false
      end

      if shouldProcess then
        matchingActions = matchingActions or {}
        actionIndex = actionIndex + 1
        matchingActions[actionIndex] = actionData.actions

        if not ActionLookupCache[objectString] then ActionLookupCache[objectString] = {} end

        ActionLookupCache[objectString][actionTableHash] = true
      end
    end
  end

  return matchingActions
end

---@param numberOrTable number|table
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
---@param rotateActionDetails table<Axis, number>
---@param currentTransform openmw.util.Transform
---@return openmw.util.Transform transform
local function getRotationValue(isRelative, rotateActionDetails, currentTransform)
  local rootTransform = util.transform.identity

  if isRelative then
    rootTransform = currentTransform * rootTransform
  end

  for _, axis in ipairs(AXES) do
    if rotateActionDetails[axis] then
      rootTransform = util.transform[ROTATE_FORMAT_STR:format(axis:upper())](
        math.rad(
          getRangeValue(
            rotateActionDetails[axis]
          )
        )
      ) * rootTransform
    end
  end

  return rootTransform
end

---@param object openmw.GObject
local function tryModifyObject(object, instanceModificationList)
  local wasModified = false
  local modifyTarget = object
  --- Do replacements first, then transforms, then item additions/removals, then spells

  local newTransform, newPos, newCell, targetScale = object.rotation, object.position, object.cell, 1.0

  for _, instanceModification in ipairs(instanceModificationList) do
    for _, actionData in ipairs(instanceModification) do
      --- Should we allow only one successful replacement???
      if actionData.replace and modifyTarget == object then
        local foundReplacement = actionHandlers.replace(object, actionData.replace)
        if foundReplacement then
          modifyTarget.enabled = false
          modifyTarget = foundReplacement
          wasModified = true
        end
      elseif actionData.transform then
        local actionDetails = actionData.transform

        local useRelativeTransform = actionDetails.transform_type == nil or
            actionDetails.transform_type == 'relative'

        if actionDetails.scale then
          local referenceScale = useRelativeTransform and modifyTarget.scale or 1.0
          local scaleType = type(actionDetails.scale)

          if scaleType == 'number' then
            targetScale = actionDetails.scale
          elseif scaleType == 'table' then
            targetScale = randomGen.range(actionDetails.scale.min or 1.0, actionDetails.scale.max)
          else
            error("Invalid type for scale parameter: " .. scaleType)
          end

          targetScale = referenceScale * targetScale
          wasModified = true
        end

        if actionDetails.rotate then
          newTransform = getRotationValue(
            useRelativeTransform,
            actionDetails.rotate,
            newTransform or modifyTarget.rotation
          )

          wasModified = true
        end

        if actionDetails.position then
          local actionTargetPos = util.vector3(
            getRangeValue(actionDetails.position.x),
            getRangeValue(actionDetails.position.y),
            getRangeValue(actionDetails.position.z)
          )

          if useRelativeTransform then
            newPos = newPos + actionTargetPos
          else
            newPos = actionTargetPos
          end

          wasModified = true
        end
      end
    end
  end

  if not wasModified then return end

  modifyTarget:setScale(targetScale)
  ---@diagnostic disable-next-line: param-type-mismatch
  modifyTarget:teleport(newCell, newPos, newTransform)
end

---@class SSSInstanceModifiers
local InstanceModifiers = {
  getMatchingInstanceModules = getMatchingInstanceModules,
  tryModifyObject = tryModifyObject,
}

---@param moduleCatalog SSSModuleCatalog
return function(moduleCatalog)
  ModuleCatalog = assert(moduleCatalog)
  return InstanceModifiers
end
