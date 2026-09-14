---@omw-context menu|player

local constants = require 'scripts.s3.ui.constants'

local MathFloor = math.floor
local Type = type

local function isPlainTable(value)
  return Type(value) == 'table' and getmetatable(value) == nil
end

local function isArray(value)
  if not isPlainTable(value) then return false end

  local count = 0
  local maximum = 0
  for key in next, value do
    if Type(key) ~= 'number' or key < 1 or key ~= MathFloor(key) then return false end
    count = count + 1
    if key > maximum then maximum = key end
  end

  return count > 0 and maximum == count
end

local function copy(value, seen)
  if constants.isUnset(value) then return value end
  if not isPlainTable(value) then return value end

  seen = seen or {}
  if seen[value] then return seen[value] end

  local result = {}
  seen[value] = result
  for key, item in next, value do
    result[key] = copy(item, seen)
  end
  return result
end


local function shallowCopy(value)
  if value == nil then return {} end
  assert(isPlainTable(value), 'H3 UI shallow copy source must be a plain table')
  local result = {}
  for key, item in next, value do result[key] = item end
  return result
end

local function mergeInto(target, source)
  if source == nil then return target end
  assert(isPlainTable(target), 'H3 UI merge target must be a plain table')
  assert(isPlainTable(source), 'H3 UI merge source must be a plain table')

  for key, value in next, source do
    if constants.isUnset(value) then
      target[key] = nil
    else
      local current = target[key]
      if isPlainTable(value) and not isArray(value)
          and isPlainTable(current) and not isArray(current) then
        mergeInto(current, value)
      else
        target[key] = copy(value)
      end
    end
  end

  return target
end

local function merged(base, overrides)
  local result = {}
  if base then mergeInto(result, base) end
  if overrides then mergeInto(result, overrides) end
  return result
end

return {
  copy = copy,
  isArray = isArray,
  isPlainTable = isPlainTable,
  mergeInto = mergeInto,
  merged = merged,
  shallowCopy = shallowCopy,
}
