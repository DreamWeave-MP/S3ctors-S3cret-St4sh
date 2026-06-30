---@omw-context global

local aux_util = require 'openmw_aux.util'
local markup = require 'openmw.markup'
local vfs = require 'openmw.vfs'

local szudzik = require 'scripts.s3.szudzik'
local tableHash = require 'scripts.s3.tableHash'

local staticUtil = require 'Scripts.staticSwitcher.util'
local validation = require 'Scripts.staticSwitcher.validation'
local logger = require 'Scripts.staticSwitcher.logger'

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

---@type SSSStaticReplacements
local StaticReplacements

---@type string[]
	local ACTIONPRIORITY = {
	'replace',
	'transform',
	'add',
	'remove',
	'equip',
	'unequip',
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
	--- Name matches should always be last as they're inevitably going to be the slowest
	'nameMatch',
	'carrying',
	--- Journal gates are relatively expensive (player/quest lookup); evaluated last
	'has_journal',
	'not',
}

local error, ipairs, NewTable, next, nkeys, pairs, sort =
		---@diagnostic disable-next-line: undefined-field
error,
	ipairs,
	table.new,
	next,
	table.nkeys,
	pairs,
	table.sort

---@param modulePath string
---@return string pathWithoutExtension
local function stripYamlExtension(modulePath)
	return modulePath:gsub('%.yaml$', ''):gsub('%.yml$', '')
end

---@param modulePath string
---@return string label
local function getModuleLabel(modulePath)
	return stripYamlExtension(modulePath):gsub('^' .. DATA_PREFIX, '')
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
	for index, conditionName in ipairs(CONDITIONPRIORITY) do
		if conditionData[conditionName] then
			return index
		end
	end
end

---@param actionData SSSInstanceAction
---@return integer?
local function sortActionByType(actionData)
	for index, actionName in ipairs(ACTIONPRIORITY) do
		if actionData[actionName] then
			return index
		end
	end
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
		for i, replaceString in ipairs(meshReplacementsTable.replace_names) do
			cellNameMatches[i] = replaceString:lower()
		end
	end

	if gridIndices then
		for _, cellGrid in ipairs(meshReplacementsTable.exterior_cells) do
			replacementTable.gridIndices[szudzik.getIndex(cellGrid.x, cellGrid.y)] = true
		end
	end

	if regionMatches then
		for _, regionName in ipairs(meshReplacementsTable.replace_regions) do
			regionMatches[regionName:lower()] = true
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

		for index, instance_action in ipairs(meshReplacementsTable.instances) do
			if instance_action.conditions then
				instance_action.conditions = aux_util.mapFilterSort(instance_action.conditions, sortConditionByType)
			end

			instance_action.actions = aux_util.mapFilterSort(instance_action.actions, sortActionByType)

			local actionHash = tableHash(instance_action)
			instance_action.actionHash = actionHash

			modStore[index] = instance_action
		end

		ObjectModificationStore[moduleIdentity.id] = modStore
	else
		---@cast meshReplacementsTable SSSModuleStatic
		StaticModuleIdsLen = StaticModuleIdsLen + 1
		StaticModuleIds[StaticModuleIdsLen] = moduleIdentity.id
		StaticReplacements.ComposedReplacements[moduleIdentity.id] = staticModuleLoader(meshReplacementsTable)
	end

	if meshReplacementsTable.instances then
		logger.info('Loaded module %s: %d instance rule(s)', moduleIdentity.displayName, #meshReplacementsTable.instances)
	else
		local numReplacements = 0
		if meshReplacementsTable.replace_meshes then
			for _ in pairs(meshReplacementsTable.replace_meshes) do
				numReplacements = numReplacements + 1
			end
		end
		logger.info('Loaded module %s: %d replacement(s)', moduleIdentity.displayName, numReplacements)
	end

	meshReplacementsFile:close()
end

---@param staticReplacements SSSStaticReplacements
---@return SSSModuleCatalog
return function(staticReplacements)
	StaticReplacements = assert(staticReplacements)

	local modulePaths, modulePathIndex = {}, 0

	for meshReplacementsPath in vfs.pathsWithPrefix 'scripts/staticSwitcher/data' do
		if meshReplacementsPath:match '%.ya?ml$' then
			modulePathIndex = modulePathIndex + 1
			modulePaths[modulePathIndex] = staticUtil.normalizePath(meshReplacementsPath)
		end
	end

	sort(modulePaths)

	for _, meshReplacementsPath in ipairs(modulePaths) do
		loadSwitcherModule(meshReplacementsPath, createModuleIdentity(meshReplacementsPath))
	end

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
	}
end
