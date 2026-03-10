local FCompDefault = function(a, b) return a < b end

local async, storage

local error, floor, getmetatable, gmatch, ipairs, next,
pairs, pcall, print, random, rawget, rawset, rep, setmetatable, tostring, type
= error, math.floor, getmetatable, string.gmatch, ipairs, next,
    pairs, pcall, print, math.random, rawget, rawset, string.rep, setmetatable, tostring, type


local concat, insert, maxn, move, pack, remove,
sort, unpack
= table.concat, table.insert, table.maxn, table.move, table.pack, table.remove,
    table.sort, table.unpack


local coYield, coWrap = coroutine.yield, coroutine.wrap

local isOpenMW = pcall(require, 'openmw.core')

if isOpenMW then
  async = require 'openmw.async'
  storage = require 'openmw.storage'
else
  ---@param data table
  ---@param handler function
  ---@return UpdatingSettingTable
  function TableSubscribe(data, handler)
    local shadow = {}

    for k, v in pairs(data) do
      shadow[k] = v
      data[k] = nil
    end

    local mt = {
      __index = shadow,
      __newindex = function(_, k, v)
        rawset(shadow, k, v)
        handler(k, v)
      end
    }

    return setmetatable(data, mt)
  end
end

local ReadOnlyMT = {
  __newindex = function(inTable, key, _)
    error(
      ('Write attempt to key %s in read-only table %s'):format(key, inTable),
      2
    )
  end,
  __metatable = false,
}

local StrictReadOnlyMT = {
  __index = function(inTable, key)
    error(
      ('Failed to locate key %s in table %s!'):format(key, inTable),
      2
    )
  end,
  __newindex = function(inTable, key, _)
    error(
      ('Write attempt to key %s read-only table %s'):format(key, inTable),
      2
    )
  end,
  __metatable = false,
}


---@class PairsIterable
---@field __pairs fun(t: self): fun(): any, any


---@class IpairsIterable
---@field __ipairs fun(t: self): fun(): any, any


---@alias SortFunc fun(a: any, b: any): boolean


--- Copy the value of a variable in a deep way, useful for copying a table's top level values
--- and direct children to another table safely, also handling metatables
---
--- Based on http://lua-users.org/wiki/CopyTable
---@param root table
---@param copies table?
---@return table cloned
local function deepCopy(root, copies)
  if type(root) ~= 'table' then
    error('Invalid table provided to deepCopy: ' .. tostring(root), 2)
  end

  copies = copies or {}
  if copies[root] then return copies[root] end

  local new = {}
  copies[root] = new

  for k, v in pairs(root) do
    local key = type(k) == 'table' and deepCopy(k, copies) or k
    local val = type(v) == 'table' and deepCopy(v, copies) or v
    new[key] = val
  end

  return setmetatable(new, getmetatable(root))
end

local function safePairs(val)
  return pcall(pairs, val)
end

local function safeIpairs(val)
  return pcall(ipairs, val)
end

--- Recursively converts a value to a human-readable string, traversing tables and iterables.
--- Uses pcall to safely handle userdata and non-iterable values.
---@param val any
---@param level? integer Maximum recursion depth. Defaults to 1.
---@param prefix? string Current indentation prefix. Leave nil on initial call.
---@return string result
local function deepToString(val, level, prefix)
  prefix = prefix or ''
  level = level or 1

  local ok, iter, t = safePairs(val)
  if level <= 0 or not ok then
    return tostring(val)
  end

  local newPrefix = prefix .. '  '
  local strs = { tostring(val) .. ' {\n' }

  for k, v in iter, t do
    strs[#strs + 1] = newPrefix .. tostring(k) .. ' = ' .. deepToString(v, level - 1, newPrefix) .. ',\n'
  end

  strs[#strs + 1] = prefix .. '}'
  return concat(strs)
end

--- Provides the number of elements in any table
---@param inputTable table
---@return number count of elements in the table
local function tableSize(inputTable)
  local count = 0
  for _ in pairs(inputTable) do count = count + 1 end
  return count
end


---@param inputTable table
---@return boolean isArray
local function isArray(inputTable)
  return next(inputTable) ~= nil and tableSize(inputTable) == #inputTable
end


--- Iterate through values matching a pattern in a string and turn them into table values
---@param inputString string
---@param pattern string
---@return string[] matchingParts
local function getTableFromSplit(inputString, pattern)
  local newTable = {}

  for value in gmatch(inputString, pattern) do
    insert(newTable, value)
  end

  return newTable
end


--- Iterate through comma-separated values in a string and turn them into table values
---@param inputString string
---@return string[] matchingParts
local function getTableFromCommaSplit(inputString)
  return getTableFromSplit(inputString, '%s*([^,]+)')
end


--- Get a string with a table's contents where every value is on its own row
---
--- Based on http://stackoverflow.com/a/13398936
---@param inputTable table
---@param maxDepth integer?
---@param indentStr string?
---@param indentLevel integer?
---@return string result
local function getPrintableTable(inputTable, maxDepth, indentStr, indentLevel)
  local inputType = type(inputTable)
  if inputType ~= 'table' and inputType ~= 'userdata' then
    return inputType
  end

  indentLevel = indentLevel or 0
  indentStr = indentStr or '\t'
  maxDepth = maxDepth or 50

  local parts = {}
  local currentIndent = rep(indentStr, indentLevel + 1)

  for index, value in pairs(inputTable) do
    local valueStr

    if type(value) == 'table' and maxDepth > 0 then
      valueStr = '\n' .. getPrintableTable(value, maxDepth - 1, indentStr, indentLevel + 1)
    else
      valueStr = tostring(value) .. '\n'
    end

    parts[#parts + 1] = currentIndent .. tostring(index) .. ': ' .. valueStr
  end

  return concat(parts, '')
end


---@param inputTable table
---@param maxDepth integer?
---@param indentStr string?
---@param indentLevel integer?
local function tablePrint(inputTable, maxDepth, indentStr, indentLevel)
  print(
    getPrintableTable(inputTable, maxDepth, indentStr, indentLevel)
  )
end


--- @param t table
--- @param deepCheck? boolean
--- @return boolean result
local function isEmpty(t, deepCheck)
  if deepCheck then
    for _, v in pairs(t) do
      if type(v) ~= 'table' or not isEmpty(v, true) then return false end
    end
  else
    for _ in pairs(t) do return false end
  end

  return true
end


--- @generic keyType
--- @generic valueType
--- @param t { [keyType]: valueType }
--- @return valueType? value
--- @return keyType? key
local function choice(t)
  -- We can abort on empty tables.
  local size = tableSize(t)
  if size == 0 then return end

  -- Call next a random amount of times up to the size of the table to get a random key.
  local key = nil
  local nextCount = random(size)
  for _ = 1, nextCount do
    key = next(t, key)
  end

  return t[key], key
end


--- @generic keyType
--- @generic valueType
--- @param t { [keyType]: valueType }
--- @param value valueType
--- @return keyType|unknown|nil key
local function find(t, value)
  for i, v in pairs(t) do
    if v == value then
      return i
    end
  end
end


--- @param t table
--- @param value unknown
--- @return boolean result
local function contains(t, value)
  return find(t, value) ~= nil
end


--- @param left table
--- @param right table
--- @return boolean result
local function isEqual(left, right)
  -- Try a quick basic equality check.
  if (left == right) then
    return true
  end

  -- Make sure both inputs are tables.
  if type(left) ~= 'table' or type(right) ~= 'table' then
    return false
  end

  -- Loop through pairs and see if all values match from t1 -> t2.
  local size1 = 0

  for k, v1 in pairs(left) do
    -- Note: If `v1 ~= v2`, then the recursive call to `table.equal` will
    -- result in a redundant comparison of `v1` and `v2`.
    -- But, testing shows that for highly similar tables, this approach is faster
    -- than only checking `not table.equal(v1, v2)`.
    -- This is likely due to the overhead from function calls.

    local v2 = right[k]
    if (v1 ~= v2 and not isEqual(v1, v2)) then
      return false
    end

    size1 = size1 + 1
  end

  -- We can assume t1 == t2 if all values match for t1 -> t2 and both tables have the same size.
  return size1 == tableSize(right)
end


--- @generic valueType
--- @param list { [unknown]: valueType }
--- @param value valueType
--- @return boolean result
local function removeValue(list, value)
  local i = find(list, value)

  if i ~= nil then
    remove(list, i)
    return true
  end

  return false
end


--- @generic fromType : table
--- @generic toType : table
--- @param from fromType
--- @param to? toType
--- @return fromType|toType result
local function shallowCopy(from, to)
  to = to or {}

  for k, v in pairs(from) do
    to[k] = v
  end

  return to
end


--- @param to table
--- @param from table
local function copyMissing(to, from)
  for k, v in pairs(from) do
    if type(to[k]) == "table" and type(v) == "table" then
      copyMissing(to[k], v)
    else
      if to[k] == nil then
        to[k] = v
      end
    end
  end
end


--- Traverses a tree structure depth-first, yielding each node.
--- NOTE: Uses coroutines internally — avoid in hot paths.
---
--- @param t table
--- @param k? string  The key used to find children. Defaults to "children".
--- @return fun(): table|any iterator
local function traverse(t, k)
  k = k or "children"

  local function iter(nodes)
    for _, node in ipairs(nodes or t) do
      if node then
        coYield(node)

        if node[k] then
          iter(node[k])
        end
      end
    end
  end

  return coWrap(iter)
end


--- @param t table
--- @param sortOrSortFunc? boolean|SortFunc
--- @return any[] keys
local function keys(t, sortOrSortFunc)
  local tableKeys = {}

  for k, _ in pairs(t) do
    insert(tableKeys, k)
  end

  if sortOrSortFunc then
    if sortOrSortFunc == true then
      sortOrSortFunc = nil
    end

    sort(tableKeys, sortOrSortFunc)
  end

  return tableKeys
end


--- @param t table
--- @param sortOrSortFunc? boolean|SortFunc
--- @return any[] values
local function values(t, sortOrSortFunc)
  local tableValues = {}

  for _, v in pairs(t) do
    insert(tableValues, v)
  end

  if sortOrSortFunc then
    ---@type SortFunc
    local sortFunction

    if type(sortOrSortFunc) == 'function' then
      sortFunction = sortOrSortFunc
    end

    sort(tableValues, sortFunction)
  end

  return tableValues
end

--- @generic keyType
--- @generic valueType
--- @param t { [keyType]: valueType }
--- @return { [valueType]: keyType } result
local function invert(t)
  local inverted = {}

  for k, v in pairs(t) do
    inverted[v] = k
  end

  return inverted
end

--- @generic keyType
--- @generic valueType
--- @param t { [keyType]: valueType }
--- @param key keyType
--- @param value any
--- @return valueType|unknown|nil oldValue
local function swap(t, key, value)
  local old = t[key]
  t[key] = value
  return old
end

--- @generic keyType
--- @generic valueType
--- @generic defaultValueType
--- @param t { [keyType]: valueType }
--- @param key keyType
--- @param defaultValue defaultValueType
--- @return valueType|defaultValueType|unknown result
local function get(t, key, defaultValue)
  local value = t[key]

  if value == nil then
    return defaultValue
  end

  return value
end

--- @generic keyType
--- @generic valueType
--- @generic defaultValueType
--- @param t { [keyType]: valueType }
--- @param key keyType
--- @param defaultValue defaultValueType
--- @return valueType|defaultValueType|unknown result
local function getOrSet(t, key, defaultValue)
  local value = t[key]

  if value ~= nil then
    return value
  end

  t[key] = defaultValue
  return defaultValue
end

--- @param t table
--- @param index number
--- @return number index
local function wrapIndex(t, index)
  local size = tableSize(t)

  local newIndex = index % size
  if newIndex == 0 then
    newIndex = size
  end

  return newIndex
end

--- @param t table
--- @param n? integer
local function shuffle(t, n)
  n = n or #t
  for i = n, 2, -1 do
    local j = random(i)
    t[i], t[j] = t[j], t[i]
  end
end

---
--- table.binsearch( table, value [, comp [, findAll] ] )
---
--- finds a value by performing a binary search.
--- If the `value` is found:
---	if `findAll` evaluates to true, then the lowest matching index and the highest matching index will be returned.
---	otherwise, the first index to match will be returned.
--- If `comp` is given:
---	comparisons will be performed as though the array was sorted via `table.sort(tbl, comp)`.
--- If `findAll == true`:
---	two indices will be returned, corresponding to the lowest and highest indices whose corresponding elements are equal to `value`.
--- Return value:
---	on success: two integers: `lowestMatch, highestMatch`
---	on failure: nil
--- @generic valueType
--- @param tbl valueType[]
--- @param value valueType
--- @param comp? fun(a: valueType, b: valueType): boolean
--- @param findAll? boolean
--- @return integer? index
--- @return integer? highestMatch
local function binSearch(tbl, value, comp, findAll)
  local first, last, midpt = 1, #tbl, 0
  comp = comp or FCompDefault

  while first <= last do
    -- calculate middle
    midpt = floor((first + last) / 2)

    if comp(value, tbl[midpt]) then     -- `value < tbl[midpt]`
      last = midpt - 1                  -- value is in the first half
    elseif comp(tbl[midpt], value) then -- `tbl[midpt] < value`
      first = midpt + 1                 -- value is in the second half
    else                                -- `tbl[midpt] == value`
      -- only want the first match? bail
      if not findAll then return midpt, midpt end

      -- find all the remaining matches
      local lowestMatch, highestMatch = midpt, midpt
      while value == tbl[lowestMatch - 1] do
        lowestMatch = lowestMatch - 1
      end
      while value == tbl[highestMatch + 1] do
        highestMatch = highestMatch + 1
      end
      return lowestMatch, highestMatch
    end
  end
end


---	table.bininsert( table, value [, comp] )
---
--- Inserts a given value through BinaryInsert into the table sorted by [comp].
---
--- If [comp] is given, then it must be a function that receives
--- two table elements, and returns true when the first is less
--- than the second, e.g. [comp = function(a, b) return a > b end],
--- will give a sorted table, with the biggest value on position 1.
--- [comp] behaves as in table.sort(table, value, [comp])
--- returns the index where 'value' was inserted
--- @generic valueType
--- @param t valueType[]
--- @param value valueType
--- @param comp? fun(a: valueType, b: valueType): boolean
--- @return number result
local function binInsert(t, value, comp)
  comp = comp or FCompDefault
  local iStart, iEnd, iMid, iState = 1, #t, 1, 0
  while iStart <= iEnd do
    -- calculate middle
    iMid = floor((iStart + iEnd) / 2)
    if comp(value, t[iMid]) then
      iEnd, iState = iMid - 1, 0
    else
      iStart, iState = iMid + 1, 1
    end
  end

  insert(t, (iMid + iState), value)
  return (iMid + iState)
end


--- @generic keyType
--- @generic valueType
--- @generic newValueType
--- @param t { [keyType]: valueType }
--- @param f fun(k: keyType, v: valueType, ...): newValueType
--- @param ... any
--- @return { [keyType]: newValueType } result
local function map(t, f, ...)
  local tbl = {}

  for k, v in pairs(t) do
    tbl[k] = f(k, v, ...)
  end

  return tbl
end

--- @generic keyType
--- @generic valueType
--- @param t { [keyType]: valueType }
--- @param f fun(k: keyType, v: valueType, ...): boolean
--- @param ... any
--- @return { [keyType]: valueType } result
local function filter(t, f, ...)
  local tbl = {}

  for k, v in pairs(t) do
    if f(k, v, ...) then
      tbl[k] = v
    end
  end

  return tbl
end

--- @generic valueType
--- @param arr valueType[]
--- @param f fun(i: integer, v: valueType, ...): boolean
--- @param ... any
--- @return valueType[] result
local function filterArray(arr, f, ...)
  local tbl = {}

  for i, v in ipairs(arr) do
    if f(i, v, ...) then
      insert(tbl, v)
    end
  end

  return tbl
end

--- Unpacks all values from a userdata implementing __pairs into a tuple
---@param object PairsIterable
---@return any ...
local function unwind(object)
  local ok, iter, t = safePairs(object)
  if not ok then
    error(tostring(object) .. ' cannot be iterated safely!', 2)
  end

  local results = {}

  for _, v in iter, t do
    results[#results + 1] = v
  end

  return unpack(results)
end

--- Unpacks all values from a userdata implementing __ipairs into a tuple
---@param object IpairsIterable
---@return any ...
local function unwindArray(object)
  local ok, iter, t = safeIpairs(object)
  if not ok then
    error(tostring(object) .. ' cannot be iterated safely!', 2)
  end

  local results = {}

  for _, v in iter, t do
    results[#results + 1] = v
  end

  return unpack(results)
end

--- Engine-agnostic subscription function to create observable tables which update
--- themselves automatically based on MCM values
---@param groupName string
---@param mcmPath string?
---@param originalTable table?
---@return UpdatingSettingTable
local function observableTable(groupName, mcmPath, originalTable)
  local settingTable = originalTable or {}

  local settingGroup
  if isOpenMW then
    settingGroup = storage.playerSection(groupName)
  else
    settingGroup = require(assert(mcmPath)).get(groupName)
  end

  local updateSettings
  if isOpenMW then
    updateSettings = function(_, updated)
      if updated then
        settingTable[updated] = settingGroup:get(updated)
      else
        for key, value in pairs(settingGroup:asTable()) do
          rawset(settingTable, key, value)
        end
      end
    end
  else
    updateSettings = function(_, updated)
      if updated then
        settingTable[updated] = rawget(settingGroup, updated)
      else
        for key, value in pairs(settingGroup) do
          rawset(settingTable, key, value)
        end
      end
    end
  end

  updateSettings()

  local newIndexFunction
  local shadowTable = {}
  if isOpenMW then
    settingGroup:subscribe(async:callback(updateSettings))

    newIndexFunction = function(_, k, v)
      if rawget(settingGroup:asTable(), k) ~= nil then
        settingGroup:set(k, v)
      else
        rawset(shadowTable, k, v)
      end
    end
  else
    --- FIXME: MWSE Version is fucked
    TableSubscribe(settingGroup, updateSettings)

    newIndexFunction = function(_, k, v)
      if settingGroup[k] ~= nil then
        settingGroup[k] = v
      else
        rawset(shadowTable, k, v)
      end
    end
  end

  return setmetatable({},
    {
      __index = function(_, k)
        local value = rawget(settingTable, k)
        if value ~= nil then return value end

        value = rawget(shadowTable, k)
        if value ~= nil then return value end
      end,
      __newindex = newIndexFunction,
    }
  )
end


--- Takes a table as input and returns a read-only one.
--- Commits seppuku if the input is not a table, so do be careful
---@param inTable table
---@param copy boolean? Whether to copy the table or make the original read-only
---@param strict boolean? Whether to make the table throw when indexing keys that don't exist
---@param visited table<table, table>?
---@return ReadOnlyTable
local function makeReadOnly(inTable, copy, strict, visited)
  if type(inTable) ~= "table" then
    error(("makeReadOnly: expected table, got %s"):format(type(inTable)), 2)
  end
  visited = visited or {}

  -- Return already processed result if seen
  if visited[inTable] then return visited[inTable] end

  local res
  if copy then
    res = {}
    visited[inTable] = res
    for k, v in pairs(inTable) do
      local newk = (type(k) == "table") and makeReadOnly(k, copy, strict, visited) or k
      local newv = (type(v) == "table") and makeReadOnly(v, copy, strict, visited) or v
      res[newk] = newv
    end
  else
    res = inTable
    visited[inTable] = res
    -- Process all values
    for _, v in pairs(inTable) do
      if type(v) == "table" then
        makeReadOnly(v, copy, strict, visited) -- modifies in place
      end
    end

    -- Process all table keys (must be done after values to avoid iteration issues)
    local tableKeys = {}
    for k in pairs(inTable) do
      if type(k) == "table" then
        tableKeys[#tableKeys + 1] = k
      end
    end

    for _, tk in ipairs(tableKeys) do
      makeReadOnly(tk, copy, strict, visited)
    end
  end

  local MT = strict and StrictReadOnlyMT or ReadOnlyMT
  return setmetatable(res, MT)
end

return {
  binInsert = binInsert,
  binSearch = binSearch,
  choice = choice,
  concat = concat,
  contains = contains,
  copyMissing = copyMissing,
  deepCopy = deepCopy,
  deepToString = deepToString,
  filter = filter,
  filterArray = filterArray,
  find = find,
  get = get,
  getOrSet = getOrSet,
  getPrintableTable = getPrintableTable,
  getTableFromCommaSplit = getTableFromCommaSplit,
  getTableFromSplit = getTableFromSplit,
  invert = invert,
  insert = insert,
  isArray = isArray,
  isEmpty = isEmpty,
  isEqual = isEqual,
  keys = keys,
  makeReadOnly = makeReadOnly,
  map = map,
  maxn = maxn,
  move = move,
  observableTable = observableTable,
  pack = pack,
  print = tablePrint,
  remove = remove,
  removeValue = removeValue,
  shallowCopy = shallowCopy,
  shuffle = shuffle,
  sort = sort,
  swap = swap,
  traverse = traverse,
  unpack = unpack,
  unwind = unwind,
  unwindArray = unwindArray,
  values = values,
  wrapIndex = wrapIndex,
}
