---@module 'doc.s3maphoreTypes'
---@omw-context player

local assert, Ceil, Max, Min, TableConcat = assert, math.ceil, math.max, math.min, table.concat

---@type openmw.SelfObject
local gameSelf = require 'openmw.self'
---@type openmw.types.Player
local myType, gameSelfId, sendEvent = gameSelf.type, gameSelf.id, gameSelf.sendEvent

local Health, IsDead, Level, MyLevel =
  myType.stats.dynamic.health,
  myType.isDead,
  myType.stats.level,
  assert(myType.stats.level(gameSelf))

local IsAIEnabled
do
  local debug = require 'openmw.debug'
  IsAIEnabled = debug.isAIEnabled
end

---@type MusicManager
local MusicManager = require 'scripts.s3.music.musicManager'
---@type S3maphoreCoreSettings
local MusicSettings = require 'scripts.s3.music.musicSettings'
---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules'
---@type PlaylistState
local PlaylistState = require 'scripts.s3.music.playlistState'

--- Actor polling state for batch combat-target checks
local Actors = require('openmw.nearby').actors
local MIN_BATCH_SIZE, MAX_BATCH_SIZE, TARGET_LATENCY, THIRTY_FRAMES = 4, 16, 1 / 3, 1 / 30
local chainPosition = 2

---@type openmw.LObject[]
local combatTargets = {}
PlaylistState.combatTargets = combatTargets
---@type table<string, integer>
local combatTargetIdx = {}
---@type table<string, boolean>
local playerTargetedActors = {}

local function recomputeState()
  local ids = {}
  local validIds = {}
  local allBelowThreshold = MusicSettings.CombatHealthThreshold > 0
  local needsLevelGap = MusicSettings.CombatLevelGap > 0
  local needsPlayerTargeted = MusicSettings.PlayerTargetedCombatOnly
  local currentLevel = MyLevel.current
  local threshold = MusicSettings.CombatHealthThreshold

  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local id = actor.id
    ids[#ids + 1] = id

    local skip = false

    if needsLevelGap and currentLevel - Level(actor).current > MusicSettings.CombatLevelGap then
      skip = true
    end

    if not skip and needsPlayerTargeted and not playerTargetedActors[id] then skip = true end

    if not skip then
      if allBelowThreshold then
        local hp = Health(actor)
        ---@cast hp openmw.types.DynamicStat

        if hp.current / hp.base > threshold then allBelowThreshold = false end
      end

      validIds[#validIds + 1] = id
    end
  end

  local cacheKey
  if ids[1] then cacheKey = TableConcat(ids) end

  if allBelowThreshold and validIds[1] then validIds = {} end

  local nowInCombat = validIds[1] ~= nil and IsAIEnabled()

  PlaylistState.isInCombat = nowInCombat and MusicSettings.BattleEnabled
  PlaylistState.isExploring = MusicSettings.ExploreEnabled and not PlaylistState.isInCombat
  MusicManager.activePlaydeck = PlaylistState.isInCombat and MusicManager.battlePlaylists
    or MusicManager.explorePlaylists
  PlaylistRules.setCombatTargetCacheKey(cacheKey)
end

---@param actor openmw.LObject
---@param targets GameObject[]
local function onTargetsChanged(actor, targets)
  if IsDead(gameSelf) then return end

  if targets[1] ~= nil then
    if not combatTargetIdx[actor.id] then
      combatTargets[#combatTargets + 1] = actor
      combatTargetIdx[actor.id] = #combatTargets
    end

    local targetsPlayer = false
    for i = 1, #targets do
      if targets[i].id == gameSelfId then
        targetsPlayer = true
        break
      end
    end
    playerTargetedActors[actor.id] = targetsPlayer
  else
    local idx = combatTargetIdx[actor.id]
    if idx then
      local last = combatTargets[#combatTargets]
      combatTargets[idx] = last
      if last then combatTargetIdx[last.id] = idx end
      combatTargets[#combatTargets] = nil
      combatTargetIdx[actor.id] = nil
    end

    playerTargetedActors[actor.id] = nil
    PlaylistRules.clearCombatCaches(actor.id)
  end

  recomputeState()
end

---@return boolean true whether changed as a result
local function onHit()
  if MusicSettings.CombatHealthThreshold <= 0 then return false end
  local oldIsInCombat = PlaylistState.isInCombat
  recomputeState()
  return PlaylistState.isInCombat ~= oldIsInCombat
end

---@param actorId string
---@return boolean isInCombat
local function actorIsInCombat(actorId) return combatTargetIdx[actorId] ~= nil end

--- Batches per-frame combat target polling across nearby actors.
--- Spreads the load across frames so we don't check all actors every tick.
---@param dt number
local function batchPoll(dt)
  local numActors = #Actors
  if numActors < 2 then return end

  dt = dt == 0 and THIRTY_FRAMES or dt

  local batchSize =
    Max(MIN_BATCH_SIZE, Min(MAX_BATCH_SIZE, Ceil((numActors - 1) * dt / TARGET_LATENCY)))

  for _ = 1, batchSize do
    if chainPosition > numActors then chainPosition = 2 end
    local actor = Actors[chainPosition]
    sendEvent(actor, 'S3maphoreCheckCombat')
    chainPosition = chainPosition + 1
  end
end

--- Resets the actor polling cycle so the next batchPoll starts from the beginning.
--- Call on cell transitions or any event that invalidates the current traversal position.
local function resetPollCycle() chainPosition = 2 end

---@class CombatState
local CombatState = {
  actorIsInCombat = actorIsInCombat,
  batchPoll = batchPoll,
  onHit = onHit,
  onTargetsChanged = onTargetsChanged,
  recomputeState = recomputeState,
  resetPollCycle = resetPollCycle,
}

return CombatState
