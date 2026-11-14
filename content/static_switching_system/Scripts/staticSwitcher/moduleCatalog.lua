---@omw-context global

local aux_util = require 'openmw_aux.util'
local markup = require 'openmw.markup'
local types = require 'openmw.types'
local vfs = require 'openmw.vfs'

local szudzik = require 'scripts.s3.szudzik'
local tableHash = require 'scripts.s3.tableHash'

local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'
local staticUtil = require 'Scripts.staticSwitcher.util'
local validation = require 'Scripts.staticSwitcher.validation'

local InfoLog, ErrorLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  InfoLog = logger.info
  ErrorLog = logger.error
end

local pcall, type = pcall, type
local StrFormat, StrLower, StrGsub, StrMatch =
  string.format, string.lower, string.gsub, string.match

local DATA_PREFIX = 'scripts/staticswitcher/data/'

---@type string[], integer
local ModuleIds, ModuleIdsLen = {}, 0

---@type table<string, SSSModuleIdentity>
local Modules = {}

---@type table<string, string>
local ModuleLabels = {}

---@type table<string, string[]>
local LegacyIdsByBasename = {}

---@type table<string, string>
local ModulePriorities = {}

---@type SSSObjectModificationStore
local ObjectModificationStore = {}

local PRIORITY_ORDER = {
  cleanup = 1,
  foundation = 2,
  remodel = 3,
  balance = 4,
  standard = 5,
  polish = 6,
  finisher = 7,
}

---@type string[]
local SortedModuleIds = {}

---@type string[]
local SortedStaticModuleIds = {}

---@type table<string, SSSTriggerRule[]>
local RulesByTrigger = { [TriggerContext.ACTIVE] = {} }

---@type table<string, SSSSweep>
local Sweeps = {}

---@type table<string, string>
local JournalSweepKeys = {}

local DEFAULT_TRIGGER_NAMES = { TriggerContext.ACTIVE }
local JOURNAL_SWEEP_PREFIX = 'journal:'

---@type SSSStaticReplacements
local StaticReplacements

---@type string[]
local ACTIONPRIORITY = {
  'replace',
  'transform',
  'teleport',
  'set_ownership',
  'add_tag',
  'remove_tag',
  'add',
  'remove',
  'equip',
  'unequip',
  'add_spell',
  'remove_spell',
  'add_active_spell',
  'lock_level',
  'key',
  'trap',
  'create',
  'global_set',
  'set_weather',
  'playsound',
  'add_lua_script',
  'activate_by_player',
  'remove_lua_script',
  'run_lua_script',
  'call_interface',
  'send_event',
  'send_global_event',
  'disable',
  'delete',
}

---@type string[]
local CONDITIONPRIORITY = {
  --- Locational conditions have highest priority
  'cell',
  'cell_match',
  'coords',
  'content_file',
  'exterior',
  'quasi_exterior',
  'region',
  'worldspace',
  'object_type',
  --- Record ID comes before many other searches as it's likely to be cheap and common
  'record_id',
  'by_player',
  'used_item',
  'content_file_target',
  --- Object property checks
  'generated_record',
  'generated_object',
  'mesh',
  'scale',
  'has_name',
  'has_lua_script',
  'has_mwscript',
  'has_tag',
  'cell_tag',
  'is_dead',
  'is_follower',
  'is_respawning',
  'creature_type',
  'has_enchantment',
  'enchantment',
  'race',
  'target_disposition',
  'locked',
  'has_key',
  'has_trap',
  --- Name matches should always be last as they're inevitably going to be the slowest
  'nameMatch',
  'carrying',
  --- Journal gates are relatively expensive (player/quest lookup); evaluated last
  'has_journal',
  'global_value',
  'player_level',
  'target_level',
  'player_attribute',
  'player_skill',
  'target_attribute',
  'target_skill',
  'player_spell',
  'target_spell',
  'player_health',
  'player_magicka',
  'player_fatigue',
  'target_health',
  'target_magicka',
  'target_fatigue',
  'time_of_day',
  'day_of_week',
  'player_faction',
  'faction_owner_id',
  'owner_id',
  'faction_owner_rank',
  'target_faction',
  'target_class',
  'player_equipped',
  'current_weather',
  'not',
}

local error, NewTable, next, nkeys, pairs, sort =
  error,
  ---@diagnostic disable-next-line: undefined-field
  table.new,
  next,
  ---@diagnostic disable-next-line: undefined-field
  table.nkeys,
  pairs,
  table.sort

---@param modulePath string
---@return string pathWithoutExtension
local function stripYamlExtension(modulePath)
  local result, _ = StrGsub(StrGsub(modulePath, '%.yaml$', ''), '%.yml$', '')
  return result
end

---@param modulePath string
---@return string label
local function getModuleLabel(modulePath)
  local result, _ = StrGsub(stripYamlExtension(modulePath), '^' .. DATA_PREFIX, '')
  return result
end

---@param modulePath string
---@return SSSModuleIdentity moduleIdentity
local function createModuleIdentity(modulePath)
  local moduleId = staticUtil.normalizePath(modulePath)
  local displayName = staticUtil.getPathBaseName(moduleId)

  return {
    id = moduleId,
    path = moduleId,
    displayName = displayName,
    label = getModuleLabel(moduleId),
  }
end

---@param moduleIdentity SSSModuleIdentity
local function addModuleIdentity(moduleIdentity)
  local moduleId, displayName = moduleIdentity.id, moduleIdentity.displayName

  Modules[moduleId] = moduleIdentity
  ModuleLabels[moduleId] = moduleIdentity.label

  ModuleIdsLen = ModuleIdsLen + 1
  ModuleIds[ModuleIdsLen] = moduleId

  local legacyIds = LegacyIdsByBasename[displayName]
  if not legacyIds then
    legacyIds = {}
    LegacyIdsByBasename[displayName] = legacyIds
  end

  legacyIds[#legacyIds + 1] = moduleId
end

---@param moduleKey string
---@return string? moduleId
local function resolveModuleId(moduleKey)
  if Modules[moduleKey] then return moduleKey end

  local legacyIds = LegacyIdsByBasename[moduleKey]
  if legacyIds and #legacyIds == 1 then return legacyIds[1] end
end

---@param conditionData SSSConditionData
---@return integer?
local function sortConditionByType(conditionData)
  for condPrioIndex = 1, #CONDITIONPRIORITY do
    local conditionName = CONDITIONPRIORITY[condPrioIndex]
    if conditionData[conditionName] ~= nil then return condPrioIndex end
  end
end

---@param actionData SSSInstanceAction
---@return integer?
local function sortActionByType(actionData)
  for actPrioIndex = 1, #ACTIONPRIORITY do
    local actionName = ACTIONPRIORITY[actPrioIndex]
    if actionData[actionName] ~= nil then return actPrioIndex end
  end
end

local LOWERED_CONDITION_KEYS = {
  cell_match = true,
  content_file = true,
  content_file_target = 'keys',
  record_id = true,
  used_item = true,
  faction_owner_id = true,
  owner_id = true,
  target_class = true,
  current_weather = true,
  day_of_week = true,
  region = true,
  worldspace = true,
  has_key = true,
  has_trap = true,
  has_mwscript = true,
  race = true,
  enchantment = true,
  global_value = 'arrayKeys',
}

---@param value string|string[]
---@return string|string[] loweredValue
local function lowerStrings(value)
  local valueType = type(value)

  if valueType == 'string' then return StrLower(value) end

  if valueType == 'table' then
    for i = 1, #value do
      value[i] = StrLower(value[i])
    end
  end

  return value
end

--- Lowercases the key of a single-entry map such as `{ RecordId = chance }`.
---@param entry table<string, number|table>
local function lowerSingleKey(entry)
  local key, value = next(entry)
  assert(key ~= nil and value ~= nil, 'expected a single-entry map')

  local loweredKey = StrLower(key)
  if loweredKey == key then return end

  entry[loweredKey] = value
  entry[key] = nil
end

--- `cell` values are lowered only after the rule is hashed: the authored casing is part of
--- every actionHash already stored in saved once caches.
---@param conditionData SSSConditionData
local function lowerCellCondition(conditionData)
  if conditionData.cell ~= nil then conditionData.cell = lowerStrings(conditionData.cell) end

  local negatedCondition = conditionData['not']
  if type(negatedCondition) == 'table' then lowerCellCondition(negatedCondition) end
end

--- Pre-lowercase string condition values at module load time so handlers
--- don't pay :lower() on user-provided strings in the hot path.
---@param conditionName string
---@param conditionValue any
---@return any
local function sanitizeConditionValue(conditionName, conditionValue)
  local keyPolicy = LOWERED_CONDITION_KEYS[conditionName]
  if not keyPolicy then return conditionValue end

  if keyPolicy == 'keys' then
    if type(conditionValue) == 'table' then
      local lowered = {}
      for k, v in pairs(conditionValue) do
        lowered[StrLower(k)] = v
      end
      return lowered
    end
    return conditionValue
  end

  if keyPolicy == 'arrayKeys' then
    if type(conditionValue) == 'table' then
      for i = 1, #conditionValue do
        lowerSingleKey(conditionValue[i])
      end
    end
    return conditionValue
  end

  return lowerStrings(conditionValue)
end

---@param meshReplacementsTable SSSModuleStatic
---@return SSSModule
local function staticModuleLoader(meshReplacementsTable)
  local meshMap
  if meshReplacementsTable.replace_meshes and next(meshReplacementsTable.replace_meshes) ~= nil then
    --- Rubic0n annotations need updated for OpenResty additions
    ---@diagnostic disable-next-line: undefined-field
    if NewTable then
      ---@diagnostic disable-next-line: undefined-field
      meshMap = NewTable(0, nkeys(meshReplacementsTable.replace_meshes))
    else
      meshMap = {}
    end
  end

  local cellNameMatches
  if meshReplacementsTable.replace_names and next(meshReplacementsTable.replace_names) ~= nil then
    if NewTable then
      cellNameMatches = NewTable(#meshReplacementsTable.replace_names, 0)
    else
      cellNameMatches = {}
    end
  end

  local gridIndices
  if meshReplacementsTable.exterior_cells and next(meshReplacementsTable.exterior_cells) ~= nil then
    if NewTable then
      gridIndices = NewTable(0, #meshReplacementsTable.exterior_cells)
    else
      gridIndices = {}
    end
  end

  local regionMatches
  if
    meshReplacementsTable.replace_regions and next(meshReplacementsTable.replace_regions) ~= nil
  then
    if NewTable then
      regionMatches = NewTable(0, #meshReplacementsTable.replace_regions)
    else
      regionMatches = {}
    end
  end

  local ignoreRecords
  if meshReplacementsTable.ignore_records and next(meshReplacementsTable.ignore_records) ~= nil then
    if NewTable then
      ignoreRecords = NewTable(0, #meshReplacementsTable.ignore_records)
    else
      ignoreRecords = {}
    end
  end

  local replacementTable
  if NewTable then
    local numElements = (meshMap and 1 or 0)
      + (cellNameMatches and 1 or 0)
      + (gridIndices and 1 or 0)
      + (regionMatches and 1 or 0)
      + (ignoreRecords and 1 or 0)
      + (meshReplacementsTable.log_name and 1 or 0)
    replacementTable = NewTable(0, numElements)
  else
    replacementTable = {}
  end

  if meshMap then replacementTable.meshMap = meshMap end
  if cellNameMatches then replacementTable.cellNameMatches = cellNameMatches end
  if gridIndices then replacementTable.gridIndices = gridIndices end
  if regionMatches then replacementTable.regionMatches = regionMatches end
  if ignoreRecords then replacementTable.ignoreRecords = ignoreRecords end
  if meshReplacementsTable.log_name then
    replacementTable.logString = meshReplacementsTable.log_name
  end

  if meshMap then
    local key, value = '', ''
    for oldMesh, newMesh in pairs(meshReplacementsTable.replace_meshes) do
      key = staticUtil.normalizePath(staticUtil.getMeshPath(oldMesh))
      value = staticUtil.normalizePath(staticUtil.getMeshPath(newMesh))

      meshMap[key] = value
    end
  end

  if cellNameMatches then
    for nameIdx = 1, #meshReplacementsTable.replace_names do
      local replaceString = meshReplacementsTable.replace_names[nameIdx]
      cellNameMatches[nameIdx] = StrLower(replaceString)
    end
  end

  if gridIndices then
    for cellIdx = 1, #meshReplacementsTable.exterior_cells do
      local cellGrid = meshReplacementsTable.exterior_cells[cellIdx]
      replacementTable.gridIndices[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
    end
  end

  if regionMatches then
    for regionIdx = 1, #meshReplacementsTable.replace_regions do
      local regionName = meshReplacementsTable.replace_regions[regionIdx]
      regionMatches[StrLower(regionName)] = true
    end
  end

  if ignoreRecords then
    for recIdx = 1, #meshReplacementsTable.ignore_records do
      local ignoreRecord = meshReplacementsTable.ignore_records[recIdx]
      replacementTable.ignoreRecords[ignoreRecord] = true
    end
  end

  return replacementTable
end

---@param instanceRule SSSInstanceRule
local function prepareInstanceRule(instanceRule)
  local conditions = instanceRule.conditions

  if conditions then
    for condIdx = 1, #conditions do
      local conditionData = conditions[condIdx]
      for conditionName, conditionValue in pairs(conditionData) do
        if conditionName == 'not' and type(conditionValue) == 'table' then
          for innerName, innerValue in pairs(conditionValue) do
            conditionValue[innerName] = sanitizeConditionValue(innerName, innerValue)
          end
        else
          conditionData[conditionName] = sanitizeConditionValue(conditionName, conditionValue)
        end
      end
    end

    conditions = aux_util.mapFilterSort(conditions, sortConditionByType)
    instanceRule.conditions = conditions
  end

  instanceRule.actions = aux_util.mapFilterSort(instanceRule.actions, sortActionByType)

  for actSanIdx = 1, #instanceRule.actions do
    local actionData = instanceRule.actions[actSanIdx]

    if actionData.key then
      for i = 1, #actionData.key do
        lowerSingleKey(actionData.key[i])
      end
    end

    if actionData.trap then
      for i = 1, #actionData.trap do
        lowerSingleKey(actionData.trap[i])
      end
    end
  end

  instanceRule.actionHash = tableHash(instanceRule)

  if conditions then
    for condIdx = 1, #conditions do
      lowerCellCondition(conditions[condIdx])
    end
  end
end

---@param modulePath string
---@param instances SSSInstanceRule[]
---@return SSSInstanceRule[] rules
local function buildInstanceRules(modulePath, instances)
  local rules = {}

  for ruleIdx = 1, #instances do
    local instanceRule = instances[ruleIdx]

    if validation.validateRule(modulePath, ruleIdx, instanceRule) then
      prepareInstanceRule(instanceRule)
      rules[#rules + 1] = instanceRule
    end
  end

  return rules
end

---@param modulePath string
---@return SSSModuleRaw moduleData
local function readSwitcherModule(modulePath)
  local moduleFile = vfs.open(modulePath)
  local moduleText = moduleFile:read '*all'
  moduleFile:close()

  local moduleData = markup.decodeYaml(moduleText)
  if type(moduleData) ~= 'table' then error('the file does not contain a YAML map', 0) end

  return moduleData
end

--- Registers nothing until the whole module has been built, so a module that fails
--- part-way leaves no trace in the catalog.
---@param meshReplacementsPath string
---@param moduleIdentity SSSModuleIdentity
local function loadSwitcherModule(meshReplacementsPath, moduleIdentity)
  local meshReplacementsTable = readSwitcherModule(meshReplacementsPath)

  validation.validate(meshReplacementsPath, meshReplacementsTable)
  local priority = meshReplacementsTable.priority or 'standard'
  assert(PRIORITY_ORDER[priority], 'Invalid SSS module priority: ' .. tostring(priority))

  local moduleId = moduleIdentity.id

  ---@cast meshReplacementsTable SSSModuleInstances
  if meshReplacementsTable.instances then
    local rules = buildInstanceRules(meshReplacementsPath, meshReplacementsTable.instances)

    ObjectModificationStore[moduleId] = {
      rules = rules,
      moduleOnce = meshReplacementsTable.once,
    }
    SortedModuleIds[#SortedModuleIds + 1] = moduleId

    InfoLog('Loaded module %s: %d instance rule(s)', moduleIdentity.displayName, #rules)
  else
    ---@cast meshReplacementsTable SSSModuleStatic
    local staticModule = staticModuleLoader(meshReplacementsTable)

    local numReplacements = 0
    if meshReplacementsTable.replace_meshes then
      for _ in pairs(meshReplacementsTable.replace_meshes) do
        numReplacements = numReplacements + 1
      end
    end

    SortedStaticModuleIds[#SortedStaticModuleIds + 1] = moduleId
    StaticReplacements.ComposedReplacements[moduleId] = staticModule

    InfoLog('Loaded module %s: %d replacement(s)', moduleIdentity.displayName, numReplacements)
  end

  addModuleIdentity(moduleIdentity)
  ModulePriorities[moduleId] = priority
end

---@param instanceRule SSSInstanceRule
---@return string[] triggerNames
local function getRuleTriggerNames(instanceRule)
  local trigger = instanceRule.trigger

  if trigger == nil then return DEFAULT_TRIGGER_NAMES end
  if type(trigger) == 'string' then return { trigger } end

  return trigger
end

--- Collects what a rule's top-level conditions say for one condition name, flattening OR-lists.
---@param instanceRule SSSInstanceRule
---@param conditionName string
---@return (string|table)[] values
local function getRuleConditionValues(instanceRule, conditionName)
  local values = {}
  local conditions = instanceRule.conditions
  if not conditions then return values end

  for condIdx = 1, #conditions do
    local conditionValue = conditions[condIdx][conditionName]

    if type(conditionValue) == 'table' and conditionValue[1] ~= nil then
      for valueIdx = 1, #conditionValue do
        values[#values + 1] = conditionValue[valueIdx]
      end
    elseif conditionValue ~= nil then
      values[#values + 1] = conditionValue
    end
  end

  return values
end

---@param sweepKey string
---@param triggerRule SSSTriggerRule
local function addSweepRule(sweepKey, triggerRule)
  local sweep = Sweeps[sweepKey]

  if not sweep then
    sweep = { key = sweepKey, rules = {}, objectTypeNames = {} }
    Sweeps[sweepKey] = sweep
  end

  sweep.rules[#sweep.rules + 1] = triggerRule

  local ruleTypeNames = getRuleConditionValues(triggerRule.rule, 'object_type')
  if #ruleTypeNames == 0 then sweep.sweepsEveryType = true end

  for typeIdx = 1, #ruleTypeNames do
    sweep.objectTypeNames[ruleTypeNames[typeIdx]] = true
  end
end

---@param triggerRule SSSTriggerRule
local function addJournalSweepRules(triggerRule)
  local journalConditions = getRuleConditionValues(triggerRule.rule, 'has_journal')
  local addedQuestIds = {}

  for journalIdx = 1, #journalConditions do
    local questId = journalConditions[journalIdx].quest

    if type(questId) == 'string' and not addedQuestIds[questId] then
      addedQuestIds[questId] = true

      local sweepKey = JOURNAL_SWEEP_PREFIX .. questId
      JournalSweepKeys[questId] = sweepKey
      addSweepRule(sweepKey, triggerRule)
    end
  end
end

--- A sweep only enumerates the object types its rules name, unless any rule leaves the type open.
local function resolveSweepObjectTypes()
  for _, sweep in next, Sweeps do
    if not sweep.sweepsEveryType then
      local objectTypes = {}

      for typeName in next, sweep.objectTypeNames do
        objectTypes[#objectTypes + 1] = types[typeName]
      end

      sweep.objectTypes = objectTypes
    end
  end
end

--- Indexes every loaded rule under the triggers it listens to, in module evaluation order.
local function indexRulesByTrigger()
  for modIdx = 1, #SortedModuleIds do
    local moduleId = SortedModuleIds[modIdx]
    local moduleData = ObjectModificationStore[moduleId]

    for ruleIdx = 1, #moduleData.rules do
      local instanceRule = moduleData.rules[ruleIdx]

      ---@type SSSTriggerRule
      local triggerRule = {
        moduleName = moduleId,
        moduleOnce = moduleData.moduleOnce,
        rule = instanceRule,
      }

      local triggerNames = getRuleTriggerNames(instanceRule)

      for triggerIdx = 1, #triggerNames do
        local triggerName = triggerNames[triggerIdx]

        local triggerRules = RulesByTrigger[triggerName]
        if not triggerRules then
          triggerRules = {}
          RulesByTrigger[triggerName] = triggerRules
        end
        triggerRules[#triggerRules + 1] = triggerRule

        if triggerName == 'journal' then
          addJournalSweepRules(triggerRule)
        elseif TriggerContext.WORLD_TRIGGERS[triggerName] then
          addSweepRule(triggerName, triggerRule)
        end
      end
    end
  end

  resolveSweepObjectTypes()
end

---@param staticReplacements SSSStaticReplacements
---@return SSSModuleCatalog
return function(staticReplacements)
  StaticReplacements = assert(staticReplacements)

  local modulePaths, modulePathIndex = {}, 0

  for meshReplacementsPath in vfs.pathsWithPrefix 'scripts/staticSwitcher/data' do
    if StrMatch(meshReplacementsPath, '%.ya?ml$') then
      modulePathIndex = modulePathIndex + 1
      modulePaths[modulePathIndex] = staticUtil.normalizePath(meshReplacementsPath)
    end
  end

  sort(modulePaths)

  for pathIdx = 1, #modulePaths do
    local meshReplacementsPath = modulePaths[pathIdx]
    local wasLoaded, loadError =
      pcall(loadSwitcherModule, meshReplacementsPath, createModuleIdentity(meshReplacementsPath))

    if not wasLoaded then
      ErrorLog(StrFormat('Skipped module %s: %s', meshReplacementsPath, tostring(loadError)))
    end
  end

  local function moduleComesBefore(a, b)
    local orderA = PRIORITY_ORDER[ModulePriorities[a]]
    local orderB = PRIORITY_ORDER[ModulePriorities[b]]
    if orderA ~= orderB then return orderA < orderB end
    return a < b
  end

  table.sort(SortedModuleIds, moduleComesBefore)
  table.sort(SortedStaticModuleIds, moduleComesBefore)

  indexRulesByTrigger()

  ---@type SSSModuleCatalog
  return {
    legacyIdsByBasename = LegacyIdsByBasename,
    moduleLabels = ModuleLabels,
    moduleNames = ModuleIds,
    moduleIds = ModuleIds,
    modules = Modules,
    numModules = ModuleIdsLen,
    resolveModuleId = resolveModuleId,
    --- Indexed first by canonical module id, then an array of actions and conditions
    --- all values in said array will be strings, and, when each lookup is performed they can/should be cached
    --- based on the generated hash of each set of table values (itself, keyed by the id of the loaded module)
    ObjectModificationStore = ObjectModificationStore,
    JournalSweepKeys = JournalSweepKeys,
    RulesByTrigger = RulesByTrigger,
    Sweeps = Sweeps,
    SortedModuleIds = SortedModuleIds,
    SortedStaticModuleIds = SortedStaticModuleIds,
  }
end
