local aux_util     = require 'openmw_aux.util'
local vfs          = require 'openmw.vfs'

local strings      = require 'scripts.staticSwitcher.staticStrings'
local staticUtil   = {}
staticUtil.strings = strings

---@param modelPath string
---@param originalModel string
---@param recordId string
---@param moduleName string
---@param logString string
---@return boolean? whether the mesh exists or not
function staticUtil.assertMeshExists(modelPath, originalModel, recordId, moduleName, logString)
    if vfs.fileExists(modelPath) then return true end

    staticUtil.Log(
        strings.MISSING_MESH_ERROR:format(modelPath, originalModel, recordId, moduleName),
        logString
    )
end

---@param inputTarget table? Table into which values will be copied
---@param source table? Table values will copy from
---@return table target
function staticUtil.deepCopy(inputTarget, source)
    local target = inputTarget or {}

    if source and type(source) ~= 'table' then error('Source table was not even a table, it was: ' .. source) end

    for k, v in pairs(source or {}) do
        if type(v) == 'table' then
            local newSubTable = {}
            target[k] = newSubTable
            staticUtil.deepCopy(newSubTable, v)
        else
            target[k] = v
        end
    end

    return target
end

---@param object any
function staticUtil.deepLog(object)
    print(
        staticUtil.LogString(
            aux_util.deepToString(object, 5)
        )
    )
end

---@param path string Path to check for the `meshes/` prefix
---@return string original path, but with `meshes/` prepended
function staticUtil.getMeshPath(path)
    path = path:gsub("^[/\\]+", "")

    if not path:match("^meshes/") then
        path = "meshes/" .. path
    end

    return path
end

---@param object GameObject
---@param replacementModules table<string, SSSModule>
---@return string? moduleName, string? replacementMesh the specific module name and model path which should be used to replace a particular gameObject
function staticUtil.getObjectReplacement(object, replacementModules)
    for moduleName, moduleData in pairs(replacementModules) do
        local replacementMesh = staticUtil.getReplacementMeshForObject(moduleData.meshMap, object)
        if replacementMesh then return moduleName, replacementMesh end
    end
end

---@param path string normalized VFS path referring to a mesh replacement map
function staticUtil.getPathBaseName(path)
    ---@type string
    local baseName
    for part in string.gmatch(path, "([^/]+)") do
        baseName = part
    end

    for split in baseName:gmatch('([^.]+)') do
        return split
    end
end

--- Given a particular gameObject, check whether this module can rightfully replace it.
--- The function must be created on a per-module basis in order to refer to the current local value of `replacementTable`
---@param object GameObject
---@return string? replacementObjectMesh
function staticUtil.getReplacementMeshForObject(meshMap, object)
    --- Special handling for marker types which are statics but have no .type field on them
    if not object.type then return end

    local objectModel = staticUtil.Record(object).model
    if not objectModel then return end

    local replacementObjectMesh = meshMap[objectModel]

    if replacementObjectMesh then return replacementObjectMesh end
end

--- Actual log writing function, given whatever message
---@param message string
---@param prefix string?
function staticUtil.Log(message, prefix)
    print(
        staticUtil.LogString(message, prefix)
    )
end

--- Helper function to generate a log message string, but without printing it for reusability.
---@param message string
---@param prefix string?
function staticUtil.LogString(message, prefix)
    if not prefix then prefix = strings.LOG_PREFIX end

    return strings.LOG_FORMAT_STR:format(
        strings.PREFIX_FRAME:format(prefix),
        message
    )
end

---Function to normalize path separators in a string
---@param path string
---@return string normalized path
function staticUtil.normalizePath(path)
    local normalized, _ = path:gsub("\\", "/"):gsub("([^:])//+", "%1/")
    return normalized:lower()
end

---@param object GameObject
---@return ActivatorRecord Object record data
function staticUtil.Record(object)
    return object.type.records[object.recordId]
end

---@type ContentFileBits
local ContentFileBits = 16777216

--- Fetches the object index of a given gameObject, including generated objects
---@param object GameObject
---@return boolean isGenerated, number refNum
function staticUtil.getRefNum(object)
    local objectId = tonumber(object.id)

    if objectId then
        return false, util.bitXor(objectId, ContentFileBits)
    else
        local generatedRef = tonumber(
            object.id:sub(2, #object.id)
        )

        assert(generatedRef)

        return true, generatedRef
    end
end

---@param t table
local function is_table_array(t)
    if type(t) ~= "table" then return false end

    local max_index = 0
    local count = 0

    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            return false
        end

        max_index = math.max(max_index, k)
        count = count + 1
    end

    return max_index == count
end

--- Deep merges tables with special array handling
-- @param target The table to merge into
-- @param source The table to merge from
-- @param is_array If true, treats tables as arrays (appends instead of overwrites)
function staticUtil.mergeTables(target, source, is_array)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end

    if is_array or is_table_array(source) then
        for _, value in ipairs(source) do
            table.insert(target, value)
        end
    else
        for key, value in pairs(source) do
            if type(value) == "table" and type(target[key]) == "table" then
                staticUtil.mergeTables(target[key], value, is_table_array(value))
            else
                target[key] = value
            end
        end
    end

    return target
end

return staticUtil
