---@omw-context global | menu

local aux_util = require 'openmw_aux.util'
local vfs = require 'openmw.vfs'

---@type ContentFileBits
local ContentFileBits = 16777216

local LOG_PREFIX, LOG_FORMAT_STR, MISSING_MESH_ERROR, PREFIX_FRAME, TITLE_CAP_FORMAT_STR =
	'StaticSwitchingSystem',
	'%s %s',
	[[Requested model %s to replace %s on object %s, but the mesh was not found. The module: %s was not properly installed!]],
	'[ %s ]:',
	'%s%s'

local GOBJECT_TYPE = 'MWLua::GObject'

local assert, error, pairs, print, tonumber, type = assert, error, pairs, print, tonumber, type
local StrFind, StrFormat, StrGsub, StrGmatch, StrLower, StrMatch, StrUpper, StrSub =
	string.find, string.format, string.gsub, string.gmatch, string.lower, string.match, string.upper, string.sub

local Insert, IsArray, Max, Floor =
		---@diagnostic disable-next-line: undefined-field
table.insert,
	table.isarray,
	math.max,
	math.floor

local Log, LogString, normalizePath, getReplacementMeshForObject

---@param modelPath string
---@param originalModel string
---@param recordId string
---@param moduleName string
---@param logString string
---@return boolean? whether the mesh exists or not
local function assertMeshExists(modelPath, originalModel, recordId, moduleName, logString)
	if vfs.fileExists(modelPath) then
		return true
	end

	Log(StrFormat(MISSING_MESH_ERROR, modelPath, originalModel, recordId, moduleName), logString)
end

---@param inputTarget table? Table into which values will be copied
---@param source table? Table values will copy from
---@return table target
local function deepCopy(inputTarget, source)
	local target = inputTarget or {}

	if source and type(source) ~= 'table' then
		error('Source table was not even a table, it was: ' .. source)
	end

	for k, v in pairs(source or {}) do
		if type(v) == 'table' then
			local newSubTable = {}
			target[k] = newSubTable
			deepCopy(newSubTable, v)
		else
			target[k] = v
		end
	end

	return target
end

---@param object any
local function deepLog(object)
	print(LogString(aux_util.deepToString(object, 5)))
end

---@param path string Path to check for the `meshes/` prefix
---@return string original path, but with `meshes/` prepended
local function getMeshPath(path)
	path = StrGsub(normalizePath(path), '^/+', '')

	if not StrMatch(path, '^meshes/') then
		path = 'meshes/' .. path
	end

	return path
end

---@param value any
---@return boolean
local function isGObject(value)
	return type(value) == 'userdata' and value.__type and value.__type.name == GOBJECT_TYPE
end

---@param object openmw.GObject
---@param replacementModules table<string, SSSModule>
---@return string? moduleName, string? replacementMesh the specific module name and model path which should be used to replace a particular gameObject
local function getObjectReplacement(object, replacementModules)
	for moduleName, moduleData in pairs(replacementModules) do
		local replacementMesh = getReplacementMeshForObject(moduleData.meshMap, object)
		if replacementMesh then
			return moduleName, replacementMesh
		end
	end
end

---@param path string normalized VFS path referring to a mesh replacement map
local function getPathBaseName(path)
	local baseName = ''

	for part in StrGmatch(path, '([^/]+)') do
		baseName = part
	end

	for split in StrGmatch(baseName, '([^.]+)') do
		return split
	end
end

--- Given a particular gameObject, check whether this module can rightfully replace it.
--- The function must be created on a per-module basis in order to refer to the current local value of `replacementTable`
---@param meshMap ReplacementMap
---@param object openmw.GObject
---@return string? replacementObjectMesh
function getReplacementMeshForObject(meshMap, object)
	--- Special handling for marker types which are statics but have no .type field on them
	if not object.type then
		return
	end

	local objectModel = object.type.records[object.recordId].model
	if not objectModel then
		return
	end

	local replacementObjectMesh = meshMap[objectModel]

	if replacementObjectMesh then
		return replacementObjectMesh
	end
end

--- Actual log writing function, given whatever message
---@param message string
---@param prefix string?
function Log(message, prefix)
	print(LogString(message, prefix))
end

--- Helper function to generate a log message string, but without printing it for reusability.
---@param message string
---@param prefix string?
---@return string logMessage
function LogString(message, prefix)
	if not prefix then
		prefix = LOG_PREFIX
	end

	return StrFormat(LOG_FORMAT_STR, StrFormat(PREFIX_FRAME, prefix), message)
end

---Function to normalize path separators in a string
---@param path string
---@return string normalized path
function normalizePath(path)
	local normalized, _ = StrGsub(StrGsub(path, '\\', '/'), '([^:])//+', '%1/')
	return StrLower(normalized)
end

---@param object openmw.GObject
---@return openmw.types.ActivatorRecord|openmw.types.StaticRecord Object record data
local function Record(object)
	return object.type.records[object.recordId]
end

--- Fetches the object index of a given gameObject, including generated objects
---@param object openmw.GObject
---@return boolean isGenerated, number refNum
local function getRefNum(object)
	local idString = object.id
	local objectId = tonumber(idString)

	if objectId then
		return false, objectId % ContentFileBits
	else
		local generatedRef = tonumber(StrSub(idString, 2, #idString))

		assert(generatedRef)

		return true, generatedRef
	end
end

---@param t table
---@return boolean isArray
local function is_table_array(t)
	if type(t) ~= 'table' then
		return false
	end

	local max_index = 0
	local count = 0

	for k, _ in pairs(t) do
		if type(k) ~= 'number' or k < 1 or Floor(k) ~= k then
			return false
		end

		max_index = Max(max_index, k)
		count = count + 1
	end

	return max_index == count
end

--- Deep merges tables with special array handling
---@param target table The table to merge into
---@param source table The table to merge from
---@param is_array boolean? If true, treats tables as arrays (appends instead of overwrites)
---@return table target The merged target table
local function mergeTables(target, source, is_array)
	if type(target) ~= 'table' or type(source) ~= 'table' then
		return target
	end

	if is_array or (IsArray and IsArray(source)) or is_table_array(source) then
		for srcIdx = 1, #source do
			Insert(target, source[srcIdx])
		end
	else
		for key, value in pairs(source) do
			if type(value) == 'table' and type(target[key]) == 'table' then
				mergeTables(target[key], value, is_table_array(value))
			else
				target[key] = value
			end
		end
	end

	return target
end

--- Takes a string as input and performs Title capitalization on it.
--- Note that other characters are lowercased explicitly.
---@param inputString string The string whose first letter should be capitalized
---@return string capitalizedString The original string, with Title capitalization
local function capitalize(inputString)
	local stringLength = #inputString
	if stringLength <= 1 then
		return StrUpper(inputString)
	end

	return StrFormat(TITLE_CAP_FORMAT_STR, StrUpper(StrSub(inputString, 1, 1)), StrSub(inputString, 2, stringLength))
end

---@class StaticUtil
return {
	assertMeshExists = assertMeshExists,
	deepCopy = deepCopy,
	deepLog = deepLog,
	getMeshPath = getMeshPath,
	isGObject = isGObject,
	getObjectReplacement = getObjectReplacement,
	getPathBaseName = getPathBaseName,
	getReplacementMeshForObject = getReplacementMeshForObject,
	Log = Log,
	LogString = LogString,
	normalizePath = normalizePath,
	Record = Record,
	getRefNum = getRefNum,
	mergeTables = mergeTables,
	capitalize = capitalize,
}
