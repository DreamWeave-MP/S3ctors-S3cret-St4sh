---@omw-context player
local ConditionRegistry = { rules = {}, states = {}, ordered = {} }
local argumentKinds =
  { nameSet = true, stringList = true, lowerList = true, patterns = true, hour = true }
local stateKinds = { boolean = true, number = true, string = true }

local function add(kind, id, label, category, arguments, valueType)
  arguments = arguments or {}
  assert(kind == 'rule' or kind == 'state', 'Invalid condition registry kind: ' .. tostring(kind))
  assert(type(id) == 'string' and id ~= '', 'Condition registry IDs must be non-empty strings')
  assert(type(label) == 'string' and label ~= '', 'Condition registry labels are required')
  assert(
    type(category) == 'string' and category ~= '',
    'Condition registry categories are required'
  )
  assert(
    ConditionRegistry.rules[id] == nil and ConditionRegistry.states[id] == nil,
    'Duplicate condition registry ID: ' .. id
  )
  assert(type(arguments) == 'table', 'Condition registry arguments must be a table')
  for i = 1, #arguments do
    assert(
      argumentKinds[arguments[i]],
      'Unknown condition argument kind: ' .. tostring(arguments[i])
    )
  end
  if kind == 'state' then
    assert(stateKinds[valueType], 'Unknown condition state type: ' .. tostring(valueType))
  end
  local entry = {
    kind = kind,
    id = id,
    label = label,
    category = category,
    arguments = arguments,
    valueType = valueType,
  }
  ConditionRegistry[kind == 'rule' and 'rules' or 'states'][id] = entry
  ConditionRegistry.ordered[#ConditionRegistry.ordered + 1] = entry
end

local ruleSpecs = {
  { 'cellNameExact', 'Cell name is exactly', 'Cell', 'nameSet' },
  { 'region', 'Region is', 'Cell', 'nameSet' },
  { 'weatherType', 'Weather is', 'Cell', 'nameSet' },
  { 'cellHasTag', 'Cell has tag', 'Tags', 'stringList' },
  { 'cellContainsTagged', 'Cell contains tagged object', 'Tags', 'stringList' },
  { 'contentTag', 'Content has tag', 'Tags', 'stringList' },
  { 'combatTargetTagged', 'Combat target has tag', 'Combat', 'stringList' },
  { 'combatTargetExact', 'Combat target name is', 'Combat', 'nameSet' },
  { 'combatTargetType', 'Combat target type is', 'Combat', 'nameSet' },
  { 'combatTargetClass', 'Combat target class is', 'Combat', 'nameSet' },
  { 'combatTargetMatch', 'Combat target name contains', 'Combat', 'lowerList' },
  { 'staticContentFile', 'Static content file is', 'Cell', 'nameSet' },
  { 'objectExact', 'Object record is present', 'Cell', 'nameSet' },
}
for i = 1, #ruleSpecs do
  local spec = ruleSpecs[i]
  add('rule', spec[1], spec[2], spec[3], { spec[4] })
end
add('rule', 'cellNameMatch', 'Cell name contains / excludes', 'Cell', { 'patterns' })
add(
  'rule',
  'timeOfDay',
  'Hour in range (start inclusive, end exclusive)',
  'Time',
  { 'hour', 'hour' }
)
add('rule', 'fightingVampires', 'Fighting vampires', 'Combat')
local stateSpecs = {
  { 'cellIsExterior', 'Cell is exterior', 'Cell', 'boolean' },
  { 'cellHasWater', 'Cell has water', 'Cell', 'boolean' },
  { 'cellHasHostileActors', 'Cell has hostile actors', 'Cell', 'boolean' },
  { 'areaHasHostileActors', 'Area has hostile actors', 'Cell', 'boolean' },
  { 'isInCombat', 'In combat', 'Combat', 'boolean' },
  { 'isExploring', 'Exploring', 'Combat', 'boolean' },
  { 'normalizedHealth', 'Health fraction', 'Player', 'number' },
  { 'normalizedMagicka', 'Magicka fraction', 'Player', 'number' },
  { 'normalizedFatigue', 'Fatigue fraction', 'Player', 'number' },
  { 'objectCount', 'Object count', 'Cell', 'number' },
  { 'cellWaterLevel', 'Water level (absent values never match)', 'Cell', 'number' },
  { 'movementMode', 'Movement mode', 'Player', 'string' },
  { 'selectedSpellSchool', 'Selected spell school', 'Player', 'string' },
  { 'playlistTimeOfDay', 'Time of day', 'Time', 'string' },
}
for i = 1, #stateSpecs do
  local spec = stateSpecs[i]
  add('state', spec[1], spec[2], spec[3], nil, spec[4])
end
assert(#ConditionRegistry.ordered > 0, 'Condition registry must not be empty')
return ConditionRegistry
