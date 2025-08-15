local aux_util = require 'openmw_aux.util'
local markup = require 'openmw.markup'
local types = require 'openmw.types'
local vfs = require 'openmw.vfs'
local world = require 'openmw.world'

local szudzik = require 'scripts.staticSwitcher.szudzik'

local PREFIX_FRAME = '[ %s ]:'
local LOG_PREFIX = 'StaticSwitchingSystem'
local LOG_FORMAT_STR = '%s %s'
local MISSING_MESH_ERROR = [[
Requested model %s to replace %s on object %s, but the mesh was not found. The module: %s was not properly installed!]]

local InvalidTypeStr = 'Invalid type was provided: %s'

local TICKS_TO_DELETE = 3

local USE_GLOBAL_FUNCTIONS = false

---@type table <string, string>
local meshesToReplace = {}

---@type table <SzudzikCoord, boolean>
local globalCells = {}

---@type ObjectDeleteData[]
local objectDeleteQueue = {}

---@type table <string, boolean>
local replaceNames = {}

---@type MeshToSourceMap
local newMeshesToSourceFiles = {}

---@type table <GameObject, ReplacedObjectData>
local replacedObjectSet = {}

---@type ReplacementMap
local overrideRecords = {}

---@type table<string, boolean>
local disabledModules = {}

---Function to normalize path separators in a string
---@param path string
---@return string normalized path
local function normalizePath(path)
  local normalized, _ = path:gsub("\\", "/"):gsub("([^:])//+", "%1/")
  return normalized:lower()
end

--- Helper function to generate a log message string, but without printing it for reusability.
---@param message string
local function LogString(message, prefix)
  if not prefix then prefix = LOG_PREFIX end

  return LOG_FORMAT_STR:format(
    PREFIX_FRAME:format(prefix),
    message
  )
end

--- Actual log writing function, given whatever message
---@param message string
---@param prefix string
local function Log(message, prefix)
  print(LogString(message, prefix))
end

---@param object any
local function deepLog(object)
  print(
    LogString(
      aux_util.deepToString(object, 5)
    )
  )
end

---@param object GameObject
---@return ActivatorRecord Object record data
local function Record(object)
  return object.type.records[object.recordId]
end

---@param path string normalized VFS path referring to a mesh replacement map
local function getPathBaseName(path)
  ---@type string
  local baseName
  for part in string.gmatch(path, "([^/]+)") do
    baseName = part
  end

  for split in baseName:gmatch('([^.]+)') do
    return split
  end
end

---@param modelPath string
---@param originalModel string
---@param recordId string
---@return boolean? whether the mesh exists or not
local function assertMeshExists(modelPath, originalModel, recordId)
  if vfs.fileExists(modelPath) then return true end
  local logData = newMeshesToSourceFiles[modelPath]

  Log(
    MISSING_MESH_ERROR:format(modelPath, originalModel, recordId, logData.sourceFile),
    logData.logString
  )
end

---@param object GameObject
---@return boolean? whether the object can be replaced or not
local function canReplace(object)
  if not object.type then return end

  --- Check if the object has a new mesh
  local newMesh = meshesToReplace[Record(object).model]
  if not newMesh then return end

  -- And whether the new mesh is associated with a source file that has been disabled
  local sourceFile = newMeshesToSourceFiles[newMesh].sourceFile
  if disabledModules[sourceFile] then return end

  local cell = object.cell
  local isInReplaceableExterior = globalCells[szudzik.getIndex(cell.gridX, cell.gridY)]

  local isInReplaceableNamedCell = false
  for _, replaceString in ipairs(replaceNames) do
    if cell.name:lower():match(replaceString) then
      isInReplaceableNamedCell = true
      break
    end
  end

  return isInReplaceableExterior or isInReplaceableNamedCell or overrideList[object.id]
end

local function createReplacementRecord(object, oldModel, newModel)
  if overrideRecords[oldModel] then return end

  local newRecord = { model = newModel }

  local oldRecord = Record(object)
  if not types.Static.objectIsInstance(object) and not types.Activator.objectIsInstance(object) then
    error(
      InvalidTypeStr:format(object.type)
    )
  end

  if oldRecord.name then newRecord.name = oldRecord.name end
  if oldRecord.mwscript then newRecord.mwscript = oldRecord.mwscript end

  overrideRecords[oldModel] = world.createRecord(types.Activator.createRecordDraft(newRecord)).id
end

---@param path string Path to check for the `meshes/` prefix
---@return string original path, but with `meshes/` prepended
local function getMeshPath(path)
  path = path:gsub("^[/\\]+", "")

  if not path:match("^meshes/") then
    path = "meshes/" .. path
  end

  return path
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

---@param object GameObject
local function replaceObject(object)
  ---@type ActivatorRecord
  local objectRecord = Record(object)
  if not objectRecord.model then return end

  local oldModel = objectRecord.model

  if not meshesToReplace[oldModel] or ignoreList[oldModel] then return end

  local newModel = meshesToReplace[oldModel]

  if not assertMeshExists(newModel, oldModel, object.recordId) then return end

  createReplacementRecord(object, oldModel, newModel)

  local replacement = world.createObject(overrideRecords[oldModel])
  replacement:setScale(object.scale)
  replacement:teleport(object.cell.name, object.position, object.rotation)

  addObjectToDeleteQueue(object, false)

  replacedObjectSet[replacement] = {
    originalObject = object,
    sourceFile = newMeshesToSourceFiles[newModel].sourceFile
  }
end

local replaceNameLength = 0
for meshReplacementsPath in vfs.pathsWithPrefix('scripts/staticSwitcher/data') do
  local meshReplacementBaseName = getPathBaseName(meshReplacementsPath)

  local meshReplacementsFile = vfs.open(meshReplacementsPath)
  local meshReplacementsText = meshReplacementsFile:read('*all')
  local meshReplacementsTable = markup.decodeYaml(meshReplacementsText)

  for _, replaceString in ipairs(meshReplacementsTable.replace_names or {}) do
    replaceNameLength = replaceNameLength + 1
    replaceNames[replaceNameLength] = replaceString
  end

  for oldMesh, newMesh in pairs(meshReplacementsTable.replace_meshes or {}) do
    local normalizedNewMesh = normalizePath(getMeshPath(newMesh))
    meshesToReplace[normalizePath(getMeshPath(oldMesh))] = normalizedNewMesh

    --- Store the mesh associated with the source file and relevant log string.
    --- This is useful to emit errors from specific mods, and also to revert installations of specific modules.
    newMeshesToSourceFiles[normalizedNewMesh] = {
      sourceFile = meshReplacementBaseName,
      logString =
          meshReplacementsTable.log_name or LOG_PREFIX,
    }
  end

  for _, cellGrid in ipairs(meshReplacementsTable.exterior_cells or {}) do
    globalCells[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
  end

  meshReplacementsFile:close()
end

local function uninstallModule(fileName)
  local objectsToRemove, objectsToRemoveLength = {}, 0

  for newObject, oldObjectData in pairs(replacedObjectSet) do
    if oldObjectData.sourceFile == fileName then
      oldObjectData.originalObject.enabled = true
      addObjectToDeleteQueue(newObject, true)
    end

    objectsToRemoveLength = objectsToRemoveLength + 1
    objectsToRemove[objectsToRemoveLength] = newObject
  end

  for i = 1, objectsToRemoveLength, 1 do
    local targetObject = objectsToRemove[i]
    replacedObjectSet[targetObject] = nil
  end

  disabledModules[fileName] = true
end

return {
  interface = {
    overrideRecords = function()
      deepLog(overrideRecords)
    end,
    replacedObjectSet = function()
      deepLog(replacedObjectSet)
    end,
    uninstallModule = uninstallModule,
  },
  interfaceName = "StaticSwitcher_G",
  eventHandlers = {
    StaticSwitcherEnableGlobalFunctions = function(state)
      USE_GLOBAL_FUNCTIONS = state
    end,
    StaticSwitcherRemoveModule = function(moduleName)
      uninstallModule(moduleName)

      for _, player in ipairs(world.players) do
        player.type.sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', moduleName)
      end
    end,
    StaticSwitcherRunGlobalFunctions = function()
      for _, cell in ipairs(world.cells) do
        if not cell.isExterior then goto SKIP end

        local cellIndex = szudzik.getIndex(cell.gridX, cell.gridY)
        local szudzikTest = globalCells[cellIndex]

        if not szudzikTest then goto SKIP end

        for _, object in ipairs(cell:getAll()) do
          if canReplace(object) then
            replaceObject(object)
          end
        end

        ::SKIP::
      end
    end,
  },
  engineHandlers = {
    onPlayerAdded = function(player)
      player.type.sendMenuEvent(player, 'StaticSwitcherRequestGlobalFunctions')
    end,
    onUpdate = function()
      local i = 1
      while i <= #objectDeleteQueue do
        local objectInfo = objectDeleteQueue[i]

        if objectInfo.ticks > 0 then
          objectInfo.ticks = objectInfo.ticks - 1
          i = i + 1
        else
          if objectInfo.removeOrDisable then
            if objectInfo.object.count > 0 and objectInfo.object:isValid() then
              objectInfo.object:remove()
            end
          else
            objectInfo.object.enabled = false
          end

          table.remove(objectDeleteQueue, i)
        end
      end
    end,
    onObjectActive = function(object)
      if object.cell.isExterior and USE_GLOBAL_FUNCTIONS then
        return
      elseif canReplace(object) then
        replaceObject(object)
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
      if data then
        for k, v in pairs(data.overrideRecords or {}) do
          overrideRecords[k] = v
        end

        for k, v in ipairs(data.objectDeleteQueue or {}) do
          objectDeleteQueue[k] = v
        end

        for k, v in ipairs(data.replacedObjectSet or {}) do
          replacedObjectSet[k] = v
        end
      end
    end,
  }
}
