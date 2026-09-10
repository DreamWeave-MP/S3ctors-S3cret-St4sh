local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_conditions_generated%.lua$' or '.'

package.path = root
  .. '/content/s3maphore/00 Core/?.lua;'
  .. root
  .. '/content/s3maphore/00 Core/?/init.lua;'
  .. package.path

local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local ConditionRegistry = PlaylistConditions.registry

local function loadCode(code, environment)
  local chunk, err = loadstring(code)
  assert(chunk, err)
  setfenv(chunk, environment)
  return chunk
end

local randomState = 1732050807
local function randomInteger(maximum)
  randomState = (randomState * 48271) % 2147483647
  return randomState % maximum + 1
end

local stateSpecifications, ruleSpecifications = {}, {}
for i = 1, #ConditionRegistry.ordered do
  local specification = ConditionRegistry.ordered[i]
  if specification.kind == 'state' then
    stateSpecifications[#stateSpecifications + 1] = specification
  else
    ruleSpecifications[#ruleSpecifications + 1] = specification
  end
end

local function randomString(prefix) return prefix .. tostring(randomInteger(100000)) end

local function randomValue(valueType)
  if valueType == 'boolean' then return randomInteger(2) == 1 end
  if valueType == 'number' then return randomInteger(200) / 10 end
  return randomString 'state-'
end

local function randomRuleArgument(kind)
  if kind == 'hour' then return randomInteger(25) - 1 end
  if kind == 'patterns' then
    return {
      allowed = { randomString 'allowed-' },
      disallowed = { randomString 'disallowed-' },
    }
  end
  return { randomString 'value-', randomString 'other-' }
end

local function makePlayback()
  local playback = { state = {}, rules = {} }
  for i = 1, #stateSpecifications do
    local specification = stateSpecifications[i]
    playback.state[specification.id] = randomValue(specification.valueType)
  end
  for i = 1, #ruleSpecifications do
    local specification = ruleSpecifications[i]
    playback.rules[specification.id] = function(...)
      local result = #specification.id + select('#', ...)
      for argumentIndex = 1, select('#', ...) do
        local argument = select(argumentIndex, ...)
        result = result + (type(argument) == 'table' and #argument or 1)
      end
      return result % 2 == 0
    end
  end
  return playback
end

local function randomStateNode(playback)
  local specification = stateSpecifications[randomInteger(#stateSpecifications)]
  local operator
  if specification.valueType == 'number' then
    local operators = { 'eq', 'ne', 'lt', 'le', 'gt', 'ge' }
    operator = operators[randomInteger(#operators)]
  else
    local operators = { 'eq', 'ne' }
    operator = operators[randomInteger(#operators)]
  end
  return {
    kind = 'state',
    id = specification.id,
    op = operator,
    value = randomValue(specification.valueType),
  }
end

local function randomRuleNode()
  local specification = ruleSpecifications[randomInteger(#ruleSpecifications)]
  local arguments = {}
  for argumentIndex = 1, #specification.arguments do
    arguments[argumentIndex] = randomRuleArgument(specification.arguments[argumentIndex])
  end
  return { kind = 'rule', id = specification.id, args = arguments }
end

local function randomLeaf(playback)
  if randomInteger(2) == 1 then return randomStateNode(playback) end
  return randomRuleNode()
end

local function randomNode(playback, depth)
  if depth >= 6 or randomInteger(100) <= 55 then return randomLeaf(playback) end
  if randomInteger(3) == 1 then return { kind = 'not', child = randomNode(playback, depth + 1) } end

  local children = {}
  for childIndex = 1, randomInteger(4) - 1 do
    children[childIndex] = randomNode(playback, depth + 1)
  end
  return { kind = randomInteger(2) == 1 and 'and' or 'or', children = children }
end

local function compareValues(left, right, operator)
  if operator == 'eq' then return left == right end
  if operator == 'ne' then return left ~= right end
  if left == nil then return false end
  if operator == 'lt' then return left < right end
  if operator == 'le' then return left <= right end
  if operator == 'gt' then return left > right end
  return left >= right
end

local function evaluateReference(node, playback)
  if node.kind == 'and' then
    for i = 1, #node.children do
      if not evaluateReference(node.children[i], playback) then return false end
    end
    return true
  end
  if node.kind == 'or' then
    for i = 1, #node.children do
      if evaluateReference(node.children[i], playback) then return true end
    end
    return false
  end
  if node.kind == 'not' then return not evaluateReference(node.child, playback) end
  if node.kind == 'state' then
    return compareValues(playback.state[node.id], node.value, node.op)
  end

  local specification = ConditionRegistry.rules[node.id]
  local arguments = {}
  for argumentIndex = 1, #specification.arguments do
    local kind = specification.arguments[argumentIndex]
    local argument = node.args[argumentIndex]
    if kind == 'nameSet' then
      local presence = {}
      for valueIndex = 1, #argument do
        presence[argument[valueIndex]] = true
      end
      argument = presence
    end
    arguments[argumentIndex] = argument
  end
  return not not playback.rules[node.id](unpack(arguments, 1, #arguments))
end

for caseIndex = 1, 1000 do
  local playback = makePlayback()
  local condition = PlaylistConditions.validate(randomNode(playback, 0))
  local compiled = PlaylistConditions.compile(condition, playback, loadCode)
  local expected = evaluateReference(condition, playback)
  assert(compiled() == expected, 'generated AST mismatch at case ' .. caseIndex)
end

print 'S3maphore generated playlist condition tests passed'
