---@module 'doc.s3maphoreTypes'
---@omw-context player

local assert, next, TableConcat, TableSort = assert, next, table.concat, table.sort

---@type openmw.SelfObject
local gameSelf = require 'openmw.self'
---@type openmw.types.Player
local myType = gameSelf.type

local Health, IsDead, Level, MyLevel =
    myType.stats.dynamic.health, myType.isDead, myType.stats.level,
    assert(myType.stats.level(gameSelf))

local IsAIEnabled
do
    local debug = require 'openmw.debug'
    IsAIEnabled = debug.isAIEnabled
end

---@type table<string, openmw.LObject>
local combatTargets
---@type table<string, boolean>
local playerTargetedActors = {}

---@type S3maphoreCoreSettings
local MusicSettings
---@type PlaylistRules
local PlaylistRules
---@type MusicManager
local MusicManager
---@type PlaylistState
local PlaylistState

local function recomputeState()
    local ids = {}
    local validIds = {}
    local allBelowThreshold = MusicSettings.CombatHealthThreshold > 0
    local needsLevelGap = MusicSettings.CombatLevelGap > 0
    local needsPlayerTargeted = MusicSettings.PlayerTargetedCombatOnly
    local currentLevel = MyLevel.current
    local threshold = MusicSettings.CombatHealthThreshold

    for id, actor in next, combatTargets do
        ids[#ids + 1] = id

        local skip = false

        if needsLevelGap and currentLevel - Level(actor).current > MusicSettings.CombatLevelGap then
            skip = true
        end

        if not skip and needsPlayerTargeted and not playerTargetedActors[id] then
            skip = true
        end

        if not skip then
            if allBelowThreshold then
                local hp = Health(actor)
                ---@cast hp openmw.types.DynamicStat

                if hp.current / hp.base > threshold then
                    allBelowThreshold = false
                end
            end

            validIds[#validIds + 1] = id
        end
    end

    local cacheKey
    if ids[1] then
        TableSort(ids)
        cacheKey = TableConcat(ids)
    end

    if allBelowThreshold and validIds[1] then
        validIds = {}
    end

    local nowInCombat = validIds[1] ~= nil and IsAIEnabled()

    PlaylistState.isInCombat = nowInCombat and MusicSettings.BattleEnabled
    PlaylistState.isExploring = MusicSettings.ExploreEnabled and not PlaylistState.isInCombat
    MusicManager.activePlaydeck = PlaylistState.isInCombat and MusicManager.battlePlaylists or
        MusicManager.explorePlaylists
    PlaylistRules.setCombatTargetCacheKey(cacheKey)
end

---@param actor openmw.LObject
---@param targets GameObject[]
local function onTargetsChanged(actor, targets)
    if IsDead(gameSelf) then return end

    if next(targets) then
        local targetsPlayer = false
        for i = 1, #targets do
            if targets[i].id == gameSelf.id then
                targetsPlayer = true
                break
            end
        end

        combatTargets[actor.id] = actor
        playerTargetedActors[actor.id] = targetsPlayer
    else
        combatTargets[actor.id] = nil
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

---@class CombatState
local CombatState = {
    onHit = onHit,
    onTargetsChanged = onTargetsChanged,
    recomputeState = recomputeState,
}

---@param musicSettings S3maphoreCoreSettings
---@param playlistRules PlaylistRules
---@param musicManager MusicManager
---@param playlistState PlaylistState
---@return CombatState
return function(musicSettings, playlistRules, musicManager, playlistState)
    MusicManager, MusicSettings, PlaylistRules, PlaylistState =
        assert(musicManager),
        assert(musicSettings),
        assert(playlistRules),
        assert(playlistState)

    combatTargets = PlaylistState.combatTargets

    return CombatState
end
