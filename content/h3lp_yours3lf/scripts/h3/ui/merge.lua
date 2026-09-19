---@omw-context menu|player

local constants = require 'scripts.h3.ui.constants'

local Assert, GetMetatable, MathFloor, Next, Type = assert, getmetatable, math.floor, next, type

---@param value H3UI.LuaValue
---@return boolean
local function isPlainTable(value) return Type(value) == 'table' and not GetMetatable(value) end

---@param value H3UI.LuaValue
---@return boolean
local function isArray(value)
  if not isPlainTable(value) then return false end

  local count, maximum = 0, 0

  for key in Next, value do
    if Type(key) ~= 'number' or key < 1 or key ~= MathFloor(key) then return false end
    count = count + 1
    if key > maximum then maximum = key end
  end

  return count > 0 and maximum == count
end

---@generic T
---@param value T
---@param seen? table<table, table>
---@return T
local function copy(value, seen)
  if constants.isUnset(value) then return value end
  if not isPlainTable(value) then return value end

  seen = seen or {}
  if seen[value] then return seen[value] end

  local result = {}
  seen[value] = result

  for key, item in Next, value do
    result[key] = copy(item, seen)
  end

  return result
end

---@generic T: table
---@param value? T
---@return T
local function shallowCopy(value)
  if not value then return {} end

  Assert(isPlainTable(value), 'H3 UI shallow copy source must be a plain table')

  local result = {}
  for key, item in Next, value do
    result[key] = item
  end

  return result
end

---@param target table
---@param source? table
---@return table
local function mergeInto(target, source)
  if not source then return target end

  Assert(isPlainTable(target), 'H3 UI merge target must be a plain table')
  Assert(isPlainTable(source), 'H3 UI merge source must be a plain table')

  for key, value in Next, source do
    if constants.isUnset(value) then
      target[key] = nil
    else
      local current = target[key]

      if
        isPlainTable(value)
        and not isArray(value)
        and isPlainTable(current)
        and not isArray(current)
      then
        mergeInto(current, value)
      else
        target[key] = copy(value)
      end
    end
  end

  return target
end

---@param base? table
---@param overrides? table
---@return table
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
