---@omw-context global

local types                      = require 'openmw.types'
local util                       = require 'openmw.util'
local world                      = require 'openmw.world'

local randomGen                  = require 'scripts.s3.randomGen'

local tableHash                  = require 'scripts.s3.tableHash'

local actionHandlers             = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers          = require 'Scripts.staticSwitcher.conditionHandlers'

---@type StaticUtil
local staticUtil                 = require 'scripts.staticSwitcher.util'

local AXES                       = { 'z', 'y', 'x', }

local ModuleToRemove

--- Indexed first by object string, then contains
local ActionLookupCache          = {}

local ROTATE_FORMAT_STR          = 'rotate%s'

local error, ipairs, pairs, type = error, ipairs, pairs, type

local sendMenuEvent              = types.Player.sendMenuEvent

local DeleteManager              = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements         = require 'Scripts.staticSwitcher.staticReplacements' (
  DeleteManager
)

local ModuleCatalog              = require 'Scripts.staticSwitcher.moduleCatalog' (
  StaticReplacements
)

local uninstallModule            = require 'Scripts.staticSwitcher.globalSettings' (
  ModuleCatalog.moduleNames,
  DeleteManager,
  StaticReplacements.ReplacedObjectSet
)

local settingsGroup              = require 'openmw.storage'.globalSection('SettingsStaticSwitcher')
if settingsGroup:get 'StaticSwitcherDisableModule' then settingsGroup:set('StaticSwitcherDisableModule', false) end

settingsGroup:subscribe(
  require 'openmw.async':callback(
    function(_, key)
      if key == 'StaticSwitcherDisableModule' then
        ModuleToRemove = settingsGroup:get('StaticSwitcherModuleSelect')
        uninstallModule(ModuleToRemove)
      end
    end
  )
)

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

return {
  interface = {
    getRefNum = staticUtil.getRefNum,
    objectModificationStore = function()
      return util.makeReadOnly(ModuleCatalog.ObjectModificationStore)
    end,
    overrideRecords = function()
      return util.makeReadOnly(StaticReplacements.OverrideRecords)
    end,
    replacedObjectSet = function()
      return util.makeReadOnly(StaticReplacements.ReplacedObjectSet)
    end,
    uninstallModule = function(moduleName)
      ModuleToRemove = uninstallModule(moduleName)
    end,
    version = 3,
  },
  interfaceName = "StaticSwitcher_G",
  engineHandlers = {
    onUpdate = function()
      DeleteManager:processDeleteQueue()

      if not ModuleToRemove or not DeleteManager:queueIsEmpty() then return end

      --- When a module is removed and all objects are removed
      --- kick every player from the game and force them to save
      for _, player in ipairs(world.players) do
        sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', ModuleToRemove)
      end

      ModuleToRemove = nil
    end,
    onObjectActive = function(object)
      local instanceModificationList = getMatchingInstanceModules(object)

      --- I don't like this.
      --- Ideally we should have like, a special type that gets assigned to each module, or something
      --- a more bespoke way to describe what *type* of module it is
      if instanceModificationList then
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
      else
        StaticReplacements.tryReplaceObject(object)
      end
    end,
    onSave = function()
      return {
        overrideRecords = StaticReplacements.OverrideRecords,
        objectDeleteQueue = DeleteManager.queue,
        replacedObjectSet = StaticReplacements.ReplacedObjectSet,
      }
    end,
    onLoad = function(data)
      if not data then return end

      staticUtil.deepCopy(StaticReplacements.OverrideRecords, data.overrideRecords)
      staticUtil.deepCopy(DeleteManager.queue, data.objectDeleteQueue)
      staticUtil.deepCopy(StaticReplacements.ReplacedObjectSet, data.replacedObjectSet)
    end,
  }
}
