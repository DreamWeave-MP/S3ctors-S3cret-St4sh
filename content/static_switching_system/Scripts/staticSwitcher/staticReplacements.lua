---@omw-context global

local world                 = require 'openmw.world'

local szudzik               = require 'scripts.s3.szudzik'

---@type StaticUtil
local staticUtil            = require 'scripts.staticSwitcher.util'

local SwitcherSection       = require 'openmw.storage'.globalSection 'SettingsStaticSwitcher'

local createRecord          = world.createRecord

---@type table<string, SSSModule> Map of file names handling mesh replacements to the data contained therein
local ComposedReplacements  = {}

--- Maps module names to the record ids they manage
---@type SSSOverrideRecords
local OverrideRecords       = {}

---@type SSSReplacedObjectSet
local ReplacedObjectSet     = {}

---@type SSSDeleteManager
local DeleteManager

local assert, ipairs, pairs = assert, ipairs, pairs

---@param object openmw.GObject
---@param oldRecord openmw.types.ActivatorRecord
---@param newModel string
---@param replacementModule string
local function createReplacementRecord(object, oldRecord, newModel, replacementModule)
  local oldRecordId = object.recordId

  if not OverrideRecords[replacementModule] then OverrideRecords[replacementModule] = {} end
  local moduleRecords = OverrideRecords[replacementModule]
  if moduleRecords[oldRecordId] then return end

  local newRecord = { model = newModel }

  local scriptId = ''

  --- We now allow any record type, but,
  --- we don't necessarily copy all the relevant data for all possible types yet
  if oldRecord.name then newRecord.name = oldRecord.name end

  if oldRecord.mwscript then
    scriptId = oldRecord.mwscript
    newRecord.mwscript = scriptId
  end

  moduleRecords[oldRecordId] = createRecord(object.type.createRecordDraft(newRecord)).id
end

---@param object openmw.GObject
---@param replacementModule string the module which is replacing this object
---@param replacementMesh string the mesh which will be used in place of the original
local function replaceObject(object, replacementModule, replacementMesh)
  ---@type openmw.types.ActivatorRecord
  local objectRecord = object.type.records[object.recordId]

  local moduleData = ComposedReplacements[replacementModule]
  if moduleData.ignoreRecords and moduleData.ignoreRecords[object.recordId] then return end

  local oldModel = objectRecord.model

  if not oldModel or not staticUtil.assertMeshExists(
        replacementMesh,
        oldModel,
        objectRecord.id,
        replacementModule,
        ComposedReplacements[replacementModule].logString or 'StaticSwitchingSystem'
      ) then
    return
  end

  createReplacementRecord(object, objectRecord, replacementMesh, replacementModule)

  local targetRecord = OverrideRecords[replacementModule][objectRecord.id]
  local replacement = world.createObject(targetRecord)
  replacement:setScale(object.scale)

  ---@diagnostic disable-next-line: param-type-mismatch
  replacement:teleport(object.cell, object.position, object.rotation)

  DeleteManager:addObjectToDeleteQueue(object, false)

  if not ReplacedObjectSet[replacementModule] then ReplacedObjectSet[replacementModule] = {} end
  ReplacedObjectSet[replacementModule][replacement] = object
end

---@param replacementTable SSSModule
---@param cell openmw.core.GCell
---@return true? locationMatched whether or not a given cell is handled by this module
local function replacementTableMatchesCell(replacementTable, cell)
  local grid = replacementTable.gridIndices

  if grid and cell.isExterior then
    if grid[szudzik.getIndex(cell.gridX, cell.gridY)] then return true end
  end

  local nameMatches = replacementTable.cellNameMatches

  if not nameMatches then return end

  local cellIdLower, cellNameLower = cell.id:lower(), cell.name:lower()
  for _, cellName in ipairs(nameMatches) do
    if cellName == cellIdLower
        or cellName == cellNameLower
        or cellNameLower:find(cellName, 1, true)
        or cellIdLower:find(cellName, 1, true)
    then
      return true
    end
  end
end

---@param cell openmw.core.GCell
---@return table<string, SSSModule>? modulesForThisCell subtable of valid modules for this cell
local function getReplacementModuleForCell(cell)
  local modulesForThisCell

  for moduleName, moduleData in pairs(ComposedReplacements) do
    if replacementTableMatchesCell(moduleData, cell) then
      modulesForThisCell = modulesForThisCell or {}
      modulesForThisCell[moduleName] = moduleData
    end
  end

  return modulesForThisCell
end

---@param moduleName string
---@return boolean
local function moduleIsUninstallTarget(moduleName)
  return SwitcherSection:get 'StaticSwitcherDisableModule' and
      SwitcherSection:get 'StaticSwitcherModuleSelect' == moduleName
end

---@param object openmw.GObject
local function tryReplaceObject(object)
  local targetModules = getReplacementModuleForCell(object.cell)
  if not targetModules then return end

  local replacementModule, replacementMesh = staticUtil.getObjectReplacement(object, targetModules)

  if not replacementModule
      or moduleIsUninstallTarget(replacementModule)
      or not replacementMesh then
    return
  end

  replaceObject(object, replacementModule, replacementMesh)
end

---@type SSSStaticReplacements
local StaticReplacements = {
  ComposedReplacements = ComposedReplacements,
  OverrideRecords = OverrideRecords,
  ReplacedObjectSet = ReplacedObjectSet,
  tryReplaceObject = tryReplaceObject,
}

---@param deleteManager SSSDeleteManager
---@return SSSStaticReplacements
return function(deleteManager)
  DeleteManager = assert(deleteManager)
  return StaticReplacements
end
