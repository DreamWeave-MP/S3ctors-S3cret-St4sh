---@omw-context global

local aux_util = require 'openmw_aux.util'
local markup = require 'openmw.markup'
local vfs = require 'openmw.vfs'

local szudzik = require 'scripts.s3.szudzik'
local tableHash = require 'scripts.s3.tableHash'

local staticUtil = require 'Scripts.staticSwitcher.util'
local validation = require 'Scripts.staticSwitcher.validation'

local InfoLog
do
	local logger = require 'Scripts.staticSwitcher.logger'
	InfoLog = logger.info
end

local type = type
local StrLower, StrGsub, StrMatch = string.lower, string.gsub, string.match

local DATA_PREFIX = 'scripts/staticswitcher/data/'

---@type string[], integer
local ModuleIds, ModuleIdsLen = {}, 0

---@type string[], integer
local StaticModuleIds, StaticModuleIdsLen = {}, 0

---@type table<string, SSSModuleIdentity>
local Modules = {}

---@type table<string, string>
local ModuleLabels = {}

---@type table<string, string[]>
local LegacyIdsByBasename = {}

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

---@type SSSStaticReplacements
local StaticReplacements

---@type string[]
local ACTIONPRIORITY = {
	'replace',
	'transform',
	'set_ownership',
	'add',
	'remove',
	'equip',
	'unequip',
	'lock_level',
	'key',
	'trap',
	'create',
	'playsound',
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
	'content_file_target',
	--- Object property checks
	'generated',
	'mesh',
	'scale',
	'has_name',
	'has_lua_script',
	'has_mwscript',
	'locked',
	'has_key',
	'has_trap',
	--- Name matches should always be last as they're inevitably going to be the slowest
	'nameMatch',
	'carrying',
	--- Journal gates are relatively expensive (player/quest lookup); evaluated last
	'has_journal',
	'player_level',
	'target_level',
	'player_attribute',
	'player_skill',
	'target_attribute',
	'target_skill',
	'player_health',
	'player_magicka',
	'player_fatigue',
	'target_health',
	'target_magicka',
	'target_fatigue',
	'time_of_day',
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
	if Modules[moduleKey] then
		return moduleKey
	end

	local legacyIds = LegacyIdsByBasename[moduleKey]
	if legacyIds and #legacyIds == 1 then
		return legacyIds[1]
	end
end

---@param conditionData SSSConditionData
---@return integer?
local function sortConditionByType(conditionData)
	for condPrioIndex = 1, #CONDITIONPRIORITY do
		local conditionName = CONDITIONPRIORITY[condPrioIndex]
		if conditionData[conditionName] then
			return condPrioIndex
		end
	end
end

---@param actionData SSSInstanceAction
---@return integer?
local function sortActionByType(actionData)
	for actPrioIndex = 1, #ACTIONPRIORITY do
		local actionName = ACTIONPRIORITY[actPrioIndex]
		if actionData[actionName] then
			return actPrioIndex
		end
	end
end

local LOWERED_CONDITION_KEYS = {
	cell_match = true,
	content_file = true,
	content_file_target = 'keys',
	record_id = true,
	faction_owner_id = true,
	owner_id = true,
	target_class = true,
	current_weather = true,
	region = true,
	worldspace = true,
	has_key = true,
	has_trap = true,
	has_mwscript = true,
}

--- Pre-lowercase string condition values at module load time so handlers
--- don't pay :lower() on user-provided strings in the hot path.
---@param conditionName string
---@param conditionValue any
---@return any
local function sanitizeConditionValue(conditionName, conditionValue)
	local keyPolicy = LOWERED_CONDITION_KEYS[conditionName]
	if not keyPolicy then
		return conditionValue
	end

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

	local valueType = type(conditionValue)

	if valueType == 'string' then
		return StrLower(conditionValue)
	end

	if valueType == 'table' then
		for i = 1, #conditionValue do
			conditionValue[i] = StrLower(conditionValue[i])
		end
	end

	return conditionValue
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
	if meshReplacementsTable.replace_regions and next(meshReplacementsTable.replace_regions) ~= nil then
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

	if meshMap then
		replacementTable.meshMap = meshMap
	end
	if cellNameMatches then
		replacementTable.cellNameMatches = cellNameMatches
	end
	if gridIndices then
		replacementTable.gridIndices = gridIndices
	end
	if regionMatches then
		replacementTable.regionMatches = regionMatches
	end
	if ignoreRecords then
		replacementTable.ignoreRecords = ignoreRecords
	end
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

---@param meshReplacementsPath string
---@param moduleIdentity SSSModuleIdentity
local function loadSwitcherModule(meshReplacementsPath, moduleIdentity)
	local meshReplacementsFile = vfs.open(meshReplacementsPath)
	local meshReplacementsText = meshReplacementsFile:read '*all'

	if not meshReplacementsText then
		error('Failed to read' .. meshReplacementsFile .. '!')
	end

	addModuleIdentity(moduleIdentity)

	---@type SSSModuleRaw
	local meshReplacementsTable = markup.decodeYaml(meshReplacementsText)

	validation.validate(meshReplacementsPath, meshReplacementsTable)

	---@cast meshReplacementsTable SSSModuleInstances
	if meshReplacementsTable.instances then
		local modStore = {}

		for ruleIdx = 1, #meshReplacementsTable.instances do
			local instance_action = meshReplacementsTable.instances[ruleIdx]
			if instance_action.conditions then
				for condIdx = 1, #instance_action.conditions do
					local conditionData = instance_action.conditions[condIdx]
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

				instance_action.conditions = aux_util.mapFilterSort(instance_action.conditions, sortConditionByType)
			end

			instance_action.actions = aux_util.mapFilterSort(instance_action.actions, sortActionByType)

			for actSanIdx = 1, #instance_action.actions do
				local actionData = instance_action.actions[actSanIdx]

				if actionData.key then
					for i = 1, #actionData.key do
						local k, v = next(actionData.key[i])
						assert(k ~= nil and v ~= nil)

						actionData.key[i][StrLower(k)] = v
						actionData.key[i][k] = nil
					end
				end

				if actionData.trap then
					for i = 1, #actionData.trap do
						local k, v = next(actionData.trap[i])
						assert(k ~= nil and v ~= nil)

						actionData.trap[i][StrLower(k)] = v
						actionData.trap[i][k] = nil
					end
				end
			end

			local actionHash = tableHash(instance_action)
			instance_action.actionHash = actionHash

			modStore[ruleIdx] = instance_action
		end

		ObjectModificationStore[moduleIdentity.id] = {
			rules = modStore,
			moduleOnce = meshReplacementsTable.once,
			priority = meshReplacementsTable.priority or 'standard',
		}

		SortedModuleIds[#SortedModuleIds + 1] = moduleIdentity.id
	else
		---@cast meshReplacementsTable SSSModuleStatic
		StaticModuleIdsLen = StaticModuleIdsLen + 1
		StaticModuleIds[StaticModuleIdsLen] = moduleIdentity.id
		StaticReplacements.ComposedReplacements[moduleIdentity.id] = staticModuleLoader(meshReplacementsTable)
	end

	if meshReplacementsTable.instances then
		InfoLog('Loaded module %s: %d instance rule(s)', moduleIdentity.displayName, #meshReplacementsTable.instances)
	else
		local numReplacements = 0
		if meshReplacementsTable.replace_meshes then
			for _ in pairs(meshReplacementsTable.replace_meshes) do
				numReplacements = numReplacements + 1
			end
		end
		InfoLog('Loaded module %s: %d replacement(s)', moduleIdentity.displayName, numReplacements)
	end

	meshReplacementsFile:close()
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
		loadSwitcherModule(meshReplacementsPath, createModuleIdentity(meshReplacementsPath))
	end

	table.sort(SortedModuleIds, function(a, b)
		local pa = ObjectModificationStore[a].priority
		local pb = ObjectModificationStore[b].priority
		local orderA = PRIORITY_ORDER[pa] or PRIORITY_ORDER.standard
		local orderB = PRIORITY_ORDER[pb] or PRIORITY_ORDER.standard
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a < b
	end)

	---@type SSSModuleCatalog
	return {
		legacyIdsByBasename = LegacyIdsByBasename,
		moduleLabels = ModuleLabels,
		moduleNames = ModuleIds,
		moduleIds = ModuleIds,
		modules = Modules,
		numModules = ModuleIdsLen,
		staticModuleIds = StaticModuleIds,
		resolveModuleId = resolveModuleId,
		--- Indexed first by canonical module id, then an array of actions and conditions
		--- all values in said array will be strings, and, when each lookup is performed they can/should be cached
		--- based on the generated hash of each set of table values (itself, keyed by the id of the loaded module)
		ObjectModificationStore = ObjectModificationStore,
		SortedModuleIds = SortedModuleIds,
	}
end
