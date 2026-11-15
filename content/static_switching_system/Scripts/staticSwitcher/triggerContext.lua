---@omw-context none

local StrFind = string.find

local CUSTOM_PREFIX = 'custom:'

--- Triggers that run a rule on one object the engine or another mod names.
local OBJECT_TRIGGERS = {
  active = true,
  activate = true,
  drop = true,
  place = true,
  use = true,
  death = true,
  cell_enter = true,
}

--- Triggers with no object of their own; they sweep the objects around the player.
local WORLD_TRIGGERS = {
  journal = true,
  hour = true,
  day = true,
  weather = true,
}

--- Triggers whose rules always run on the player, who cannot be replaced or removed.
local PLAYER_SUBJECT_TRIGGERS = {
  cell_enter = true,
}

--- Triggers that carry the actor who caused them.
local ACTOR_TRIGGERS = {
  activate = true,
  drop = true,
  place = true,
  use = true,
}

---@param triggerName string
---@return boolean
local function isCustomTrigger(triggerName)
  return StrFind(triggerName, CUSTOM_PREFIX, 1, true) == 1 and #triggerName > #CUSTOM_PREFIX
end

---@param triggerName string
---@return boolean
local function isKnownTrigger(triggerName)
  return OBJECT_TRIGGERS[triggerName] == true
    or WORLD_TRIGGERS[triggerName] == true
    or isCustomTrigger(triggerName)
end

---@class SSSTriggerContext
---@field actor openmw.GObject? actor that caused the trigger being dispatched
---@field item openmw.GObject? item used in the `use` trigger being dispatched
---@field expectedWeatherIds string[] weathers SSS itself requested for the player's region and has not yet seen arrive, oldest first
---@field expectedPlayerCellId string? cell an SSS teleport is sending the player to
---@field playerReturnCellId string? cell the player is being put back in after an abandoned pass moved them
---@field playerReturnPollsLeft integer cell polls left before the player is taken to have settled
local TriggerContext = {
  ACTIVE = 'active',
  ACTOR_TRIGGERS = ACTOR_TRIGGERS,
  CUSTOM_PREFIX = CUSTOM_PREFIX,
  expectedWeatherIds = {},
  playerReturnPollsLeft = 0,
  PLAYER_SUBJECT_TRIGGERS = PLAYER_SUBJECT_TRIGGERS,
  WORLD_TRIGGERS = WORLD_TRIGGERS,
  isKnownTrigger = isKnownTrigger,
}

return TriggerContext
