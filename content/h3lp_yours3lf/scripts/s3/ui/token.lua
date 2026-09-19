---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local marker = {}
local referenceCache = {}
local pathCache = {}
local StrFormat = string.format
local Type = type

local function validatePath(path)
  assert(Type(path) == 'string' and path ~= '', 'H3 UI token path must be a non-empty string')
  assert(
    path:sub(1, 1) ~= '.' and path:sub(-1) ~= '.' and not path:find('..', 1, true),
    'H3 UI token path contains an empty segment: ' .. path
  )
  return path
end

---@param path string
---@return H3UI.TokenReference
local function ref(path)
  validatePath(path)
  local cached = referenceCache[path]
  if cached then return cached end
  cached = {
    [marker] = true,
    path = path,
  }
  referenceCache[path] = cached
  return cached
end

local function isRef(value) return Type(value) == 'table' and rawget(value, marker) == true end

local function pathParts(path)
  validatePath(path)
  local cached = pathCache[path]
  if cached then return cached end
  cached = {}
  for part in string.gmatch(path, '[^%.]+') do
    cached[#cached + 1] = part
  end
  pathCache[path] = cached
  return cached
end

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

local function resolveTree(rawTokens)
  rawTokens = rawTokens or {}
  assert(merge.isPlainTable(rawTokens), 'H3 UI theme tokens must be a plain table')

  local cache = {}
  local activePaths = {}
  local activeTables = {}
  local resolvePath
  local resolveValue

  resolveValue = function(value, origin)
    if isRef(value) then return resolvePath(value.path) end
    if not merge.isPlainTable(value) then return value end

    if activeTables[value] then
      error(StrFormat('H3 UI token table cycle while resolving %s', origin or '<tokens>'))
    end

    activeTables[value] = true
    local result = {}
    for key, item in next, value do
      result[key] = resolveValue(item, origin)
    end
    activeTables[value] = nil
    return result
  end

  resolvePath = function(path)
    if cache[path] ~= nil then return merge.copy(cache[path]) end
    if activePaths[path] then error('H3 UI token cycle at ' .. path) end

    local rawValue, found = getPath(rawTokens, path)
    if not found then error('Unknown H3 UI token: ' .. path) end

    activePaths[path] = true
    local result = resolveValue(rawValue, path)
    activePaths[path] = nil
    cache[path] = result
    return merge.copy(result)
  end

  local resolved = {}
  for key in next, rawTokens do
    resolved[key] = resolvePath(tostring(key))
  end
  return resolved
end

local function resolveValue(value, tokens, active)
  if isRef(value) then
    local tokenValue, found = getPath(tokens, value.path)
    if not found then error('Unknown H3 UI token: ' .. value.path) end
    return merge.copy(tokenValue)
  end

  if not merge.isPlainTable(value) then return value end

  active = active or {}
  if active[value] then error 'H3 UI style table contains a cycle' end
  active[value] = true

  local result = {}
  for key, item in next, value do
    result[key] = resolveValue(item, tokens, active)
  end

  active[value] = nil
  return result
end

local function lookup(tokens, path)
  local value, found = getPath(tokens, path)
  if not found then error('Unknown H3 UI token: ' .. path) end
  return merge.copy(value)
end

return {
  isRef = isRef,
  lookup = lookup,
  ref = ref,
  resolveTree = resolveTree,
  resolveValue = resolveValue,
}
