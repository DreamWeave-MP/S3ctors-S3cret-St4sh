---@omw-context global

local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'
local types = require 'openmw.types'

local actionHandlers = require 'Scripts.staticSwitcher.actionHandlers'
local conditionHandlers = require 'Scripts.staticSwitcher.conditionHandlers'

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local next, pcall, tostring, type = next, pcall, tostring, type
local StrFind, StrFormat = string.find, string.format

--- Keys allowed in an action block that are not themselves actions.
local ACTION_MODIFIER_KEYS = {
  chance = true,
}

local KNOWN_KEYS = {
  log_name = true,
  once = true,
  priority = true,
  replace_names = true,
  exterior_cells = true,
  replace_regions = true,
  ignore_records = true,
  replace_meshes = true,
  instances = true,
}

---@param modulePath string
---@param moduleData table
local function validateModule(modulePath, moduleData)
  for key in pairs(moduleData) do
    if not KNOWN_KEYS[key] then
      print(StrFormat('SSS Warning: unknown top-level key "%s" in %s', key, modulePath))
    end
  end

  if not moduleData.replace_meshes and not moduleData.instances then
    print(StrFormat('SSS Warning: no replace_meshes or instances in %s', modulePath))
  end

  if moduleData.replace_meshes and moduleData.instances then
    print(
      StrFormat(
        'SSS Warning: both replace_meshes and instances in %s; they are mutually exclusive',
        modulePath
      )
    )
  end
end

--- Conditions that read the trigger's own context, with the triggers that supply it.
---@type table<string, table<string, true>>
local TRIGGER_SCOPED_CONDITIONS = {
  by_player = TriggerContext.ACTOR_TRIGGERS,
  used_item = { use = true },
}

--- Actions that take their target out of the world; the player cannot be their target.
local TARGET_REMOVING_ACTIONS = {
  replace = true,
  disable = true,
  delete = true,
}

local RECORD_PATTERN_CONDITIONS = {
  record_id = true,
  used_item = true,
}

--- A trigger listed twice would index its rule twice, and the rule would then match twice in
--- one pass, before `once` had been recorded for either match.
---@param trigger string|string[]?
---@return string[]? triggerNames
---@return string? problem
local function readTriggerNames(trigger)
  if trigger == nil then return { TriggerContext.ACTIVE } end

  local triggerNames = type(trigger) == 'table' and trigger or { trigger }
  if #triggerNames == 0 then return nil, 'trigger is an empty list' end

  local seenTriggerNames = {}

  for triggerIndex = 1, #triggerNames do
    local triggerName = triggerNames[triggerIndex]

    if type(triggerName) ~= 'string' or not TriggerContext.isKnownTrigger(triggerName) then
      return nil, StrFormat('unknown trigger "%s"', tostring(triggerName))
    end

    if seenTriggerNames[triggerName] then
      return nil, StrFormat('trigger "%s" is listed twice', triggerName)
    end
    seenTriggerNames[triggerName] = true
  end

  return triggerNames
end

---@param value string|number|boolean|table|nil
---@return boolean
local function isText(value) return type(value) == 'string' and value ~= '' end

---@param objectTypeValue string|string[]
---@return string? unknownTypeName
local function findUnknownObjectType(objectTypeValue)
  if type(objectTypeValue) == 'table' then
    for typeIndex = 1, #objectTypeValue do
      local unknownTypeName = findUnknownObjectType(objectTypeValue[typeIndex])
      if unknownTypeName then return unknownTypeName end
    end

    return
  end

  local objectType = isText(objectTypeValue) and types[objectTypeValue]

  if type(objectType) ~= 'table' or type(objectType.objectIsInstance) ~= 'function' then
    return tostring(objectTypeValue)
  end
end

local CREATE_VECTOR_FIELDS = { 'position', 'rotate' }
local VECTOR_AXES = { 'x', 'y', 'z' }

local CREATE_TRANSFORM_TYPES = {
  relative = true,
  absolute = true,
}

--- A sampled range is a fixed number or a table with a numeric `max`; `min` is optional.
---@param rangeValue number|RangeTable|nil
---@return boolean isUsable
local function isSampledRange(rangeValue)
  if rangeValue == nil or type(rangeValue) == 'number' then return true end
  if type(rangeValue) ~= 'table' or type(rangeValue.max) ~= 'number' then return false end

  local min = rangeValue.min
  return min == nil or type(min) == 'number'
end

---@param countValue integer|RangeTable|nil
---@return boolean isUsable
local function isCountRange(countValue)
  if not isSampledRange(countValue) then return false end
  if type(countValue) ~= 'table' then return true end

  return (countValue.min or 1) <= countValue.max
end

---@param details string|number|SSSCreatePool
---@return string? problem phrased to follow the pool's record ID
local function findCreatePoolProblem(details)
  local detailsType = type(details)

  if detailsType == 'string' or detailsType == 'number' then return end
  if detailsType ~= 'table' then return 'must be a record ID, a count, or a pool' end

  if not isCountRange(details.count) then return 'has a count range without a usable max' end
  if not isSampledRange(details.chance) then return 'has a chance range without max' end
  if not isSampledRange(details.scale) then return 'has a scale range without max' end

  for fieldIndex = 1, #CREATE_VECTOR_FIELDS do
    local fieldName = CREATE_VECTOR_FIELDS[fieldIndex]
    local vector = details[fieldName]

    if vector ~= nil then
      if type(vector) ~= 'table' then return StrFormat('has a %s that is not a map', fieldName) end

      for axisIndex = 1, #VECTOR_AXES do
        if not isSampledRange(vector[VECTOR_AXES[axisIndex]]) then
          return StrFormat('has a %s range without max', fieldName)
        end
      end
    end
  end

  local transformType = details.transform_type
  if transformType ~= nil and not CREATE_TRANSFORM_TYPES[transformType] then
    return StrFormat('has unknown transform_type "%s"', tostring(transformType))
  end
end

--- Shapes a handler would otherwise only discover by raising, once per object it ran on.
---@type table<string, fun(actionValue: string|number|boolean|table): string?>
local ACTION_PAYLOAD_PROBLEMS = {
  create = function(createAction)
    if type(createAction) ~= 'table' then return 'create needs a map of record IDs to pools' end

    for recordId, details in next, createAction do
      local poolProblem = findCreatePoolProblem(details)

      if poolProblem then
        return StrFormat('create pool "%s" %s', tostring(recordId), poolProblem)
      end
    end
  end,
  set_weather = function(weatherAction)
    if isText(weatherAction) then return end

    if type(weatherAction) ~= 'table' or not isText(weatherAction.weather) then
      return 'set_weather needs a weather record ID'
    end

    if weatherAction.region ~= nil and not isText(weatherAction.region) then
      return 'set_weather region must be a region record ID'
    end
  end,
  global_set = function(globalAction)
    if type(globalAction) ~= 'table' or not isText(globalAction.name) then
      return 'global_set needs a name'
    end
  end,
  call_interface = function(callAction)
    if
      type(callAction) ~= 'table'
      or not isText(callAction.interface)
      or not isText(callAction['function'])
    then
      return 'call_interface needs an interface and a function'
    end
  end,
  send_event = function(eventAction)
    if type(eventAction) ~= 'table' or not isText(eventAction.name) then
      return 'send_event needs a name'
    end
  end,
  send_global_event = function(eventAction)
    if type(eventAction) ~= 'table' or not isText(eventAction.name) then
      return 'send_global_event needs a name'
    end
  end,
  run_lua_script = function(runAction)
    if type(runAction) ~= 'table' or not isText(runAction.script) then
      return 'run_lua_script needs a script'
    end
  end,
  add_lua_script = function(scriptPath)
    if not isText(scriptPath) then return 'add_lua_script needs a script path' end
  end,
  remove_lua_script = function(scriptPath)
    if not isText(scriptPath) then return 'remove_lua_script needs a script path' end
  end,
}

---@param conditionName string
---@param triggerNames string[]
---@return string? unsupportedTrigger
local function findUnsupportedTrigger(conditionName, triggerNames)
  local supportedTriggers = TRIGGER_SCOPED_CONDITIONS[conditionName]
  if not supportedTriggers then return end

  for triggerIndex = 1, #triggerNames do
    local triggerName = triggerNames[triggerIndex]
    if not supportedTriggers[triggerName] then return triggerName end
  end
end

---@param recordIdValue string|string[]
---@return string? invalidPattern
local function findInvalidRecordIdPattern(recordIdValue)
  if type(recordIdValue) == 'string' then
    if not pcall(StrFind, '', recordIdValue) then return recordIdValue end
  elseif type(recordIdValue) == 'table' then
    for patternIndex = 1, #recordIdValue do
      local invalidPattern = findInvalidRecordIdPattern(recordIdValue[patternIndex])
      if invalidPattern then return invalidPattern end
    end
  end
end

---@param conditionData SSSConditionData
---@param triggerNames string[]
---@return string? problem
local function findConditionProblem(conditionData, triggerNames)
  if type(conditionData) ~= 'table' then return 'a condition entry is not a map' end

  for conditionName, conditionValue in next, conditionData do
    if type(conditionHandlers[conditionName]) ~= 'function' then
      return StrFormat('unknown condition "%s"', tostring(conditionName))
    end

    local unsupportedTrigger = findUnsupportedTrigger(conditionName, triggerNames)
    if unsupportedTrigger then
      return StrFormat(
        'condition "%s" is not available on trigger "%s"',
        conditionName,
        unsupportedTrigger
      )
    end

    if conditionName == 'not' then
      local negatedProblem = findConditionProblem(conditionValue, triggerNames)
      if negatedProblem then return negatedProblem end
    elseif conditionName == 'object_type' then
      local unknownTypeName = findUnknownObjectType(conditionValue)
      if unknownTypeName then return StrFormat('unknown object_type "%s"', unknownTypeName) end
    elseif RECORD_PATTERN_CONDITIONS[conditionName] then
      local invalidPattern = findInvalidRecordIdPattern(conditionValue)

      if invalidPattern then
        return StrFormat('%s "%s" is not a valid Lua pattern', conditionName, invalidPattern)
      end
    end
  end
end

---@param triggerNames string[]
---@return string? playerSubjectTrigger
local function findPlayerSubjectTrigger(triggerNames)
  for triggerIndex = 1, #triggerNames do
    local triggerName = triggerNames[triggerIndex]
    if TriggerContext.PLAYER_SUBJECT_TRIGGERS[triggerName] then return triggerName end
  end
end

---@param actionData SSSInstanceAction
---@param playerSubjectTrigger string? trigger of this rule that runs it on the player, if any
---@return string? problem
local function findActionProblem(actionData, playerSubjectTrigger)
  if type(actionData) ~= 'table' then return 'an action entry is not a map' end

  for actionName, actionValue in next, actionData do
    if not ACTION_MODIFIER_KEYS[actionName] and type(actionHandlers[actionName]) ~= 'function' then
      return StrFormat('unknown action "%s"', tostring(actionName))
    end

    local findPayloadProblem = ACTION_PAYLOAD_PROBLEMS[actionName]
    local payloadProblem = findPayloadProblem and findPayloadProblem(actionValue)
    if payloadProblem then return payloadProblem end

    if playerSubjectTrigger and TARGET_REMOVING_ACTIONS[actionName] then
      return StrFormat(
        'action "%s" is not available on trigger "%s", which runs on the player',
        actionName,
        playerSubjectTrigger
      )
    end
  end
end

---@param instanceRule SSSInstanceRule
---@return string? problem
local function findRuleProblem(instanceRule)
  if type(instanceRule) ~= 'table' then return 'the rule is not a map' end

  local conditions, actions = instanceRule.conditions, instanceRule.actions

  if type(actions) ~= 'table' then return 'the rule has no actions list' end
  if conditions ~= nil and type(conditions) ~= 'table' then return 'conditions is not a list' end

  local triggerNames, triggerProblem = readTriggerNames(instanceRule.trigger)
  if not triggerNames then return triggerProblem end

  local namesJournalQuest = false

  if conditions then
    for conditionIndex = 1, #conditions do
      local conditionData = conditions[conditionIndex]

      local problem = findConditionProblem(conditionData, triggerNames)
      if problem then return problem end

      namesJournalQuest = namesJournalQuest or conditionData.has_journal ~= nil
    end
  end

  for triggerIndex = 1, #triggerNames do
    if triggerNames[triggerIndex] == 'journal' and not namesJournalQuest then
      return 'trigger "journal" needs a has_journal condition naming the quest to watch'
    end
  end

  local playerSubjectTrigger = findPlayerSubjectTrigger(triggerNames)

  for actionIndex = 1, #actions do
    local problem = findActionProblem(actions[actionIndex], playerSubjectTrigger)
    if problem then return problem end
  end
end

--- A rule with an unknown condition or action name is rejected whole. Dropping only the
--- unknown entry would leave a rule that matches more objects than its author wrote.
---@param modulePath string
---@param ruleIndex integer
---@param instanceRule SSSInstanceRule
---@return boolean isValid
local function validateRule(modulePath, ruleIndex, instanceRule)
  local problem = findRuleProblem(instanceRule)
  if not problem then return true end

  WarnLog(StrFormat('Skipped rule %d in %s: %s', ruleIndex, modulePath, problem))
  return false
end

return { validate = validateModule, validateRule = validateRule }
