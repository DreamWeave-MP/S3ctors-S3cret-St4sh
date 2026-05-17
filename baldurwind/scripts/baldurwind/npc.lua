local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ai = require('openmw.interfaces').AI
local core = require('openmw.core')
local async = require('openmw.async')

local didAttack = false
local hasStartedCombat = false
local hasDied = false
local isMyTurn = true
local isCurrentCompanion = false
local combatants = {}

-- end their turn if not types.Actor.canMove(self)

local function getPlayer()
  for _, actor in ipairs(nearby.actors) do
    if actor.type == types.Player then
      return actor
    end
  end
end

local function sendEndTurn()
  core.sendGlobalEvent('endTurn', {lastActor = self.object, reason = "endTurn"})
end

local function NPCEndTurn()
  self:enableAI(false)
  isMyTurn = false
  sendEndTurn()
end

local function isInCombat()
  local currentPackage = ai.getActivePackage(self)

  -- What happens when they try to flee??

  if not currentPackage then return false end

  if currentPackage.type ~= "Combat" then return false end

  if not types.Actor.canMove(self) then
    NPCEndTurn()
    return false
  end

  return currentPackage

end

local function startTurn(combatants)

  combatants = combatants

  self:enableAI(true)

  -- if isCurrentCompanion and not isInCombat() then
  --   sendEndTurn()
  --   return
  -- end
  isMyTurn = true
end

local function endCombat()

end

local function isCompanion()
  if isCurrentCompanion then return end

  local currentPackage = ai.getActivePackage(self)

  if not currentPackage or types.Actor.stats.dynamic["health"](self).current <= 0 then return false end

  if currentPackage.type ~= "Follow" and
    currentPackage.target ~= "player" and
    currentPackage.sideWithTarget ~= true then return false end

  core.sendGlobalEvent('addFriendlyCombatant', self)

  isCurrentCompanion = true

end

local function checkCombatTarget(aiData)
  if hasStartedCombat then return end

  hasStartedCombat = true

  if isCurrentCompanion then return end

  -- Fix this later, when accounting for companions
  -- if aiData.target.recordId ~= "player" then return end

  local combatData = {
    aiTarget = aiData.target,
    aiType = aiData.type,
    source = self.object
  }

  core.sendGlobalEvent('combatInitiated', {ai = combatData, origin = self.object})

end



local function wasKilled()
  if not hasStartedCombat then return false end

  if hasDied then return true end

  local health = types.Actor.stats.dynamic["health"](self).current

  if health > 0 or not hasStartedCombat then return false end

  core.sendGlobalEvent('combatantDied', self.object)

  hasDied = true

  return true
end

local function doAttack(dt)
  isCompanion()

  local died = wasKilled()

  if not isMyTurn then return end

  local aiData = isInCombat()

  if died or not aiData then return end

  checkCombatTarget(aiData)

  -- migrate into a separate function for turn processing

  local attackState = self.controls.use

  if attackState == 1 then
    didAttack = true
    return
  end

  if not didAttack then return end

  didAttack = false
  NPCEndTurn()

end

return {
  engineHandlers = {
    onUpdate = doAttack,
  },
  eventHandlers = {
    isMyTurn = startTurn,
    isNotMyTurn = function()
      self:enableAI(false)
      isMyTurn = false
    end,
    endCombat = function()
      self:enableAI(true)
      isMyTurn = false
      hasStartedCombat = false
      didAttack = false
    end
  }
}
