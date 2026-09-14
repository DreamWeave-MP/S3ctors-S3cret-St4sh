---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local allowed = {
  class = true,
  component = true,
  density = true,
  recipe = true,
  role = true,
  slot = true,
  state = true,
  tone = true,
  variant = true,
}

local traitFields = {
  'component',
  'recipe',
  'role',
  'variant',
  'tone',
  'density',
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

  if result.class ~= nil then
    assert(
      type(result.class) == 'string' and result.class ~= '',
      'H3 UI selector class must be a string'
    )
  end
  if result.slot ~= nil then
    assert(
      type(result.slot) == 'string' and result.slot ~= '',
      'H3 UI selector slot must be a string'
    )
  end

  return result
end

local function classes(input, single)
  local result = {}
  if single ~= nil then
    assert(type(single) == 'string' and single ~= '', 'H3 UI class must be a string')
    result[single] = true
  end

  if input ~= nil then
    if type(input) == 'string' then
      assert(input ~= '', 'H3 UI class must be a non-empty string')
      result[input] = true
    else
      assert(type(input) == 'table', 'H3 UI classes must be a string or array')
      for index = 1, #input do
        local value = input[index]
        assert(type(value) == 'string' and value ~= '', 'H3 UI classes must contain strings')
        result[value] = true
      end
    end
  end

  return result
end

local function matches(rule, node)
  if rule.class ~= nil and not node.classes[rule.class] then return false end

  for index = 1, #traitFields do
    local key = traitFields[index]
    local expected = rule[key]
    if expected ~= nil and node[key] ~= expected then return false end
  end

  return true
end

local function tier(rule)
  if rule.state ~= nil then return 5 end
  if rule.class ~= nil then return 4 end
  if rule.variant ~= nil or rule.tone ~= nil or rule.density ~= nil then return 3 end
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
