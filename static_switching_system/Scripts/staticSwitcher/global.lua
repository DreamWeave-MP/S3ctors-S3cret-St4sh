local markup               = require 'openmw.markup'
local types                = require 'openmw.types'
local util                 = require 'openmw.util'
local vfs                  = require 'openmw.vfs'
local world                = require 'openmw.world'

local staticUtil           = require 'scripts.staticSwitcher.util'
local strings              = staticUtil.strings

local szudzik              = require 'scripts.staticSwitcher.szudzik'

local TICKS_TO_DELETE      = 3
local moduleToRemove

---@type ObjectDeleteData[]
local objectDeleteQueue    = {}

---@type table <GameObject, ReplacedObjectData>
local replacedObjectSet    = {}

--- Maps module names to the record ids they manage
---@type table<string, ReplacementMap>
local overrideRecords      = {}

---@type table<string, SSSModule> Map of file names handling mesh replacements to the data contained therein
local ComposedReplacements = {}

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

for meshReplacementsPath in vfs.pathsWithPrefix('scripts/staticSwitcher/data') do
  local baseName = staticUtil.getPathBaseName(meshReplacementsPath)
  if baseName == 'example' then goto SKIPMODULE end

  local meshReplacementsFile = vfs.open(meshReplacementsPath)
  local meshReplacementsText = meshReplacementsFile:read('*all')

  ---@type SSSModuleRaw
  local meshReplacementsTable = markup.decodeYaml(meshReplacementsText)
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

  ---@cast replacementTable SSSModule
  ComposedReplacements[baseName] = replacementTable

  meshReplacementsFile:close()

  ::SKIPMODULE::
end

--- Remove all objects which were replaced by a given module
--- After all objects from this module are inserted into the delete queue, mark this module as unusable for replacements
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
    overrideRecords = function()
      return util.makeReadOnly(overrideRecords)
    end,
    replacedObjectSet = function()
      return util.makeReadOnly(replacedObjectSet)
    end,
    uninstallModule = uninstallModule,
    verson = 2,
  },
  interfaceName = "StaticSwitcher_G",
  eventHandlers = {
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
      local targetModules = getReplacementModuleForCell(object.cell)
      if not next(targetModules) then return end

      local replacementModule, replacementMesh = staticUtil.getObjectReplacement(object, targetModules)
      if not replacementModule or replacementModule == moduleToRemove or not replacementMesh then return end

      replaceObject(object, replacementModule, replacementMesh)
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
