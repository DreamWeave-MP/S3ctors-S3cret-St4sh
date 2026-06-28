---@omw-context global

local aux_util                                          = require 'openmw_aux.util'
local markup                                            = require 'openmw.markup'
local vfs                                               = require 'openmw.vfs'

local szudzik                                           = require 'scripts.s3.szudzik'
local tableHash                                         = require 'scripts.s3.tableHash'

local staticUtil                                        = require 'Scripts.staticSwitcher.util'

---@type string[], integer
local MeshReplacementModules, MeshReplacementModulesLen = {}, 0

---@type SSSObjectModificationStore
local ObjectModificationStore                           = {}

---@type SSSStaticReplacements
local StaticReplacements

---@type string[]
local ACTIONPRIORITY                                    = {
  'replace',
  'transform',
}

---@type string[]
local CONDITIONPRIORITY                                 = {
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

local error, ipairs, pairs                              = error, ipairs, pairs

---@param conditionData SSSConditionData
---@return integer?
local function sortConditionByType(conditionData)
  for index, conditionName in ipairs(CONDITIONPRIORITY) do
    if conditionData[conditionName] then return index end
  end
end

---@param actionData SSSInstanceAction
---@return integer?
local function sortActionByType(actionData)
  for index, actionName in ipairs(ACTIONPRIORITY) do
    if actionData[actionName] then return index end
  end
end
---@param meshReplacementsTable SSSModuleStatic
---@return SSSModule
local function staticModuleLoader(meshReplacementsTable)
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



---@param meshReplacementsPath string
---@param baseName string
local function loadSwitcherModule(meshReplacementsPath, baseName)
  if baseName == 'example' then return end

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

      local actionHash = tableHash(instance_action)
      instance_action.actionHash = actionHash

      modStore[index] = instance_action
    end

    ObjectModificationStore[baseName] = modStore
  else
    ---@cast meshReplacementsTable SSSModuleStatic
    StaticReplacements.ComposedReplacements[baseName] = staticModuleLoader(meshReplacementsTable)
  end

  meshReplacementsFile:close()
end

---@type SSSModuleCatalog
local ModuleCatalog = {
  moduleNames = MeshReplacementModules,
  numModules = MeshReplacementModulesLen,
  --- Indexed first by module name, then an array of actions and conditions
  --- all values in said array will be strings, and, when each lookup is performed they can/should be cached
  --- based on the generated hash of each set of table values (itself, keyed by the name of the loaded module)
  ObjectModificationStore = ObjectModificationStore,
}

---@param staticReplacements SSSStaticReplacements
---@return SSSModuleCatalog
return function(staticReplacements)
  StaticReplacements = assert(staticReplacements)

  for meshReplacementsPath in vfs.pathsWithPrefix 'scripts/staticSwitcher/data' do
    local baseName = staticUtil.getPathBaseName(meshReplacementsPath)
    loadSwitcherModule(meshReplacementsPath, baseName)
  end

  return ModuleCatalog
end
