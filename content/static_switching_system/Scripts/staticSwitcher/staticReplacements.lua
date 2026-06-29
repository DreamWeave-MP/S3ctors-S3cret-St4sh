---@omw-context global

local world                 = require 'openmw.world'

local szudzik               = require 'scripts.s3.szudzik'

---@type StaticUtil
local staticUtil            = require 'scripts.staticSwitcher.util'

local SwitcherSection       = require 'openmw.storage'.globalSection 'SettingsStaticSwitcher'

local createRecord          = world.createRecord

local MAX_REPLACEMENT_CHAIN_DEPTH = 8
---@type table<string, SSSModule> Map of canonical module ids handling mesh replacements to the data contained therein
local ComposedReplacements  = {}

--- Maps canonical module ids to the record ids they manage
---@type SSSOverrideRecords
local OverrideRecords       = {}

---@type SSSReplacedObjectSet
local ReplacedObjectSet     = {}

---@type SSSReplacementStepBySource
local ReplacementStepBySource = {}

---@type SSSReplacementChains
local ReplacementChains    = {
  entries = {},
  byObjectId = {},
}

---@type string[]?
local ReplacementModuleOrder

---@type SSSDeleteManager
local DeleteManager

---@type fun(moduleKey: string): string?
local ResolveModuleId

local assert, ipairs, pairs, sort = assert, ipairs, pairs, table.sort

---@param targetTable table
local function clearTable(targetTable)
  for key in pairs(targetTable) do targetTable[key] = nil end
end

---@param moduleKey string
---@return string? moduleId
local function resolveModuleId(moduleKey)
  return ResolveModuleId and ResolveModuleId(moduleKey) or moduleKey
end

---@return string[] moduleOrder
local function getReplacementModuleOrder()
  if not ReplacementModuleOrder then
    ReplacementModuleOrder = {}

    for moduleName in pairs(ComposedReplacements) do
      ReplacementModuleOrder[#ReplacementModuleOrder + 1] = moduleName
    end

    sort(ReplacementModuleOrder)
  end

  return ReplacementModuleOrder
end

---@param sourceObject openmw.GObject
---@return boolean
local function sourceObjectAlreadyReplaced(sourceObject)
  local replacement = ReplacementStepBySource[sourceObject.id]

  if not replacement then return false end

  if replacement:isValid() then return true end

  ReplacementStepBySource[sourceObject.id] = nil
  return false
end

local function rebuildReplacementStepBySource()
  clearTable(ReplacementStepBySource)

  for _, moduleReplacements in pairs(ReplacedObjectSet) do
    for replacement, sourceObject in pairs(moduleReplacements) do
      if replacement:isValid() and sourceObject:isValid() then
        ReplacementStepBySource[sourceObject.id] = replacement
      end
    end
  end
end

local function migrateOverrideRecords()
  local migrations = {}

  for moduleName, moduleRecords in pairs(OverrideRecords) do
    local moduleId = resolveModuleId(moduleName)

    if moduleId and moduleId ~= moduleName then
      migrations[#migrations + 1] = {
        from = moduleName,
        records = moduleRecords,
        to = moduleId,
      }
    end
  end

  for _, migration in ipairs(migrations) do
    local targetRecords = OverrideRecords[migration.to]

    if not targetRecords then
      OverrideRecords[migration.to] = migration.records
    else
      for recordId, replacementRecordId in pairs(migration.records) do
        if not targetRecords[recordId] then targetRecords[recordId] = replacementRecordId end
      end
    end

    OverrideRecords[migration.from] = nil
  end
end

local function rebuildReplacedObjectSetFromChains()
  clearTable(ReplacedObjectSet)

  for _, chain in ipairs(ReplacementChains.entries) do
    for _, step in ipairs(chain.steps) do
      local moduleReplacements = ReplacedObjectSet[step.moduleName]

      if not moduleReplacements then
        moduleReplacements = {}
        ReplacedObjectSet[step.moduleName] = moduleReplacements
      end

      moduleReplacements[step.replacement] = step.source
    end
  end
end

---@param object openmw.GObject
---@return SSSReplacementChain? chain
local function getReplacementChain(object)
  return ReplacementChains.byObjectId[object.id]
end

---@param object openmw.GObject
---@return SSSReplacementChain chain
local function getOrCreateReplacementChain(object)
  local chain = getReplacementChain(object)
  if chain then return chain end

  chain = {
    root = object,
    current = object,
    steps = {},
    appliedModules = {},
  }

  ReplacementChains.entries[#ReplacementChains.entries + 1] = chain
  ReplacementChains.byObjectId[object.id] = chain

  return chain
end

---@param chain SSSReplacementChain
---@return boolean
local function chainCanContinue(chain)
  return #chain.steps < MAX_REPLACEMENT_CHAIN_DEPTH
end

---@param chain SSSReplacementChain?
---@param moduleName string
---@return boolean
local function chainCanApplyModule(chain, moduleName)
  return not chain or not chain.appliedModules[moduleName]
end

---@param chain SSSReplacementChain
---@param moduleName string
---@param sourceObject openmw.GObject
---@param replacement openmw.GObject
local function addReplacementChainStep(chain, moduleName, sourceObject, replacement)
  local steps = chain.steps
  steps[#steps + 1] = {
    moduleName = moduleName,
    source = sourceObject,
    replacement = replacement,
  }

  chain.current = replacement
  chain.appliedModules[moduleName] = true
  ReplacementChains.byObjectId[sourceObject.id] = chain
  ReplacementChains.byObjectId[replacement.id] = chain
  ReplacementStepBySource[sourceObject.id] = replacement
end

local function rebuildReplacementChainIndexes()
  local oldEntries = ReplacementChains.entries
  local newEntries = {}

  clearTable(ReplacementChains.byObjectId)
  clearTable(ReplacementStepBySource)

  for _, chain in ipairs(oldEntries) do
    local root = chain.root

    if staticUtil.isGObject(root) and root:isValid() then
      local sanitizedSteps = {}
      local appliedModules = {}
      local current = root

      for _, step in ipairs(chain.steps or {}) do
        local moduleName = step.moduleName
        local sourceObject, replacement = step.source, step.replacement

        if #sanitizedSteps >= MAX_REPLACEMENT_CHAIN_DEPTH
            or not moduleName
            or appliedModules[moduleName] then
          break
        elseif staticUtil.isGObject(sourceObject)
            and staticUtil.isGObject(replacement)
            and sourceObject:isValid()
            and replacement:isValid()
            and sourceObject.id == current.id then
          sanitizedSteps[#sanitizedSteps + 1] = step
          appliedModules[moduleName] = true
          current = replacement

          ReplacementChains.byObjectId[sourceObject.id] = chain
          ReplacementChains.byObjectId[replacement.id] = chain
          ReplacementStepBySource[sourceObject.id] = replacement
        else
          break
        end
      end

      if #sanitizedSteps > 0 then
        chain.steps = sanitizedSteps
        chain.appliedModules = appliedModules
        chain.current = current
        ReplacementChains.byObjectId[root.id] = chain
        newEntries[#newEntries + 1] = chain
      end
    end
  end

  ReplacementChains.entries = newEntries
  rebuildReplacedObjectSetFromChains()
end

---@param sourceToEdge table<string, SSSReplacementChainStep>
---@param replacementIds table<string, true>
---@param moduleName string
---@param sourceObject any
---@param replacement any
local function addImportEdge(sourceToEdge, replacementIds, moduleName, sourceObject, replacement)
  if type(moduleName) ~= 'string'
      or not staticUtil.isGObject(sourceObject)
      or not staticUtil.isGObject(replacement)
      or not sourceObject:isValid()
      or not replacement:isValid() then
    return
  end

  local moduleId = resolveModuleId(moduleName) or moduleName

  sourceToEdge[sourceObject.id] = {
    moduleName = moduleId,
    source = sourceObject,
    replacement = replacement,
  }

  replacementIds[replacement.id] = true
end

---@param sourceToEdge table<string, SSSReplacementChainStep>
---@param replacementIds table<string, true>
local function importReplacementChainsFromEdges(sourceToEdge, replacementIds)
  clearTable(ReplacementChains.entries)
  clearTable(ReplacementChains.byObjectId)
  local visitedEdges = {}

  local function importChain(firstEdge)
    if visitedEdges[firstEdge] then return end

    local chain = {
      root = firstEdge.source,
      current = firstEdge.source,
      steps = {},
      appliedModules = {},
    }

    local edge = firstEdge

    while edge
        and not visitedEdges[edge]
        and not chain.appliedModules[edge.moduleName]
        and #chain.steps < MAX_REPLACEMENT_CHAIN_DEPTH do
      visitedEdges[edge] = true
      chain.steps[#chain.steps + 1] = edge
      chain.appliedModules[edge.moduleName] = true
      chain.current = edge.replacement
      edge = sourceToEdge[chain.current.id]
    end

    if #chain.steps > 0 then ReplacementChains.entries[#ReplacementChains.entries + 1] = chain end
  end

  for sourceId, edge in pairs(sourceToEdge) do
    if not replacementIds[sourceId] then importChain(edge) end
  end

  for _, edge in pairs(sourceToEdge) do
    importChain(edge)
  end

  rebuildReplacementChainIndexes()
end

local function importLegacyReplacementChains()
  local sourceToEdge, replacementIds = {}, {}

  for moduleName, moduleReplacements in pairs(ReplacedObjectSet) do
    for replacement, sourceObject in pairs(moduleReplacements) do
      addImportEdge(sourceToEdge, replacementIds, moduleName, sourceObject, replacement)
    end
  end

  importReplacementChainsFromEdges(sourceToEdge, replacementIds)
end

---@param savedChains SSSReplacementChainsSaved
local function importSavedReplacementChains(savedChains)
  local sourceToEdge, replacementIds = {}, {}

  if type(savedChains.entries) ~= 'table' then return importLegacyReplacementChains() end

  for _, chain in ipairs(savedChains.entries) do
    if type(chain) == 'table' and type(chain.steps) == 'table' then
      for _, step in ipairs(chain.steps) do
        if type(step) == 'table' then
          addImportEdge(sourceToEdge, replacementIds, step.moduleName, step.source, step.replacement)
        end
      end
    end
  end

  importReplacementChainsFromEdges(sourceToEdge, replacementIds)
end

---@return SSSReplacementChainsSaved
local function saveReplacementChains()
  local savedEntries = {}

  for _, chain in ipairs(ReplacementChains.entries) do
    savedEntries[#savedEntries + 1] = {
      root = chain.root,
      steps = chain.steps,
    }
  end

  return {
    entries = savedEntries,
  }
end

---@param savedChains SSSReplacementChains?
local function loadReplacementChains(savedChains)
  clearTable(ReplacementChains.entries)
  clearTable(ReplacementChains.byObjectId)

  if savedChains and savedChains.entries then
    importSavedReplacementChains(savedChains)
  else
    importLegacyReplacementChains()
  end
end

---@param moduleName string
---@return string? removedModule
local function uninstallModule(moduleName)
  moduleName = resolveModuleId(moduleName)
  if not moduleName then return end

  local removedModule

  for _, chain in ipairs(ReplacementChains.entries) do
    local firstRemovedStepIndex

    for stepIndex, step in ipairs(chain.steps) do
      if step.moduleName == moduleName then
        firstRemovedStepIndex = stepIndex
        break
      end
    end

    if firstRemovedStepIndex then
      local restoreObject = chain.steps[firstRemovedStepIndex].source
      if restoreObject:isValid() and restoreObject.count >= 1 then
        DeleteManager:removeObjectFromDeleteQueue(restoreObject, false)
        restoreObject.enabled = true
      end

      for stepIndex = #chain.steps, firstRemovedStepIndex, -1 do
        local step = chain.steps[stepIndex]
        local moduleReplacements = ReplacedObjectSet[step.moduleName]

        if moduleReplacements then moduleReplacements[step.replacement] = nil end
        DeleteManager:addObjectToDeleteQueue(step.replacement, true)
        chain.steps[stepIndex] = nil
      end

      removedModule = moduleName
    end
  end

  rebuildReplacementChainIndexes()
  return removedModule
end

---@param object openmw.GObject
---@param oldRecord openmw.types.ActivatorRecord -- HACK: Not actually an activator record, but easier to annotate.
---@param newModel string
---@param replacementModule string
local function createReplacementRecord(object, oldRecord, newModel, replacementModule)
  local oldRecordId = object.recordId

  if not OverrideRecords[replacementModule] then OverrideRecords[replacementModule] = {} end
  local moduleRecords = OverrideRecords[replacementModule]
  if moduleRecords[oldRecordId] then return end

  local newRecord = { template = oldRecord, model = newModel }

  moduleRecords[oldRecordId] = createRecord(object.type.createRecordDraft(newRecord)).id
end

---@param object openmw.GObject
---@param replacementModule string the module which is replacing this object
---@param replacementMesh string the mesh which will be used in place of the original
local function replaceObject(object, replacementModule, replacementMesh, chain)
  if sourceObjectAlreadyReplaced(object) then return end

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
  addReplacementChainStep(chain or getOrCreateReplacementChain(object), replacementModule, object, replacement)
end

---@param replacementTable SSSModule
---@param cell openmw.core.GCell
---@return true? locationMatched whether or not a given cell is handled by this module
local function replacementTableMatchesCell(replacementTable, cell)
  local grid = replacementTable.gridIndices
  local nameMatches = replacementTable.cellNameMatches

  if not grid and not nameMatches then return true end

  if grid and cell.isExterior then
    if grid[szudzik.getIndex(cell.gridX, cell.gridY)] then return true end
  end

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

---@param moduleName string
---@return boolean
local function moduleIsUninstallTarget(moduleName)
  return SwitcherSection:get 'StaticSwitcherDisableModule' and
      resolveModuleId(SwitcherSection:get 'StaticSwitcherModuleSelect') == moduleName
end

---@param object openmw.GObject
---@param chain SSSReplacementChain?
---@return string? replacementModule
---@return string? replacementMesh
local function getObjectReplacement(object, chain)
  for _, moduleName in ipairs(getReplacementModuleOrder()) do
    local moduleData = ComposedReplacements[moduleName]

    if moduleData
        and not moduleIsUninstallTarget(moduleName)
        and chainCanApplyModule(chain, moduleName)
        and replacementTableMatchesCell(moduleData, object.cell) then
      local replacementMesh = staticUtil.getReplacementMeshForObject(moduleData.meshMap, object)
      if replacementMesh then return moduleName, replacementMesh end
    end
  end
end

---@param object openmw.GObject
local function tryReplaceObject(object)
  if sourceObjectAlreadyReplaced(object) then return end

  local chain = getReplacementChain(object)
  if chain and not chainCanContinue(chain) then return end

  local replacementModule, replacementMesh = getObjectReplacement(object, chain)

  if not replacementModule or not replacementMesh then return end

  replaceObject(object, replacementModule, replacementMesh, chain)
end

---@type SSSStaticReplacements
local StaticReplacements = {
  ComposedReplacements = ComposedReplacements,
  loadReplacementChains = loadReplacementChains,
  ReplacementChains = ReplacementChains,
  OverrideRecords = OverrideRecords,
  migrateOverrideRecords = migrateOverrideRecords,
  rebuildReplacementStepBySource = rebuildReplacementStepBySource,
  ReplacedObjectSet = ReplacedObjectSet,
  saveReplacementChains = saveReplacementChains,
  uninstallModule = uninstallModule,
  tryReplaceObject = tryReplaceObject,
}

---@param moduleResolver fun(moduleKey: string): string?
function StaticReplacements.setModuleResolver(moduleResolver)
  ResolveModuleId = moduleResolver
end

---@param deleteManager SSSDeleteManager
---@return SSSStaticReplacements
return function(deleteManager)
  DeleteManager = assert(deleteManager)
  return StaticReplacements
end
