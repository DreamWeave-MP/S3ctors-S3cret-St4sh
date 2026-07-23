---@omw-context local

local next, require = next, require

local gameSelf = require 'openmw.self'

local clear = require 'scripts.s3.clear'

local Players
local Targets = {}

local IsDeathFinished, IsInActorsProcessingRange, IsWorldPaused, GetStance, GetTargets, IsFleeing, UnarmedStance
local SendEvent, SendGlobalEvent = gameSelf.sendEvent, nil

do
  local core = require 'openmw.core'
  IsWorldPaused, SendGlobalEvent = core.isWorldPaused, core.sendGlobalEvent

  local I = require 'openmw.interfaces'
  local AI = I.AI
  GetTargets, IsFleeing = AI.getTargets, AI.isFleeing

  local types = require 'openmw.types'
  IsDeathFinished, IsInActorsProcessingRange =
    types.Actor.isDeathFinished, types.Actor.isInActorsProcessingRange
  GetStance, UnarmedStance = types.Actor.getStance, types.Actor.STANCE.Nothing

  Players = require('openmw.nearby').players

  ---@param attack openmw.interfaces.Combat.AttackInfo
  local function s3maphoreAttackHandler(attack)
    if not attack.successful or not next(Targets) then return end
    for i = 1, #Players do
      SendEvent(Players[i], 'S3maphoreClearTargetCache', gameSelf.object)
    end
  end

  I.Combat.addOnHitHandler(s3maphoreAttackHandler)
end

local function syncTargets(newTargets)
  local n, nn = #Targets, #newTargets

  if nn == n then
    local changed = false

    for i = 1, n do
      local old, new = Targets[i], newTargets[i]
      Targets[i] = new
      if old ~= new then changed = true end
    end

    return changed
  end

  clear(Targets)

  for i = 1, nn do
    Targets[i] = newTargets[i]
  end

  return true
end

local function notifyTargetsChanged()
  local targetData = { actor = gameSelf, targets = Targets }

  for i = 1, #Players do
    SendEvent(Players[i], 'OMWMusicCombatTargetsChanged', targetData)
  end
end

local function updateCombatState()
  local startedWithTargets = next(Targets) ~= nil
  local isDead = IsDeathFinished(gameSelf) or not IsInActorsProcessingRange(gameSelf)

  if isDead then
    if startedWithTargets then
      clear(Targets)
      notifyTargetsChanged()
    end
    return
  end

  if
    (GetStance(gameSelf) == UnarmedStance)
    and not startedWithTargets
    and not IsFleeing()
    and not IsWorldPaused()
  then
    return
  end

  if syncTargets(GetTargets 'Combat') then notifyTargetsChanged() end
end

local function onInactive()
  if not next(Targets) then return end
  clear(Targets)
  notifyTargetsChanged()
end

return {
  engineHandlers = {
    onInactive = onInactive,
  },
  eventHandlers = {
    Died = function()
      SendGlobalEvent('S3maphoreDeathCountIncrement', gameSelf.recordId)
      for i = 1, #Players do
        SendEvent(Players[i], 'S3maphoreClearTargetCache', gameSelf.object)
      end
    end,
    S3maphoreCheckCombat = updateCombatState,
  },
}
