---@omw-context global

local util                               = require 'openmw.util'

local randomGen                          = require 'scripts.s3.randomGen'
local tableHash                          = require 'scripts.s3.tableHash'

local actionHandlers                     = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers                  = require 'Scripts.staticSwitcher.conditionHandlers'

--- Indexed first by object id, then by action table hash.
---@type table<string, table<string, true>>
local ActionLookupCache                  = {}

---@type SSSModuleCatalog
local ModuleCatalog

local assert, error, ipairs, pairs, type = assert, error, ipairs, pairs, type

local rotateX                            = util.transform.rotateX
local rotateY                            = util.transform.rotateY
local rotateZ                            = util.transform.rotateZ
local rad                                = math.rad

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

        if not matchedAnyValue then return false end
      else
        if not conditionHandler(object, conditionValue) then return false end
      end
    end
  end

  return true
end

---@param object openmw.GObject
---@return SSSInstanceModificationList?
local function getMatchingInstanceModules(object)
  local matchingActions, actionIndex

  --- This is kind of terrible and appears to be a bug in the engine itself
  --- but, for now, using the tostring version works alright-ish until... we find out it doesn't, somehow
  --- like perhaps the ID changing due to load order fuckery (which is why we used the GO itself as a key in the first place)
  local objectString = object.id

  for _, actionList in pairs(ModuleCatalog.ObjectModificationStore) do
    for _, actionData in ipairs(actionList) do
      local actionTableHash = tableHash(actionData)
      local shouldProcess = actionData.conditions and matchesAllConditions(object, actionData.conditions)

      -- Action conditions have been evaluated already, and this action can only run once
      if actionData.once and
          ActionLookupCache[objectString]
          and ActionLookupCache[objectString][actionTableHash] then
        shouldProcess = false
      end

      if shouldProcess then
        matchingActions = matchingActions or {}
        actionIndex = (actionIndex or 0) + 1
        matchingActions[actionIndex] = actionData.actions

        if not ActionLookupCache[objectString] then ActionLookupCache[objectString] = {} end

        ActionLookupCache[objectString][actionTableHash] = true
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
  if z then rootTransform = rotateZ(rad(getRangeValue(z))) * rootTransform end

  local y = rotateActionDetails.y
  if y then rootTransform = rotateY(rad(getRangeValue(y))) * rootTransform end

  local x = rotateActionDetails.x
  if x then rootTransform = rotateX(rad(getRangeValue(x))) * rootTransform end

  return rootTransform
end

---@param object openmw.GObject
---@param modifyTarget openmw.GObject
---@param replaceAction SSSReplaceAction
---@return openmw.GObject modifyTarget
---@return boolean wasModified
local function tryApplyReplacement(object, modifyTarget, replaceAction)
  local foundReplacement = actionHandlers.replace(object, replaceAction)
  if not foundReplacement then return modifyTarget, false end

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

---@param object openmw.GObject
---@param instanceModificationList SSSInstanceModificationList
local function tryModifyObject(object, instanceModificationList)
  local wasModified = false
  local modifyTarget = object
  --- Do replacements first, then transforms, then item additions/removals, then spells

  local newTransform, newPos, newCell, targetScale = object.rotation, object.position, object.cell, 1.0

  for _, instanceModification in ipairs(instanceModificationList) do
    for _, actionData in ipairs(instanceModification) do
      local replaceAction, transformAction = actionData.replace, actionData.transform

      --- Should we allow only one successful replacement???
      if replaceAction and modifyTarget == object then
        local didReplace
        modifyTarget, didReplace = tryApplyReplacement(object, modifyTarget, replaceAction)
        wasModified = wasModified or didReplace
      elseif transformAction then
        local useRelativeTransform = transformAction.transform_type == nil or
            transformAction.transform_type == 'relative'

        if transformAction.scale then
          local referenceScale = useRelativeTransform and modifyTarget.scale or 1.0
          targetScale = getScaleValue(transformAction.scale, referenceScale)
          wasModified = true
        end

        if transformAction.rotate then
          newTransform = getRotationValue(
            useRelativeTransform,
            transformAction.rotate,
            newTransform or modifyTarget.rotation
          )

          wasModified = true
        end

        if transformAction.position then
          local actionTargetPos = util.vector3(
            getRangeValue(transformAction.position.x),
            getRangeValue(transformAction.position.y),
            getRangeValue(transformAction.position.z)
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
---@return SSSInstanceModifiers
return function(moduleCatalog)
  ModuleCatalog = assert(moduleCatalog)
  return InstanceModifiers
end
