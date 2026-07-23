---@omw-context none
---Deterministic OpenMW UI layout snapshot serializer.
---
---This plain Lua module does not import `openmw.ui` and does not create,
---update, destroy, or mutate UI elements. It is safe to require from any
---context, but the values it inspects may still be OpenMW-owned objects.
---
---All capture functions allocate fresh plain Lua tables and strings. They are
---intended for diagnostics, logs, tests, and bug reports; do not call them from
---per-frame UI hot paths or high-frequency event callbacks.
---
---Usage:
---```lua
---local uiSnapshot = require 'scripts.s3.uiSnapshot'
---local text = uiSnapshot.format(element)
---```

local concat, sort = table.concat, table.sort
local ipairs, pairs, pcall, tostring, type = ipairs, pairs, pcall, tostring, type

---@class S3.UiSnapshotOptions
---@field maxDepth? integer Maximum nested table/layout depth. Defaults to 8.
---@field maxChildren? integer Maximum numeric content children to capture. Defaults to 128.
---@field maxString? integer Maximum string length before truncation. Defaults to 160.
---@field includeFunctions? boolean Include stable function placeholders. Defaults to false.
---@field includeEvents? boolean Include `events` tables and callback placeholders. Defaults to false.
---@field includeUserData? boolean Include `userData` values. Defaults to false.
---@field vectorMode? 'fields'|'placeholder' How vector/color userdata are represented. Defaults to 'fields'.
---@field sortKeys? boolean Sort non-content keys for deterministic output. Defaults to true.

---@class S3.UiSnapshotInvalidElement
---@field __snapshot string Always `'invalidElement'`.
---@field reason string Human-readable failure marker.

---@class S3.UiSnapshotModule
---@field fromLayout fun(layout: any, opts?: S3.UiSnapshotOptions): table Captures a layout/value as a fresh plain table.
---@field fromElement fun(element: any, opts?: S3.UiSnapshotOptions): table Captures `element.layout` with pcall; destroyed/invalid elements return a marker table.
---@field capture fun(value: any, opts?: S3.UiSnapshotOptions): table Captures an element when `value.layout` is safely readable and table-like, otherwise captures the value/layout directly.
---@field lines fun(value: any, opts?: S3.UiSnapshotOptions): string[] Formats a captured snapshot as deterministic text lines.
---@field format fun(value: any, opts?: S3.UiSnapshotOptions): string Formats a captured snapshot as one newline-separated string.

local M = {}

local snapshotContent
local snapshotValue
local appendLines

local KNOWN_LAYOUT_KEYS = {
    'type',
    'name',
    'layer',
    'template',
    'props',
    'external',
    'content',
    'events',
    'userData',
}

local KNOWN_KEY_SET = {}
for _, key in ipairs(KNOWN_LAYOUT_KEYS) do KNOWN_KEY_SET[key] = true end

local DEFAULTS = {
    maxDepth = 8,
    maxChildren = 128,
    maxString = 160,
    includeFunctions = false,
    includeEvents = false,
    includeUserData = false,
    vectorMode = 'fields',
    sortKeys = true,
}

local OMIT = {}

---@param opts S3.UiSnapshotOptions?
---@return S3.UiSnapshotOptions
local function normalizeOptions(opts)
    local out = {}
    opts = opts or {}
    for k, v in pairs(DEFAULTS) do
        local override = opts[k]
        out[k] = override == nil and v or override
    end
    return out
end

---@param value any
---@param key any
---@return boolean ok
---@return any result
local function safeGet(value, key)
    return pcall(function() return value[key] end)
end

---@param value any
---@return boolean ok
---@return integer len
local function safeLen(value)
    return pcall(function() return #value end)
end

---@param value any
---@param maxString integer
---@return string
local function truncateString(value, maxString)
    if #value <= maxString then return value end
    local remaining = #value - maxString
    return value:sub(1, maxString) .. '…(' .. remaining .. ' more)'
end

---@param value any
---@return boolean
local function isScalar(value)
    local valueType = type(value)
    return value == nil
        or valueType == 'string'
        or valueType == 'number'
        or valueType == 'boolean'
end

---@param key any
---@return boolean
local function isSerializableKey(key)
    local keyType = type(key)
    return keyType == 'string' or keyType == 'number' or keyType == 'boolean'
end

---@param value any
---@return table?
local function functionPlaceholder(value)
    if type(value) ~= 'function' then return nil end
    return { __type = 'function' }
end

---@param events any
---@param opts S3.UiSnapshotOptions
---@param depth integer
---@param seen table<table, boolean>
---@param active table<table, boolean>
---@return table
local function snapshotEvents(events, opts, depth, seen, active)
    local eventOpts = {}
    for k, v in pairs(opts) do eventOpts[k] = v end
    eventOpts.includeFunctions = true
    return snapshotValue(events, eventOpts, depth, seen, active)
end

---@param value any
---@return boolean
---@return table?
local function tryVectorOrColor(value, opts)
    if type(value) ~= 'table' and type(value) ~= 'userdata' then return false, nil end
    if opts.vectorMode == 'placeholder' then
        local okX, x = safeGet(value, 'x')
        local okR, r = safeGet(value, 'r')
        if (okX and type(x) == 'number') or (okR and type(r) == 'number') then
            return true, { __type = 'vectorOrColor' }
        end
        return false, nil
    end

    local okX, x = safeGet(value, 'x')
    local okY, y = safeGet(value, 'y')
    if okX and okY and type(x) == 'number' and type(y) == 'number' then
        local out = { __type = 'vector', x = x, y = y }
        local okZ, z = safeGet(value, 'z')
        local okW, w = safeGet(value, 'w')
        if okZ and type(z) == 'number' then out.z = z end
        if okW and type(w) == 'number' then out.w = w end
        return true, out
    end

    local okR, r = safeGet(value, 'r')
    local okG, g = safeGet(value, 'g')
    local okB, b = safeGet(value, 'b')
    if okR and okG and okB and type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
        local out = { __type = 'color', r = r, g = g, b = b }
        local okA, a = safeGet(value, 'a')
        if okA and type(a) == 'number' then out.a = a end
        return true, out
    end

    return false, nil
end

---@param value any
---@param opts S3.UiSnapshotOptions
---@param depth integer
---@param seen table<table, boolean>
---@param active table<table, boolean>
---@return any
function snapshotValue(value, opts, depth, seen, active)
    local valueType = type(value)
    if valueType == 'string' then return truncateString(value, opts.maxString) end
    if valueType == 'number' or valueType == 'boolean' or value == nil then return value end
    if valueType == 'function' then
        return opts.includeFunctions and functionPlaceholder(value) or OMIT
    end

    local isVector, vector = tryVectorOrColor(value, opts)
    if isVector then return vector end

    if valueType ~= 'table' then
        return { __type = valueType }
    end

    if depth >= opts.maxDepth then return { __truncated = 'maxDepth' } end
    if active[value] then return { __cycle = true } end
    if seen[value] then return { __ref = true } end

    seen[value] = true
    active[value] = true

    local out = {}

    for _, key in ipairs(KNOWN_LAYOUT_KEYS) do
        if not (key == 'events' and not opts.includeEvents)
            and not (key == 'userData' and not opts.includeUserData) then
            local ok, child = safeGet(value, key)
            if ok and child ~= nil then
                if key == 'content' then
                    out[key] = snapshotContent(child, opts, depth + 1, seen, active)
                elseif key == 'events' then
                    out[key] = snapshotEvents(child, opts, depth + 1, seen, active)
                else
                    local snapped = snapshotValue(child, opts, depth + 1, seen, active)
                    if snapped ~= OMIT then out[key] = snapped end
                end
            end
        end
    end

    local otherKeys = {}
    local okPairs, iter, tableValue = pcall(pairs, value)
    if okPairs then
        for key in iter, tableValue do
            if not KNOWN_KEY_SET[key] and isSerializableKey(key) then
                otherKeys[#otherKeys + 1] = key
            end
        end
    end
    if opts.sortKeys then
        sort(otherKeys, function(a, b) return tostring(a) < tostring(b) end)
    end
    for _, key in ipairs(otherKeys) do
        local ok, child = safeGet(value, key)
        if ok and isScalar(child) then
            local snapped = snapshotValue(child, opts, depth + 1, seen, active)
            if snapped ~= OMIT then out[key] = snapped end
        elseif ok and opts.includeFunctions and type(child) == 'function' then
            out[key] = functionPlaceholder(child)
        end
    end

    active[value] = nil
    return out
end

---@param content any
---@param opts S3.UiSnapshotOptions
---@param depth integer
---@param seen table<table, boolean>
---@param active table<table, boolean>
---@return table
function snapshotContent(content, opts, depth, seen, active)
    local out = {}
    local okLen, len = safeLen(content)
    if not okLen then
        out.__invalidContent = true
        return out
    end

    local limit = len
    if limit > opts.maxChildren then limit = opts.maxChildren end
    for i = 1, limit do
        local ok, child = safeGet(content, i)
        if ok then
            local snapped = snapshotValue(child, opts, depth, seen, active)
            if snapped ~= OMIT then out[#out + 1] = snapped end
        else
            out[#out + 1] = { __invalidChild = i }
        end
    end
    if len > limit then out.__truncatedChildren = len - limit end
    return out
end

---@param layout any UI layout table or arbitrary value to serialize.
---@param opts S3.UiSnapshotOptions?
---@return table snapshot Fresh deterministic plain Lua snapshot. Inputs are never mutated.
function M.fromLayout(layout, opts)
    opts = normalizeOptions(opts)
    local snapped = snapshotValue(layout, opts, 0, {}, {})
    if snapped == OMIT then return { __omitted = true } end
    if type(snapped) == 'table' then return snapped end
    return { value = snapped }
end

---@param element any OpenMW UI element-like value.
---@param opts S3.UiSnapshotOptions?
---@return table snapshot Layout snapshot or invalid-element marker. Never throws for destroyed/invalid `element.layout` reads.
function M.fromElement(element, opts)
    local ok, layout = pcall(function() return element.layout end)
    if not ok then
        return { __snapshot = 'invalidElement', reason = 'layout read failed' }
    end
    if type(layout) ~= 'table' then
        return { __snapshot = 'invalidElement', reason = 'layout is not a table' }
    end
    return M.fromLayout(layout, opts)
end

---@param value any Element-like value or layout/value to serialize.
---@param opts S3.UiSnapshotOptions?
---@return table snapshot Fresh deterministic plain Lua snapshot.
function M.capture(value, opts)
    local valueType = type(value)
    if valueType == 'table' or valueType == 'userdata' then
        local ok, layout = pcall(function() return value.layout end)
        if ok and type(layout) == 'table' then
            return M.fromLayout(layout, opts)
        end
    end
    return M.fromLayout(value, opts)
end

---@param key any
---@return string
local function formatKey(key)
    if type(key) == 'string' and key:match('^[_%a][_%w]*$') then return key end
    return '[' .. tostring(key) .. ']'
end

---@param value any
---@param indent string
---@return string
local function inlineOrBlock(value, indent)
    if type(value) ~= 'table' then return tostring(value) end
    local out = {}
    appendLines(out, value, indent)
    return '\n' .. concat(out, '\n')
end

---@param out string[]
---@param value any
---@param indent string
function appendLines(out, value, indent)
    local valueType = type(value)
    if valueType ~= 'table' then
        out[#out + 1] = indent .. tostring(value)
        return
    end

    out[#out + 1] = indent .. '{'
    local nextIndent = indent .. '  '
    local used = {}
    for i = 1, #value do
        used[i] = true
        out[#out + 1] = nextIndent .. '[' .. i .. '] = ' .. inlineOrBlock(value[i], nextIndent)
    end

    local keys = {}
    for key in pairs(value) do
        if not used[key] and isSerializableKey(key) then keys[#keys + 1] = key end
    end
    sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        local child = value[key]
        out[#out + 1] = nextIndent .. formatKey(key) .. ' = ' .. inlineOrBlock(child, nextIndent)
    end
    out[#out + 1] = indent .. '}'
end

---@param value any Element-like value or layout/value to serialize.
---@param opts S3.UiSnapshotOptions?
---@return string[] lines Deterministic text lines. Allocates a fresh array.
function M.lines(value, opts)
    local out = {}
    appendLines(out, M.capture(value, opts), '')
    return out
end

---@param value any Element-like value or layout/value to serialize.
---@param opts S3.UiSnapshotOptions?
---@return string text Deterministic newline-separated text. Allocates a snapshot, line array, and string.
function M.format(value, opts)
    return concat(M.lines(value, opts), '\n')
end

return M
