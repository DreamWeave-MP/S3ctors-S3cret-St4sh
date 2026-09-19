---@omw-context menu|player

local merge = require 'scripts.h3.ui.merge'

local Assert, Error, StrGmatch, Next, RawGet, StrFormat, ToString, Type =
  assert, error, string.gmatch, next, rawget, string.format, tostring, type

local Marker, PathCache, ReferenceCache = {}, {}, {}

---@param path string
---@return string
local function validatePath(path)
  Assert(Type(path) == 'string' and path ~= '', 'H3 UI token path must be a non-empty string')

  if path:sub(1, 1) == '.' or path:sub(-1) == '.' or path:find('..', 1, true) then
    Error(StrFormat('H3 UI token path contains an empty segment: %s', path))
  end

  return path
end

---@param path string
---@return H3UI.TokenReference
local function ref(path)
  validatePath(path)

  local cached = ReferenceCache[path]
  if cached then return cached end

  cached = {
    [Marker] = true,
    path = path,
  }

  ReferenceCache[path] = cached

  return cached
end

---@param value H3UI.LuaValue
---@return boolean
local function isRef(value) return Type(value) == 'table' and RawGet(value, Marker) == true end

---@param path string
---@return string[]
local function pathParts(path)
  validatePath(path)

  local cached = PathCache[path]
  if cached then return cached end

  cached = {}
  for part in StrGmatch(path, '[^%.]+') do
    cached[#cached + 1] = part
  end

  PathCache[path] = cached

  return cached
end

---@param root table
---@param path string
---@return H3UI.TokenResolvable?, boolean
local function getPath(root, path)
  local value = root
  local parts = pathParts(path)

  for index = 1, #parts do
    if Type(value) ~= 'table' then return nil, false end

    value = value[parts[index]]

    if value == nil then return nil, false end
  end

  return value, true
end

---@param rawTokens? table<string, H3UI.TokenDefinition>
---@return table<string, H3UI.TokenValue>
local function resolveTree(rawTokens)
  rawTokens = rawTokens or {}
  Assert(merge.isPlainTable(rawTokens), 'H3 UI theme tokens must be a plain table')

  local activePaths, activeTables, cache = {}, {}, {}
  local resolvePath, resolveValue

  ---@param value H3UI.TokenDefinition
  ---@param origin? string
  ---@return H3UI.TokenValue
  resolveValue = function(value, origin)
    if isRef(value) then
      ---@cast value H3UI.TokenReference
      return resolvePath(value.path)
    end
    if not merge.isPlainTable(value) then return value end

    if activeTables[value] then
      Error(StrFormat('H3 UI token table cycle while resolving %s', origin or '<tokens>'))
    end

    activeTables[value] = true

    local result = {}
    for key, item in Next, value do
      result[key] = resolveValue(item, origin)
    end

    activeTables[value] = nil

    return result
  end

  ---@param path string
  ---@return H3UI.TokenValue
  resolvePath = function(path)
    if cache[path] ~= nil then return merge.copy(cache[path]) end
    if activePaths[path] then Error(StrFormat('H3 UI token cycle at %s', path)) end

    local rawValue, found = getPath(rawTokens, path)
    if not found then Error(StrFormat('Unknown H3 UI token: %s', path)) end
    ---@cast rawValue H3UI.TokenDefinition

    activePaths[path] = true
    local result = resolveValue(rawValue, path)
    activePaths[path] = nil

    cache[path] = result

    return merge.copy(result)
  end

  local resolved = {}
  for key in Next, rawTokens do
    resolved[key] = resolvePath(ToString(key))
  end

  return resolved
end

---@param value H3UI.TokenValue|H3UI.TokenReference
---@param tokens table<string, H3UI.TokenValue>
---@param active? table<table, boolean>
---@return H3UI.TokenValue
local function resolveValue(value, tokens, active)
  if isRef(value) then
    ---@cast value H3UI.TokenReference
    local tokenValue, found = getPath(tokens, value.path)

    if not found then Error(StrFormat('Unknown H3 UI token: %s', value.path)) end
    ---@cast tokenValue H3UI.TokenValue

    return merge.copy(tokenValue)
  end

  if not merge.isPlainTable(value) then return value end

  active = active or {}
  if active[value] then Error 'H3 UI style table contains a cycle' end
  active[value] = true

  local result = {}
  for key, item in Next, value do
    result[key] = resolveValue(item, tokens, active)
  end

  active[value] = nil
  return result
end

---@param tokens table<string, H3UI.TokenValue>
---@param path string
---@return H3UI.TokenValue
local function lookup(tokens, path)
  local value, found = getPath(tokens, path)

  if not found then Error(StrFormat('Unknown H3 UI token: %s', path)) end
  ---@cast value H3UI.TokenValue

  return merge.copy(value)
end

---@param tokens table<string, H3UI.TokenValue>
---@param path string
---@return H3UI.TokenValue?, boolean
local function find(tokens, path)
  local value, found = getPath(tokens, path)

  if not found then return nil, false end
  ---@cast value H3UI.TokenValue

  return merge.copy(value), true
end

return {
  find = find,
  isRef = isRef,
  lookup = lookup,
  ref = ref,
  resolveTree = resolveTree,
  resolveValue = resolveValue,
}
