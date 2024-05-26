local core = require('openmw.core')
local uiLib = require('openmw.ui')
local inputLib = require('openmw.input')
local types = require('openmw.types')
local self = require('openmw.self')
local async = require('openmw.async')

local lastTarget
local isMyTurn = true
local debug = true
local isInCombat = false
local canTimedAttack = false
local didTimedAttack = false
local didAttack = false
local attackDelayTimer = 0.3
local timeSinceAttack = 0
local attributes = types.Actor.stats.attributes
local attackDelayTimerUpperRange = 150

local function startAttack()
  self.controls.use = 1
end

local function finishAttack()
  self.controls.use = 0
end

-- true for yes, false for no; let's use real notation next time
local function switchControls(canControl)
  inputLib.setControlSwitch(inputLib.CONTROL_SWITCH.Controls, canControl)
end

local function playerEndTurn()
  if not isMyTurn then return end

  uiLib.showMessage("Switching Turns!")
  if types.Actor.stance(self) == types.Actor.STANCE.Weapon then finishAttack() end
  isMyTurn = false
  canTimedAttack = false
  didTimedAttack = false
  didAttack = false
  core.sendGlobalEvent('endTurn', {lastActor = self.object, reason = "endTurn"})
end

local function explainEndTurn(endReason)
  if not debug then return end

  if not endReason then endReason = "unknown!" end
  uiLib.showMessage("Ending Turn due to " .. endReason .. "!")
end

local function handleTimedAttack(currentTurnAttackDelay)
  if not canTimedAttack or didTimedAttack then return end

  local timedAttackLow = currentTurnAttackDelay / 3
  local timedAttackHigh = (currentTurnAttackDelay / 3) * 2
  local playerStrength = attributes.strength(self)
  local oldMod = playerStrength.modifier
  local strengthDelta = playerStrength.base * .5

  if timeSinceAttack >= timedAttackLow and timeSinceAttack <= timedAttackHigh then
    uiLib.showMessage("Timed attack! Strength buff is: " .. strengthDelta)
  else
    strengthDelta = -strengthDelta
    uiLib.showMessage("You fumbled your attack! Strength buff is: " .. strengthDelta)
  end

  playerStrength.modifier = strengthDelta

  -- is this safe?
  async:newUnsavableSimulationTimer(1, function()
                                      if strengthDelta < 0 then
                                        playerStrength.modifier = oldMod + -strengthDelta
                                      else
                                        playerStrength.modifier = oldMod
                                      end
  end)

  didTimedAttack = true
  canTimedAttack = false
end

local function endAttackEvent(currentTurnAttackDelay)
  switchControls(false)
  async:newUnsavableSimulationTimer(currentTurnAttackDelay, function()
                                      explainEndTurn("attack")
                                      playerEndTurn()
  end)
  didAttack = true
end

local function isUsingWeapon()
  local playerStance = types.Actor.stance(self)

  if playerStance == types.Actor.STANCE.Weapon then return true end

  return false
end

local function getAttackDelay()
  if isUsingWeapon() then
    return attackDelayTimer + (math.random(1, attackDelayTimerUpperRange) / 100)
  end

  return attackDelayTimer + .45
end

local function startAttackEvent()

  if types.Actor.stance(self) == types.Actor.STANCE.Nothing then return end

  startAttack()

  -- ranged/magic should have a much longer timer, so they're able to properly hit the target
  local currentTurnAttackDelay = getAttackDelay()

  -- Ranged weapons shouldn't have timed attacks
  if canTimedAttack then handleTimedAttack(currentTurnAttackDelay) end

  -- only handle timed attacks for the second input
  canTimedAttack = true
  -- don't trigger again for a timed attack
  if didAttack then return end

  if debug then uiLib.showMessage("Initiating attack!") end

  if debug then uiLib.showMessage("Current attack delay is: " .. currentTurnAttackDelay) end
  endAttackEvent(currentTurnAttackDelay)
end

local function inputManager(key)
  if not isInCombat or not isMyTurn then return end

  if key == inputLib.ACTION.Use then
    startAttackEvent()
  elseif key == inputLib.ACTION.Activate and isInCombat then
      explainEndTurn("manual intervention")
      switchControls(false)
      playerEndTurn()
  end

end

local function beginTurn()
  switchControls(true)
  isMyTurn = true
end


-- for now, this doesn't take into account possible other combatants.
-- A global script should control the round order.
local function initiateCombat(combatants)
  lastTarget = combatants[#combatants]
  if lastTarget then
    uiLib.showMessage("You were attacked by " .. lastTarget.recordId .. "!")
  end

  uiLib.showMessage("It is now your turn.")

  --async:newUnsavableSimulationTimer(30, function()
                                      -- if isMyTurn then
                                      --   inputLib.setControlSwitch(inputLib.CONTROL_SWITCH.Controls, false)
                                      --   playerEndTurn()
                                      --   explainEndTurn("expiration")
                                      -- end
  -- end)
  -- Re-enable player controls
  beginTurn()
end

local function declareFight(origin)
  isInCombat = true
  --[[
    perhaps later we should add the ability to do a reaction roll; the origin is already being provided
    So there shouldn't be any issue in comparing the two actor stats and taking turn
    priority over them in some cases.
  ]]--

  -- Force loss of combat controls when a fight begins
  switchControls(false)

  if not debug then return end

  -- uiLib.showMessage(origin.source.recordId
  --                   .. " has ai package: " .. origin.aiType
  --                   .. " and is targeting " .. origin.aiTarget.recordId .. "!")
end

local function declareFightEnd()
  isInCombat = false
  switchControls(true)
  -- beginTurn()
end

local function onFrame(dt)
  if not canTimedAttack then timeSinceAttack = 0 return end

  timeSinceAttack = timeSinceAttack + dt
end

return {
  interfaceName = "s3turnsplayer",
  interface = {
    isMyTurn = isMyTurn,
    version = 001
  },
  engineHandlers = {
    onInputAction = inputManager,
    onFrame = onFrame
  },
  eventHandlers = {
    isMyTurn = initiateCombat,
    isNotMyTurn = declareFight,
    endCombat = declareFightEnd
  }
}
