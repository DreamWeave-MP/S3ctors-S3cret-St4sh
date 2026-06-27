---@omw-context global

local aux_util                                          = require 'openmw_aux.util'
local markup                                            = require 'openmw.markup'
local types                                             = require 'openmw.types'
local util                                              = require 'openmw.util'
local vfs                                               = require 'openmw.vfs'
local world                                             = require 'openmw.world'

local randomGen                                         = require 'scripts.s3.randomGen'

local szudzik                                           = require 'scripts.s3.szudzik'
local tableHash                                         = require 'scripts.s3.tableHash'

local actionHandlers                                    = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers                                 = require 'Scripts.staticSwitcher.conditionHandlers'

---@type StaticUtil
local staticUtil                                        = require 'scripts.staticSwitcher.util'

local AXES                                              = { 'z', 'y', 'x', }

local ModuleToRemove

--- Indexed first by module name, then an array of actions and conditions
--- all values in said array will be strings, and, when each lookup is performed they can/should be cached
--- based on the generated hash of each set of table values (itself, keyed by the name of the loaded module)
local ObjectModificationStore                           = {}

--- Indexed first by object string, then contains
local ActionLookupCache                                 = {}

local ROTATE_FORMAT_STR                                 = 'rotate%s'

local MeshReplacementModules, MeshReplacementModulesLen = {}, 0

local error, ipairs, next, pairs, type                  = error, ipairs, next, pairs, type

local sendMenuEvent                                     = types.Player.sendMenuEvent

local DeleteManager                                     = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements                                = require 'Scripts.staticSwitcher.staticReplacements' (
  DeleteManager
)

local uninstallModule                                   = require 'Scripts.staticSwitcher.globalSettings' (
  MeshReplacementModules,
  DeleteManager,
  StaticReplacements.ReplacedObjectSet
)

local settingsGroup                                     = require 'openmw.storage'.globalSection(
  'SettingsStaticSwitcher')
if settingsGroup:get('StaticSwitcherDisableModule') then settingsGroup:set('StaticSwitcherDisableModule', false) end

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

local function staticLoaderModuleHandler(meshReplacementsTable)
  local meshMap
  if meshReplacementsTable.replace_meshes and next(meshReplacementsTable.replace_meshes) ~= nil then
    --- Rubic0n annotations need updated for OpenResty additions
    ---@diagnostic disable-next-line: undefined-field
    if table.new then
      ---@diagnostic disable-next-line: undefined-field
      meshMap = table.new(0, table.nkeys(meshReplacementsTable.replace_meshes))
    else
      meshMap = {}
    end
  end

  local cellNameMatches
  if meshReplacementsTable.replace_names and next(meshReplacementsTable.replace_names) ~= nil then
    if table.new then
      cellNameMatches = table.new(#meshReplacementsTable.replace_names, 0)
    else
      cellNameMatches = {}
    end
  end

  local gridIndices
  if meshReplacementsTable.exterior_cells and next(meshReplacementsTable.exterior_cells) ~= nil then
    if table.new then
      gridIndices = table.new(0, #meshReplacementsTable.exterior_cells)
    else
      gridIndices = {}
    end
  end

  local ignoreRecords
  if meshReplacementsTable.ignore_records and next(meshReplacementsTable.ignore_records) ~= nil then
    if table.new then
      ignoreRecords = table.new(0, #meshReplacementsTable.ignore_records)
    else
      ignoreRecords = {}
    end
  end

  local replacementTable
  if table.new then
    local numElements = (meshMap and 1 or 0)
        + (cellNameMatches and 1 or 0)
        + (gridIndices and 1 or 0)
        + (ignoreRecords and 1 or 0)
        + (meshReplacementsTable.log_name and 1 or 0)
    replacementTable = table.new(0, numElements)

    print('allocating replacement table with', numElements, 'elements')
  else
    replacementTable = {}
  end

  if meshMap then replacementTable.meshMap = meshMap end
  if cellNameMatches then replacementTable.cellNameMatches = cellNameMatches end
  if gridIndices then replacementTable.gridIndices = gridIndices end
  if ignoreRecords then replacementTable.ignoreRecords = ignoreRecords end
  if meshReplacementsTable.log_name then replacementTable.logString = meshReplacementsTable.log_name end

  if meshMap then
    local key, value = '', ''
    for oldMesh, newMesh in pairs(meshReplacementsTable.replace_meshes) do
      key = staticUtil.normalizePath(staticUtil.getMeshPath(oldMesh))
      value = staticUtil.normalizePath(staticUtil.getMeshPath(newMesh))

      meshMap[key] = value
    end
  end

  if cellNameMatches then
    for i, replaceString in ipairs(meshReplacementsTable.replace_names) do
      cellNameMatches[i] = replaceString:lower()
    end
  end

  if gridIndices then
    for _, cellGrid in ipairs(meshReplacementsTable.exterior_cells) do
      replacementTable.gridIndices[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
    end
  end

  if ignoreRecords then
    for _, ignoreRecord in ipairs(meshReplacementsTable.ignore_records) do
      replacementTable.ignoreRecords[ignoreRecord] = true
    end
  end

  return replacementTable
end

---@class ActionPriority
local ACTIONPRIORITY = {
  'replace',
  'transform',
}

---@class ConditionPriority
local CONDITIONPRIORITY = {
  'content_file',
  'object_type',
  --- Record ID comes before many other searches as it's likely to be cheap and common
  --- This one doesn't have a separate match variant
  'record_id',
  'ref_num',
  --- Name matches should always be last as they're inevitably going to be the slowest
  'name',
  'carrying',
}

local function sortConditionByType(conditionData)
  for index, conditionName in ipairs(CONDITIONPRIORITY) do
    if conditionData[conditionName] then return index end
  end
end

local function sortActionByType(actionData)
  for index, actionName in ipairs(ACTIONPRIORITY) do
    if actionData[actionName] then return index end
  end
end


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

  for _, actionList in pairs(ObjectModificationStore) do
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

---@alias Axis
---| 'x'
---| 'y'
---| 'z'

---@class RotationParamInput
---@field isRelative boolean
---@field currentTransform userdata
---@field rotateActionDetails table<Axis, integer> map of axes to rotations as degrees

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

local composedReplacements = StaticReplacements.ComposedReplacements

local function loadSwitcherModule(meshReplacementsPath, baseName)
  local meshReplacementsFile = vfs.open(meshReplacementsPath)
  local meshReplacementsText = meshReplacementsFile:read('*all')

  if not meshReplacementsText then error('Failed to read' .. meshReplacementsFile .. '!') end

  MeshReplacementModulesLen = MeshReplacementModulesLen + 1
  MeshReplacementModules[MeshReplacementModulesLen] = baseName

  ---@type SSSModuleRaw
  local meshReplacementsTable = markup.decodeYaml(meshReplacementsText)

  ---@cast meshReplacementsTable SSSModuleInstances
  if meshReplacementsTable.instances then
    local modStore = {}

    for index, instance_action in ipairs(meshReplacementsTable.instances) do
      if instance_action.conditions then
        instance_action.conditions = aux_util.mapFilterSort(instance_action.conditions, sortConditionByType)
      end

      instance_action.actions = aux_util.mapFilterSort(instance_action.actions, sortActionByType)

      modStore[index] = instance_action
    end

    ObjectModificationStore[baseName] = modStore
  else
    ---@cast meshReplacementsTable SSSModuleStatic
    composedReplacements[baseName] = staticLoaderModuleHandler(meshReplacementsTable)
  end

  meshReplacementsFile:close()
end


for meshReplacementsPath in vfs.pathsWithPrefix 'scripts/staticSwitcher/data' do
  local baseName = staticUtil.getPathBaseName(meshReplacementsPath)
  if baseName ~= 'example' then
    loadSwitcherModule(meshReplacementsPath, baseName)
  end
end

return {
  interface = {
    getRefNum = staticUtil.getRefNum,
    objectModificationStore = function()
      return util.makeReadOnly(ObjectModificationStore)
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
    version = 2,
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
