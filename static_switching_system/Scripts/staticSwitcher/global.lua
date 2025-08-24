local aux_util                = require 'openmw_aux.util'
local markup                  = require 'openmw.markup'
local types                   = require 'openmw.types'
local util                    = require 'openmw.util'
local vfs                     = require 'openmw.vfs'
local world                   = require 'openmw.world'

local randomGen               = require 'scripts.staticSwitcher.randomGen'
---@type StaticUtil
local staticUtil              = require 'scripts.staticSwitcher.util'
local strings                 = staticUtil.strings

local szudzik                 = require 'scripts.staticSwitcher.szudzik'
local tableHash               = require 'scripts.staticSwitcher.tableHash'

local TICKS_TO_DELETE         = 3
local moduleToRemove

---@type ObjectDeleteData[]
local objectDeleteQueue       = {}

---@type table <GameObject, ReplacedObjectData>
local replacedObjectSet       = {}

--- Maps module names to the record ids they manage
---@type table<string, ReplacementMap>
local overrideRecords         = {}

---@type table<string, SSSModule> Map of file names handling mesh replacements to the data contained therein
local ComposedReplacements    = {}

--- Indexed first by module name, then an array of actions and conditions
--- all values in said array will be strings, and, when each lookup is performed they can/should be cached
--- based on the generated hash of each set of table values (itself, keyed by the name of the loaded module)
local objectModificationStore = {}

--- Indexed first by object string, then contains
local actionLookupCache       = {}

---@param object GameObject
---@param oldRecord ActivatorRecord
---@param newModel string
---@param replacementModule string
local function createReplacementRecord(object, oldRecord, newModel, replacementModule)
  local oldRecordId = object.recordId

  if not overrideRecords[replacementModule] then overrideRecords[replacementModule] = {} end
  local moduleRecords = overrideRecords[replacementModule]
  if moduleRecords[oldRecordId] then return end

  local newRecord = { model = newModel }

  if not types.Static.objectIsInstance(object) and not types.Activator.objectIsInstance(object) then
    error(
      strings.InvalidTypeStr:format(object.type)
    )
  end

  local scriptId
  if oldRecord.name then newRecord.name = oldRecord.name end
  if oldRecord.mwscript then
    scriptId = oldRecord.mwscript
    newRecord.mwscript = scriptId
  end

  moduleRecords[oldRecordId] = world.createRecord(types.Activator.createRecordDraft(newRecord)).id
end

--- Adds an object to the delete queue, to be processed on another frame
---@param object GameObject
local function addObjectToDeleteQueue(object, removeOrDisable)
  objectDeleteQueue[#objectDeleteQueue + 1] = {
    object = object,
    ticks = TICKS_TO_DELETE,
    removeOrDisable =
        removeOrDisable
  }
end

---@param replacementTable SSSModule
---@param cell GameCell
---@return true? locationMatched whether or not a given cell is handled by this module
local function replacementTableMatchesCell(replacementTable, cell)
  if cell.isExterior then
    local cellIndex = szudzik.getIndex(cell.gridX, cell.gridY)
    if replacementTable.gridIndices[cellIndex] then
      return true
    end
  end

  local cellIdLower, cellNameLower = cell.id:lower(), cell.name:lower()
  for _, cellName in ipairs(replacementTable.cellNameMatches) do
    if cellName == cellIdLower
        or cellName == cellNameLower
        or cellNameLower:match(cellName)
        or cellIdLower:match(cellName)
    then
      return true
    end
  end
end

---@param cell GameCell
---@return table<string, SSSModule> modulesForThisCell subtable of valid modules for this cell
local function getReplacementModuleForCell(cell)
  local modulesForThisCell = {}

  for moduleName, moduleData in pairs(ComposedReplacements) do
    if replacementTableMatchesCell(moduleData, cell) then
      modulesForThisCell[moduleName] = moduleData
    end
  end

  return modulesForThisCell
end

---@param object GameObject
---@param replacementModule string the module which is replacing this object
---@param replacementMesh string the mesh which will be used in place of the original
local function replaceObject(object, replacementModule, replacementMesh)
  ---@type ActivatorRecord
  local objectRecord = staticUtil.Record(object)
  local moduleData = ComposedReplacements[replacementModule]
  if moduleData.ignoreRecords[object.recordId] then return end
  local oldModel = objectRecord.model

  if not oldModel or not staticUtil.assertMeshExists(
        replacementMesh,
        oldModel,
        objectRecord.id,
        replacementModule,
        ComposedReplacements[replacementModule].logString or strings.LOG_PREFIX
      ) then
    return
  end

  createReplacementRecord(object, objectRecord, replacementMesh, replacementModule)

  local targetRecord = overrideRecords[replacementModule][objectRecord.id]
  local replacement = world.createObject(targetRecord)
  replacement:setScale(object.scale)
  replacement:teleport(object.cell.name, object.position, object.rotation)

  addObjectToDeleteQueue(object, false)

  if not replacedObjectSet[replacementModule] then replacedObjectSet[replacementModule] = {} end
  replacedObjectSet[replacementModule][replacement] = object
end

local function staticLoaderModuleHandler(meshReplacementsTable)
  local replacementTable = {}

  if meshReplacementsTable.log_name then
    replacementTable.logString = meshReplacementsTable.log_name
  end

  replacementTable.meshMap = {}
  for oldMesh, newMesh in pairs(meshReplacementsTable.replace_meshes or {}) do
    replacementTable.meshMap[staticUtil.normalizePath(
      staticUtil.getMeshPath(
        oldMesh
      )
    )] = staticUtil.normalizePath(
      staticUtil.getMeshPath(
        newMesh
      )
    )
  end

  replacementTable.cellNameMatches = {}
  for i, replaceString in ipairs(meshReplacementsTable.replace_names or {}) do
    replacementTable.cellNameMatches[i] = replaceString:lower()
  end

  replacementTable.gridIndices = {}
  for _, cellGrid in ipairs(meshReplacementsTable.exterior_cells or {}) do
    replacementTable.gridIndices[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
  end

  replacementTable.ignoreRecords = {}
  for _, ignoreRecord in ipairs(meshReplacementsTable.ignore_records or {}) do
    replacementTable.ignoreRecords[ignoreRecord] = true
  end

  return replacementTable
end

local function safeCreateObject(objectId)
  return world.createObject(objectId)
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

---@type table<string, SSSConditionHandler>
local conditionHandlers = {
  content_file = function(object, contentFileName)
    return (
      object.contentFile == contentFileName:lower()
    ) or (
      not object.contentFile and contentFileName:upper() == 'GENERATED'
    )
  end,
  name = function(object, targetName)
    --- Statics may never have a name
    if types.Static.objectIsInstance(object) or not object.type then return false end

    local objectRecord = object.type.records[object.recordId]

    if objectRecord.name == nil or objectRecord.name == '' then return false end

    return objectRecord.name == targetName
        or objectRecord.name:match(targetName) ~= nil
  end,
  object_type = function(object, targetTypeName)
    local capitalizedTypeName = (targetTypeName:lower() == 'npc' and 'NPC') or staticUtil.capitalize(targetTypeName)
    local targetType = types[capitalizedTypeName]

    assert(
      targetType ~= nil,
      strings.InvalidTypeStr:format(capitalizedTypeName)
    )

    return targetType.objectIsInstance(object)
  end,
  record_id = function(object, targetRecordId)
    local originalId, lowerId = object.recordId, targetRecordId:lower()

    return originalId == lowerId or originalId:match(lowerId)
  end,
  ref_num = function(object, targetRefNum)
    local _, refNum = staticUtil.getRefNum(object)

    return refNum == targetRefNum
  end,
}

local function matchesAllConditions(object, conditions)
  for _, conditionData in ipairs(conditions) do
    for conditionName, conditionValue in pairs(conditionData) do
      local conditionHandler = conditionHandlers[conditionName]

      assert(
        type(conditionHandler) == 'function',
        ('Condition %s is an invalid condition for the handler!'):format(conditionName)
      )

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
  local matchingActions, actionIndex = {}, 1

  --- This is kind of terrible and appears to be a bug in the engine itself
  --- but, for now, using the tostring version works alright-ish until... we find out it doesn't, somehow
  --- like perhaps the ID changing due to load order fuckery (which is why we used the GO itself as a key in the first place)
  local objectString = tostring(object)

  for _, actionList in pairs(objectModificationStore) do
    for _, actionData in ipairs(actionList) do
      local actionTableHash = tableHash(actionData)
      -- conditions defined, but not passed
      if actionData.conditions and not matchesAllConditions(object, actionData.conditions) then goto SKIPACTION end

      -- Action conditions have been evaluated already, and this action can only run once
      if actionData.once and
          actionLookupCache[objectString]
          and actionLookupCache[objectString][actionTableHash] then
        goto SKIPACTION
      end

      matchingActions[actionIndex] = actionData.actions
      actionIndex = actionIndex + 1

      if not actionLookupCache[objectString] then actionLookupCache[objectString] = {} end

      actionLookupCache[objectString][actionTableHash] = true

      ::SKIPACTION::
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
    rangeOrValue = randomGen:range(numberOrTable.min or 0, numberOrTable.max)
  elseif actionDataType == 'nil' then
    return 0
  else
    error('Incorrect type provided to getPerAxisRotation: ' .. actionDataType)
  end

  return rangeOrValue
end

---@param rotateDatum RotationParamInput
---@return userdata transform
local function getRotationValue(rotateDatum)
  local rotateActionDetails = rotateDatum.rotateActionDetails
  ---@type userdata
  local rootTransform = util.transform.identity

  if rotateDatum.isRelative then
    rootTransform = rotateDatum.currentTransform * rootTransform
  end

  for _, axis in ipairs { 'z', 'y', 'x', } do
    if rotateActionDetails[axis] then
      rootTransform = util.transform[strings.ROTATE_FORMAT_STR:format(axis:upper())](
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

local actionHandlers = {
  ['replace'] = function(_, replaceActionData)
    for replaceId, replaceChance in pairs(replaceActionData) do
      if randomGen:float() > replaceChance then goto SKIPREPLACEMENT end

      local result, replacement = pcall(safeCreateObject, replaceId)

      if result then return replacement end

      ::SKIPREPLACEMENT::
    end
  end,
}

for meshReplacementsPath in vfs.pathsWithPrefix('scripts/staticSwitcher/data') do
  local baseName = staticUtil.getPathBaseName(meshReplacementsPath)
  if baseName == 'example' then goto SKIPMODULE end

  local meshReplacementsFile = vfs.open(meshReplacementsPath)
  local meshReplacementsText = meshReplacementsFile:read('*all')

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

    objectModificationStore[baseName] = modStore
  else
    ---@cast meshReplacementsTable SSSModuleStatic
    ComposedReplacements[baseName] = staticLoaderModuleHandler(meshReplacementsTable)
  end

  meshReplacementsFile:close()

  ::SKIPMODULE::
end

--- Remove all objects which were replaced by a given module
--- After all objects from this module are inserted into the delete queue, mark this module as unusable for replacements
---@param fileName string
local function uninstallModule(fileName)
  local objectsToRemove, objectsToRemoveLength = {}, 0
  local localModuleReplacements = replacedObjectSet[fileName]

  if not localModuleReplacements then
    return staticUtil.Log(
      strings.InvalidModuleNameStr:format(fileName)
    )
  end

  for newObject, oldObject in pairs(localModuleReplacements) do
    oldObject.enabled = true
    addObjectToDeleteQueue(newObject, true)

    objectsToRemoveLength = objectsToRemoveLength + 1
    objectsToRemove[objectsToRemoveLength] = newObject
  end

  for i = 1, objectsToRemoveLength do
    local targetObject = objectsToRemove[i]
    replacedObjectSet[fileName][targetObject] = nil
  end

  moduleToRemove = fileName
end

return {
  interface = {
    getRefNum = staticUtil.getRefNum,
    objectModificationStore = function()
      return util.makeReadOnly(objectModificationStore)
    end,
    overrideRecords = function()
      return util.makeReadOnly(overrideRecords)
    end,
    randomGen = randomGen,
    replacedObjectSet = function()
      return util.makeReadOnly(replacedObjectSet)
    end,
    uninstallModule = uninstallModule,
    version = 2,
  },
  interfaceName = "StaticSwitcher_G",
  eventHandlers = {
    StaticSwitcherGetRefNum = function(object)
      local isGenerated, refNum = staticUtil.getRefNum(object)

      staticUtil.Log(
        strings.GET_REFNUM_STR:format(
          isGenerated and 'Generated Object' or '' .. object.id, object.recordId, refNum
        )
      )
    end,
    StaticSwitcherRemoveModule = function(moduleName)
      uninstallModule(moduleName)
    end,
    -- Replace this with a toggle for a coroutine loader
    StaticSwitcherRunGlobalFunctions = function()
      for _, cell in ipairs(world.cells) do
        --- Global functions only run in exteriors
        if not cell.isExterior then goto SKIPCELL end

        --- if targetModule is nil, then, this cell isn't handled by any modules and should NOT be loaded
        local targetModules = getReplacementModuleForCell(cell)
        if not next(targetModules) then goto SKIPCELL end

        -- Log(
        --   ReplacingObjectsStr:format(cell)
        -- )

        for _, object in ipairs(cell:getAll()) do
          local replacementModule, replacementMesh = staticUtil.getObjectReplacement(object, targetModules)
          if not replacementMesh or not replacementModule then goto SKIPOBJECT end

          -- Log(
          --   ReplacingIndividualObjectStr:format(object, replacementMesh, replacementModule)
          -- )

          replaceObject(object, replacementModule, replacementMesh)

          ::SKIPOBJECT::
        end

        ::SKIPCELL::
      end
    end,
  },
  engineHandlers = {
    onPlayerAdded = function(player)
      player.type.sendMenuEvent(player, 'StaticSwitcherRequestGlobalFunctions')
    end,
    onUpdate = function()
      for i = #objectDeleteQueue, 1, -1 do
        local objectInfo = objectDeleteQueue[i]

        if objectInfo.ticks > 0 then
          objectInfo.ticks = objectInfo.ticks - 1
        else
          if objectInfo.removeOrDisable then
            if objectInfo.object.count > 0 and objectInfo.object:isValid() then
              objectInfo.object:remove()
              table.remove(objectDeleteQueue, i)
            end
          else
            objectInfo.object.enabled = false
            table.remove(objectDeleteQueue, i)
          end
        end
      end

      --- When a module is removed and all objects are removed
      --- kick every player from the game and force them to save
      if moduleToRemove and not next(objectDeleteQueue) then
        for _, player in ipairs(world.players) do
          player.type.sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', moduleToRemove)
        end

        moduleToRemove = nil
      end
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
                  targetScale = randomGen:range(actionDetails.scale.min or 1.0, actionDetails.scale.max)
                else
                  error("Invalid type for scale parameter: " .. scaleType)
                end

                targetScale = referenceScale * targetScale
                wasModified = true
              end

              if actionDetails.rotate then
                newTransform = getRotationValue {
                  object              = modifyTarget,
                  isRelative          = useRelativeTransform,
                  rotateActionDetails = actionDetails.rotate,
                  currentTransform    = newTransform or modifyTarget.rotation,
                }

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
        modifyTarget:teleport(newCell, newPos, newTransform)
      else
        local targetModules = getReplacementModuleForCell(object.cell)
        if not next(targetModules) then return end

        local replacementModule, replacementMesh = staticUtil.getObjectReplacement(object, targetModules)
        if not replacementModule or replacementModule == moduleToRemove or not replacementMesh then return end

        replaceObject(object, replacementModule, replacementMesh)
      end
    end,
    onSave = function()
      return {
        overrideRecords = overrideRecords,
        objectDeleteQueue = objectDeleteQueue,
        replacedObjectSet = replacedObjectSet,
      }
    end,
    onLoad = function(data)
      if not data then return end

      for target, source in pairs {
        [overrideRecords] = data.overrideRecords,
        [objectDeleteQueue] = data.objectDeleteQueue,
        [replacedObjectSet] = data.replacedObjectSet,
      } do
        staticUtil.deepCopy(target, source)
      end
    end,
  }
}
