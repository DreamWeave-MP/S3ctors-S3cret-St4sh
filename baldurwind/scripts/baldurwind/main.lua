local world = require('openmw.world')
local types = require('openmw.types')
local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local ai = require('openmw.interfaces').AI
local common = require('scripts.baldurwind.common')

--table including all actors in combat
-- start with npcs, and players
-- for now creatures are not technically affected though.
-- How do we determine combatants?
local combatants = {}
local enemies = {}
local party = {}
local const = {
  TURNSWITCHRANGE = 750,
  TURNEXPIRETIME = 6.0,
}

local function targetInTable(targetObject, targetTable)
  for _, ref in ipairs(targetTable) do
    if (ref == targetObject) then return true end
  end
  return false
end

local function getPlayer()
  for _, ref in ipairs(world.activeActors) do
    if (ref.type == types.Player) then
      return ref
    end
  end
end

local function findEnemyCombatantIndex(enemy)
  for index, ref in ipairs(combatants) do
    if (ref == enemy) then
      return index
    end
  end
end

local function hasActiveEnemyCombatants()
  for _, ref in ipairs(combatants) do
    if not targetInTable(ref, party) then
      return true
    end
  end
  return false
end

local function setNextInTurnOrder()
  table.insert(combatants, table.remove(combatants, 1))
end

local function removeFromTurnOrder(actor)
  if not actor or actor.type == types.Player then return end
  table.remove(combatants, findEnemyCombatantIndex(actor))
  common.debugMePls("Removed " .. actor.recordId .. " from combatants table")
end

local function startNextTurn()
  if not hasActiveEnemyCombatants then return end
  combatants[1]:sendEvent('isMyTurn', combatants)
  common.debugMePls("Sending Turn Init to: " .. combatants[1].recordId)
end

local function sendEventToGroup(eventName, groupName)
  for _, partyMember in ipairs(groupName) do
    partyMember:sendEvent(eventName)
  end
end

local function switchTurn()
  if #combatants == 1 then return end
  common.debugMePls("Combatants table prior to turn shift: \n" .. aux_util.deepToString(combatants, 2))
  setNextInTurnOrder()
  common.debugMePls("Combatants table after turn shift: \n" .. aux_util.deepToString(combatants, 2))
  startNextTurn()
  -- When we switch turns
  -- startNextTurn returns the actor whose turn it is
  -- An async timer fires a function which checks if combatants[1] == provided actor
  -- If so we run switchTurn and display a message
  local previousActor = combatants[1]
  async:newUnsavableSimulationTimer(const.TURNEXPIRETIME, function()
				      if previousActor ~= combatants[1] then return end
				      switchTurn()
				      previousActor:sendEvent("isNotMyTurn")
				      common.debugMePls(previousActor.recordId .. "'s turn was force-expired!")
				      end
  )
end

local function declareFightStart(enemyInfo)
  local player = getPlayer()
  local enemy = enemyInfo.origin

  if not targetInTable(enemy, party) then
    table.insert(enemies, enemy)
  end

  common.debugMePls("Combatants table prior to adding actor: \n" .. aux_util.deepToString(combatants, 2))

  -- Newly added actors will take their turns first, so let's put them at the top. Otherwise,
  -- They take two turns when the turn shift occurs.

  if not targetInTable(enemy, combatants) then
    table.insert(combatants, 1, enemy)
  end

  common.debugMePls("Combatants table after adding actor: \n" .. aux_util.deepToString(combatants, 2))

  if ( player.position - enemy.position ):length() > const.TURNSWITCHRANGE then return end

  sendEventToGroup('isNotMyTurn', party)
end

local function combatantDied(actor)
  -- The actor should remove themselves from turn order, first.
  removeFromTurnOrder(actor)
  -- Then process the next turn.
  -- Unless there are no enemies to keep fighting!
  if hasActiveEnemyCombatants() then startNextTurn() return end

  sendEventToGroup('endCombat', party)

end

local function initializeCombatants(player)
  table.insert(combatants, player)
  table.insert(party, player)
  -- I suppose this is where, on load, we should figure out whether a fight was in progress or not.
  -- That'll be fun.
end

return {
    interfaceName = 's3turnsmain',
    interface = {
      combatants = combatants,
      party = party,
      version = 001,
    },
    engineHandlers = {
      onPlayerAdded = initializeCombatants
    },
    eventHandlers = {
      endTurn = switchTurn,
      combatInitiated = declareFightStart,
      addFriendlyCombatant = function(source)
        if not targetInTable(source, combatants) then
          table.insert(party, source)
          table.insert(combatants, source)
          print("Added actor to friendlies from addFriendlyCombatant function")
        end
      end,
      combatantDied = combatantDied
    }
}
