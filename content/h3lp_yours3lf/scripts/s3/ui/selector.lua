---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local allowed = {
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

local stringFields = {
  'class',
  'component',
  'recipe',
  'role',
  'slot',
  'state',
  'tone',
  'variant',
}

local emptyClasses = {}

local traitFields = {
  'component',
  'recipe',
  'role',
  'selected',
  'variant',
  'tone',
  'state',
}

local function normalize(input)
  input = input or {}
  assert(merge.isPlainTable(input), 'H3 UI selector must be a plain table')

  local result = {}
  for key, value in next, input do
    assert(allowed[key], 'Unknown H3 UI selector field: ' .. tostring(key))
    if value ~= nil then result[key] = value end
  end

  for index = 1, #stringFields do
    local key = stringFields[index]
    local value = result[key]
    if value ~= nil then
      assert(
        type(value) == 'string' and value ~= '',
        'H3 UI selector ' .. key .. ' must be a non-empty string'
      )
    end
  end
  if result.selected ~= nil then
    assert(type(result.selected) == 'boolean', 'H3 UI selector selected must be boolean')
  end
  if result.state ~= nil then
    assert(
      result.state == 'hover' or result.state == 'pressed',
      'H3 UI selector state must be hover or pressed'
    )
  end

  return result
end

local function classes(input, single)
  if input == nil and single == nil then return emptyClasses end
  local result = {}
  if single ~= nil then
    assert(type(single) == 'string' and single ~= '', 'H3 UI class must be a non-empty string')
    result[single] = true
  end

  if input == nil then return result end
  if type(input) == 'string' then
    assert(input ~= '', 'H3 UI class must be a non-empty string')
    result[input] = true
    return result
  end

  assert(merge.isPlainTable(input), 'H3 UI classes must be a string, array, or set')
  if merge.isArray(input) then
    for index = 1, #input do
      local value = input[index]
      assert(type(value) == 'string' and value ~= '', 'H3 UI classes must contain strings')
      result[value] = true
    end
    return result
  end

  for className, enabled in next, input do
    assert(
      type(className) == 'string' and className ~= '',
      'H3 UI class set keys must be non-empty strings'
    )
    assert(type(enabled) == 'boolean', 'H3 UI class set values must be boolean')
    if enabled then result[className] = true end
  end
  return result
end

local function matches(rule, componentRecord, state)
  if rule.class ~= nil and not componentRecord.classes[rule.class] then return false end

  for index = 1, #traitFields do
    local key = traitFields[index]
    local expected = rule[key]
    local actual = key == 'state' and state or componentRecord[key]
    if expected ~= nil and actual ~= expected then return false end
  end

  return true
end

local function tier(rule)
  if rule.state ~= nil then return 5 end
  if rule.class ~= nil then return 4 end
  if rule.variant ~= nil or rule.tone ~= nil or rule.selected ~= nil then return 3 end
  if rule.recipe ~= nil or rule.role ~= nil then return 2 end
  if rule.component ~= nil then return 1 end
  return 0
end

local function specificity(rule)
  local count = 0
  for key, value in next, rule do
    if key ~= 'slot' and value ~= nil then count = count + 1 end
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
