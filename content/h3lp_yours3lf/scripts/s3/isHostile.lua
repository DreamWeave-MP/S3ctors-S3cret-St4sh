---@omw-context global

local fFightDispMult, iFightDistanceBase, fFightDistanceMultiplier, iWerewolfFightMod
local CalmHumanoid, CalmCreature
local GlobalVariables
local ActiveEffects, AiFight, CanMove, GetDisposition, IsNPC, IsWerewolf
local Player

do
  local core = require 'openmw.core'
  local types = require 'openmw.types'
  local world = require 'openmw.world'

  fFightDispMult, iFightDistanceBase, fFightDistanceMultiplier, iWerewolfFightMod =
    core.getGMST 'fFightDispMult',
    core.getGMST 'iFightDistanceBase',
    core.getGMST 'fFightDistanceMultiplier',
    core.getGMST 'iWerewolfFightMod'

  CalmHumanoid, CalmCreature =
    core.magic.EFFECT_TYPE.CalmHumanoid, core.magic.EFFECT_TYPE.CalmCreature

  GlobalVariables = world.mwscript.getGlobalVariables()
  ---@class openmw.world.MWScriptVariables
  ---@field PCKnownWerewolf integer Whether or not the player is currently known to be a werewolf

  ActiveEffects, AiFight, CanMove, GetDisposition, IsNPC, IsWerewolf =
    types.Actor.activeEffects,
    types.Actor.stats.ai.fight,
    types.Actor.canMove,
    types.NPC.getDisposition,
    types.NPC.objectIsInstance,
    types.NPC.isWerewolf

  Player = world.players[1]
end

-- combat.cpp:561-569
---@param disposition number
---@return number
local function fightDispositionBias(disposition) return (50 - disposition) * fFightDispMult end

-- combat.cpp:571-590
---@param pos1 openmw.util.Vector3
---@param pos2 openmw.util.Vector3
---@return number
local function fightDistanceBias(pos1, pos2)
  local dist = (pos1 - pos2):length()
  return iFightDistanceBase - fFightDistanceMultiplier * dist
end

-- combat.cpp:550-559
---@param actor openmw.GObject
---@param target openmw.GObject
---@return integer
local function getFightTerm(actor, target)
  local fightStat = AiFight(actor)
  local fight = fightStat and fightStat.modified or 0

  local disposition = 50
  if IsNPC(actor) then disposition = GetDisposition(actor, Player) end

  return fight
    + fightDistanceBias(actor.position, target.position)
    + fightDispositionBias(disposition)
end

-- combat.cpp:599-615
---@param actor openmw.GObject
---@return boolean
local function isAggressionCapable(actor)
  if not CanMove(actor) then return false end

  local calmId = IsNPC(actor) and CalmHumanoid or CalmCreature

  ---@diagnostic disable-next-line: param-type-mismatch
  local calm = ActiveEffects(actor):getEffect(calmId)

  if calm and calm.magnitude > 0 then return false end
  return true
end

---@param actor openmw.GObject
---@param target openmw.GObject
---@return boolean
return function(actor, target)
  if
    not actor
    or actor.count <= 0
    or not actor:isValid()
    or not target
    or target.count <= 0
    or not target:isValid()
    or actor == target
  then
    return false
  end

  if not isAggressionCapable(actor) then return false end

  local fight = getFightTerm(actor, target)

  -- combat.cpp:626-637
  if IsNPC(actor) and IsNPC(target) then
    local werewolf

    if target == Player then
      werewolf = GlobalVariables.PCKnownWerewolf ~= 0
    else
      werewolf = IsWerewolf(target)
    end

    if werewolf then fight = fight + iWerewolfFightMod end
  end

  return fight >= 100
end
