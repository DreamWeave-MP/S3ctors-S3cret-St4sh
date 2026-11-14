---@omw-context global

local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'
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

local RECORD_PATTERN_CONDITIONS = {
  record_id = true,
  used_item = true,
}

---@param trigger string|string[]?
---@return string[]? triggerNames
---@return string? problem
local function readTriggerNames(trigger)
  if trigger == nil then return { TriggerContext.ACTIVE } end

  local triggerNames = type(trigger) == 'table' and trigger or { trigger }
  if #triggerNames == 0 then return nil, 'trigger is an empty list' end

  for triggerIndex = 1, #triggerNames do
    local triggerName = triggerNames[triggerIndex]

    if type(triggerName) ~= 'string' or not TriggerContext.isKnownTrigger(triggerName) then
      return nil, StrFormat('unknown trigger "%s"', tostring(triggerName))
    end
  end

  return triggerNames
end

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
    elseif RECORD_PATTERN_CONDITIONS[conditionName] then
      local invalidPattern = findInvalidRecordIdPattern(conditionValue)

      if invalidPattern then
        return StrFormat('%s "%s" is not a valid Lua pattern', conditionName, invalidPattern)
      end
    end
  end
end

---@param actionData SSSInstanceAction
---@return string? problem
local function findActionProblem(actionData)
  if type(actionData) ~= 'table' then return 'an action entry is not a map' end

  for actionName in next, actionData do
    if not ACTION_MODIFIER_KEYS[actionName] and type(actionHandlers[actionName]) ~= 'function' then
      return StrFormat('unknown action "%s"', tostring(actionName))
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

  for actionIndex = 1, #actions do
    local problem = findActionProblem(actions[actionIndex])
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
