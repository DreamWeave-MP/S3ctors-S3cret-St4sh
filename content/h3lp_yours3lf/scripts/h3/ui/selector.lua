---@omw-context menu|player

local merge = require 'scripts.h3.ui.merge'

local Assert, Error, Next, StrFormat, ToString, Type =
  assert, error, next, string.format, tostring, type

local Allowed = {
  class = true,
  component = true,
  recipe = true,
  role = true,
  selected = true,
  slot = true,
  state = true,
  tone = true,
  variant = true,
}

local StringFields = {
  'class',
  'component',
  'recipe',
  'role',
  'slot',
  'state',
  'tone',
  'variant',
}

local EmptyClasses = {}

local TraitFields = {
  'component',
  'recipe',
  'role',
  'selected',
  'variant',
  'tone',
  'state',
}

---@param input? H3UI.ThemeSelector
---@return H3UI.ThemeSelector
local function normalize(input)
  input = input or {}

  Assert(merge.isPlainTable(input), 'H3 UI selector must be a plain table')

  local result = {}
  for key, value in Next, input do
    if not Allowed[key] then Error(StrFormat('Unknown H3 UI selector field: %s', ToString(key))) end
    result[key] = value
  end

  for index = 1, #StringFields do
    local key = StringFields[index]
    local value = result[key]

    if value ~= nil then
      if Type(value) ~= 'string' or value == '' then
        Error(StrFormat('H3 UI selector %s must be a non-empty string', key))
      end
    end
  end

  if result.selected ~= nil then
    Assert(Type(result.selected) == 'boolean', 'H3 UI selector selected must be boolean')
  end

  if result.state ~= nil then
    Assert(
      result.state == 'hover' or result.state == 'pressed',
      'H3 UI selector state must be hover or pressed'
    )
  end

  return result
end

---@param input? string|string[]|table<string, boolean>
---@param single? string
---@return table<string, boolean>
local function classes(input, single)
  if not input and not single then return EmptyClasses end

  local result = {}

  if single ~= nil then
    Assert(Type(single) == 'string' and single ~= '', 'H3 UI class must be a non-empty string')
    result[single] = true
  end

  if input == nil then return result end
  if Type(input) == 'string' then
    Assert(input ~= '', 'H3 UI class must be a non-empty string')

    result[input] = true

    return result
  end

  Assert(merge.isPlainTable(input), 'H3 UI classes must be a string, array, or set')

  if merge.isArray(input) then
    for index = 1, #input do
      local value = input[index]

      Assert(Type(value) == 'string' and value ~= '', 'H3 UI classes must contain strings')

      result[value] = true
    end

    return result
  end

  for className, enabled in Next, input do
    Assert(
      Type(className) == 'string' and className ~= '',
      'H3 UI class set keys must be non-empty strings'
    )

    Assert(Type(enabled) == 'boolean', 'H3 UI class set values must be boolean')

    if enabled then result[className] = true end
  end

  return result
end

---@param rule H3UI.ThemeSelector
---@param componentRecord H3UI.ComponentRecord
---@param state? string
---@return boolean
local function matches(rule, componentRecord, state)
  if rule.class ~= nil and not componentRecord.classes[rule.class] then return false end

  for index = 1, #TraitFields do
    local key = TraitFields[index]
    local expected = rule[key]

    local actual = key == 'state' and state or componentRecord[key]

    if expected ~= nil and actual ~= expected then return false end
  end

  return true
end

---@param rule H3UI.ThemeSelector
---@return integer
local function tier(rule)
  if rule.state ~= nil then return 5 end
  if rule.class ~= nil then return 4 end
  if rule.variant ~= nil or rule.tone ~= nil or rule.selected ~= nil then return 3 end
  if rule.recipe ~= nil or rule.role ~= nil then return 2 end
  if rule.component ~= nil then return 1 end

  return 0
end

---@param rule H3UI.ThemeSelector
---@return integer
local function specificity(rule)
  local count = 0

  for key in Next, rule do
    if key ~= 'slot' then count = count + 1 end
  end

  return count
end

return {
  classes = classes,
  matches = matches,
  normalize = normalize,
  specificity = specificity,
  tier = tier,
}
