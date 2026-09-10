local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_conditions%.lua$' or '.'
package.path = root
  .. '/content/s3maphore/00 Core/?.lua;'
  .. root
  .. '/content/s3maphore/00 Core/?/init.lua;'
  .. package.path

local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local ConditionRegistry = PlaylistConditions.registry

local function assertError(fn, text)
  local ok, err = pcall(fn)
  assert(not ok, 'expected failure')
  if text then assert(tostring(err):find(text, 1, true), tostring(err)) end
end

local function loadCode(code, environment)
  local chunk, err = loadstring(code)
  assert(chunk, err)
  setfenv(chunk, environment)
  return chunk
end

local function hasOnlyPlainTables(value, seen)
  if type(value) ~= 'table' then return true end
  seen = seen or {}
  assert(not seen[value], 'serialized AST contains a shared table reference')
  seen[value] = true
  assert(getmetatable(value) == nil, 'serialized AST leaked a metatable')
  for key, child in pairs(value) do
    assert(type(key) == 'string' or type(key) == 'number', 'serialized AST key is not primitive')
    hasOnlyPlainTables(child, seen)
  end
  return true
end

local exteriorCondition = PlaylistConditions.state('cellIsExterior', 'eq', true)
local combatCondition = PlaylistConditions.state('isInCombat', 'eq', true)
local tree = PlaylistConditions.all {
  exteriorCondition,
  PlaylistConditions.any { combatCondition, PlaylistConditions.not_(exteriorCondition) },
}
local loaded = PlaylistConditions.deserialize(PlaylistConditions.serialize(tree))
assert(tree == loaded)
assert(tree ~= PlaylistConditions.any { exteriorCondition, combatCondition })
assert(
  PlaylistConditions.all { exteriorCondition, combatCondition }
    ~= PlaylistConditions.all { combatCondition, exteriorCondition }
)
assert(PlaylistConditions.clone(tree) == tree)
assert(
  PlaylistConditions.compile(PlaylistConditions.all {}, { state = {}, rules = {} }, loadCode)()
    == true
)
assert(
  PlaylistConditions.compile(PlaylistConditions.any {}, { state = {}, rules = {} }, loadCode)()
    == false
)
hasOnlyPlainTables(PlaylistConditions.serialize(tree))

local escapedValue = table.concat {
  'quote " slash \\ comma, newline',
  string.char(10),
  'tab',
  string.char(9),
  'nul',
  string.char(0),
  'controls',
  string.char(1, 31),
}
local escapedLiteral = PlaylistConditions.literal(escapedValue)
local escapedChunk = assert(loadstring('return ' .. escapedLiteral))
assert(escapedChunk() == escapedValue, 'literal escaping did not round-trip')
local escapedNames
local escapedPlayback = {
  state = {},
  rules = {
    cellNameExact = function(names)
      escapedNames = names
      return true
    end,
  },
}
assert(
  PlaylistConditions.compile(
    PlaylistConditions.rule('cellNameExact', { escapedValue }),
    escapedPlayback,
    loadCode
  )() == true
)
assert(escapedNames[escapedValue] == true, 'escaped name was not passed through compilation')

assertError(function() PlaylistConditions.validate { kind = 'wat' } end, 'unknown kind')
assertError(function() PlaylistConditions.validate { kind = 'not' } end, 'child')
assertError(
  function() PlaylistConditions.validate { kind = 'not', child = exteriorCondition, extra = true } end,
  'unexpected field'
)
assertError(
  function()
    PlaylistConditions.validate { kind = 'state', id = 'cellIsExterior', op = 'lt', value = true }
  end,
  'unsupported'
)
assertError(
  function() PlaylistConditions.validate { kind = 'state', id = 'missing', op = 'eq', value = true } end,
  'unknown state'
)
assertError(
  function()
    PlaylistConditions.validate { kind = 'state', id = 'objectCount', op = 'eq', value = true }
  end,
  'expected number'
)
assertError(
  function() PlaylistConditions.validate { kind = 'rule', id = 'timeOfDay', args = { 25, 1 } } end,
  'hour'
)
assertError(
  function()
    PlaylistConditions.validate { kind = 'rule', id = 'cellNameExact', args = { { 'x' }, 'extra' } }
  end,
  'wrong argument count'
)
assertError(
  function() PlaylistConditions.deserialize { version = 2, root = exteriorCondition } end,
  'version'
)
assertError(
  function()
    PlaylistConditions.validate {
      kind = 'rule',
      id = 'cellNameExact',
      args = { { [1] = 'x', [3] = 'y' } },
    }
  end,
  'sparse'
)
local cyclic = { kind = 'not' }
cyclic.child = cyclic
assertError(function() PlaylistConditions.validate(cyclic) end, 'cycle')
local deep = PlaylistConditions.state('cellIsExterior', 'eq', true)
for depth = 1, PlaylistConditions.MAX_DEPTH do
  deep = { kind = 'not', child = deep }
end
assertError(function() PlaylistConditions.validate(deep) end, 'tree limit')

local environment = {
  Playback = {
    state = { cellIsExterior = nil, isInCombat = false },
    rules = {},
  },
}
local calls = {}
for ruleId, ruleSpec in pairs(ConditionRegistry.rules) do
  environment.Playback.rules[ruleId] = function(...)
    calls[ruleId] = { ... }
    return true
  end
  local args = {}
  for argumentIndex = 1, #ruleSpec.arguments do
    local kind = ruleSpec.arguments[argumentIndex]
    if kind == 'hour' then
      args[argumentIndex] = 0
    elseif kind == 'patterns' then
      args[argumentIndex] = { allowed = { 'x' }, disallowed = {} }
    else
      args[argumentIndex] = { 'X' }
    end
  end
  local leaf = PlaylistConditions.rule(ruleId, unpack(args))
  local callback = PlaylistConditions.compile(leaf, environment.Playback, loadCode)
  assert(callback() == true, ruleId .. ' did not compile to true')
  assert(callback() == true, ruleId .. ' did not remain callable')
end
assert(calls.cellNameExact[1].x == true, 'nameSet was not emitted as a presence map')
assert(calls.combatTargetMatch[1][1] == 'x', 'lowerList was not canonicalized')

local stateCallback = PlaylistConditions.compile(
  PlaylistConditions.state('cellIsExterior', 'ne', true),
  environment.Playback,
  loadCode
)
assert(stateCallback() == true, 'ne should retain Lua nil semantics')
local orderingCallback = PlaylistConditions.compile(
  PlaylistConditions.state('cellWaterLevel', 'lt', 2),
  environment.Playback,
  loadCode
)
assert(orderingCallback() == false, 'ordering against nil should not match')
environment.Playback.state.cellIsExterior = true
assert(PlaylistConditions.compile(tree, environment.Playback, loadCode)() == false)
environment.Playback.state.isInCombat = true
assert(PlaylistConditions.compile(tree, environment.Playback, loadCode)() == true)

local declarations, callbackSource =
  PlaylistConditions.emit(PlaylistConditions.rule('cellNameExact', { 'Balmora', 'Seyda Neen' }))
assert(declarations:find('conditionArg1', 1, true))
assert(callbackSource:find('Playback.rules.cellNameExact', 1, true))
assert(not callbackSource:find('evaluateAst', 1, true))

for registryIndex = 1, #ConditionRegistry.ordered do
  local registryEntry = ConditionRegistry.ordered[registryIndex]
  assert(registryEntry.id and registryEntry.label and registryEntry.category)
  if registryEntry.kind == 'rule' then
    for argumentIndex = 1, #registryEntry.arguments do
      assert(registryEntry.arguments[argumentIndex])
    end
  else
    assert(registryEntry.valueType)
  end
end

print 'S3maphore playlist condition torture tests passed'
