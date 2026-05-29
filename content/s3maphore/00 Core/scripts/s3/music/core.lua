---@module 'doc.s3maphoreTypes'

local isOpenMW = require 'scripts.s3.isOpenMW'

local ambient, async, core, input, nearby, self, storage, types

local MusicManager           = require 'scripts.s3.music.musicManager'
local MusicSettings          = require 'scripts.s3.music.musicSettings'
---@type function?
local PlaylistLoader         = require 'scripts.s3.music.playlistLoader'
local PlaylistState          = require 'scripts.s3.music.playlistState'
local SilenceManager         = require 'scripts.s3.music.silenceManager'
local Strings                = require 'scripts.s3.music.staticStrings'

local activePlaylistSettings, tableUtil
local musicUtil              = require 'scripts.s3.music.util'

if isOpenMW then
    ambient                  = require 'openmw.ambient'
    async                    = require 'openmw.async'
    core                     = require 'openmw.core'
    input                    = require 'openmw.input'
    nearby                   = require 'openmw.nearby'
    self                     = require 'openmw.self'
    storage                  = require 'openmw.storage'
    types                    = require 'openmw.types'

    activePlaylistSettings   = storage.playerSection 'S3maphoreActivePlaylistSettings'
    tableUtil                = require 'scripts.s3.table'
else
    activePlaylistSettings   = tes3.player.tempData['S3maphoreActivePlaylistSettings']
end

local nullFunction           = function() end

local CachedCellGrid         = { x = 0, y = 0, }

local NPCFightThreshold      = 90
local CreatureFightThreshold = 83

---@type fun(dt: number)
local currentUpdateHandler

local handlePlayback         = nullFunction

local function checkSilenceManager()
    if not SilenceManager:silenceActive() then
        currentUpdateHandler = handlePlayback
    end
end

local isSoundEnabled = isOpenMW and core.sound.isEnabled or function() return true end
local function onSoundEnabledChanged()
    if not isSoundEnabled() then return end

    currentUpdateHandler = checkSilenceManager
end

---@type fun(_: number)
currentUpdateHandler = function(_)
    assert(PlaylistLoader)
    if not PlaylistLoader() then return end

    PlaylistLoader = nil
    currentUpdateHandler = onSoundEnabledChanged
end

---@type S3maphoreStateChangeEventData
local TrackChangeData = {
    fadeOut = MusicSettings.FadeOutDuration,
    playlistId = '',
    reason = MusicManager.STATE.TrackChanged,
    trackName = '',
}

---@type QueuedEvent
local queuedEvent = { name = nil, data = {} }
local function clearQueuedData()
    local key = next(queuedEvent.data)
    while key do
        queuedEvent.data[key] = nil
        key = next(queuedEvent.data)
    end
end

local musicEnabledUpdate = function()
    if MusicSettings.DebugEnable then
        musicUtil.debugLog('Music state changed to', MusicSettings.MusicEnabled)
    end

    MusicManager.forceSkip = false
    queuedEvent.name = nil
    clearQueuedData()

    if MusicSettings.MusicEnabled then
        currentUpdateHandler = onSoundEnabledChanged
    else
        currentUpdateHandler = nullFunction

        if isOpenMW and ambient.isMusicPlaying() or tes3.worldController.audioController.isMusicPlaying then
            if isOpenMW then
                ambient.stopMusic()
            else
                tes3.worldController.audioController:pauseMusic()
            end
            MusicManager.currentPlaylist = nil
            MusicManager.currentTrack = nil

            queuedEvent.data.reason = MusicManager.STATE.Disabled
            if isOpenMW then self:sendEvent('S3maphoreMusicStopped', queuedEvent.data) else event.trigger('S3maphoreMusicStopped', queuedEvent.data) end
        end
    end
end

if isOpenMW then
    storage.playerSection('SettingsS3Music'):subscribe(
        async:callback(
            function(_, key)
                if key == 'BannerEnabled' then
                    MusicManager.updateBanner()
                elseif key == 'MusicEnabled' then
                    musicEnabledUpdate()
                end
            end
        )
    )
else
    --- @param e modConfigEntryClosedEventData
    local function modConfigEntryClosedCallback(e)
        MusicManager.updateBanner()

        musicEnabledUpdate()
    end
    event.register(tes3.event.modConfigEntryClosed, modConfigEntryClosedCallback)
end

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
    PlaylistState.playlistTimeOfDay = MusicManager.playlistTimeOfDay()

    if isOpenMW then
        PlaylistState.isUnderwater = PlaylistState.cellHasWater
            and self.type.isSwimming(self)
            and
            self.position.z + self:getBoundingBox().halfSize.z * 2 <
            PlaylistState.cellWaterLevel -- - 100 -- Hardcoded value for now, but, PLEASE make this a s3tting later
    else
        PlaylistState.isUnderwater = tes3.player.mobile.underwater
    end
end

---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules'
MusicManager.Rules = PlaylistRules

---@class Playback
---@field state PlaylistState
---@field rules PlaylistRules
local Playback = {
    rules = PlaylistRules,
    state = PlaylistState,
}

local ipairs = ipairs
local AIFight, isDead, isNPC, LocalActors, MyId
if isOpenMW then
    AIFight, isDead, isNPC, LocalActors, MyId = types.Actor.stats.ai.fight, types.Actor.isDead, types.NPC.objectIsInstance, nearby.actors, self.id
else
    --- There is a function called `tes3.findActorsInProximity` but it requires a range value which may not cover all objects when in an interior cell.
    LocalActors = {}
    --- @param cell tes3cell
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences{tes3.objectType.npc, tes3.objectType.creature} do
            table.insert(LocalActors, ref)
        end
    end
    -- LocalActors = tes3.findActorsInProximity{reference = tes3.player, range = math.huge}
end

local function updateCellHasCombatTargets()
    local nearbyCombatTargets = false

    --- @param actor GameObject|tes3reference
    for _, actor in ipairs(LocalActors) do
        if isOpenMW and actor.id ~= MyId or actor.mobile then
            local fightStat = isOpenMW and AIFight(actor) or actor.mobile.fight
            local fightLimit = (isOpenMW and isNPC(actor) or actor.objectType == tes3.objectType.npc) and NPCFightThreshold or CreatureFightThreshold

            if (isOpenMW and fightStat.modified or fightStat) >= fightLimit and (isOpenMW and not isDead(actor) or actor.mobile.health.current < 1) then
                nearbyCombatTargets = true
                break
            end
        end
    end

    PlaylistState.cellHasCombatTargets = nearbyCombatTargets
end

local CombatTargetCacheKey
---@param eventData CombatTargetChangedData
local function onCombatTargetsChanged(eventData)
    if eventData.actor == nil then return end

    if next(eventData.targets) ~= nil then
        PlaylistState.combatTargets[eventData.actor.id] = eventData.actor
    else
        PlaylistState.combatTargets[eventData.actor.id] = nil
        PlaylistRules.clearCombatCaches(eventData.actor.id)
    end

    updateCellHasCombatTargets()
    PlaylistState.isInCombat = MusicSettings.BattleEnabled and musicUtil.isInCombat(PlaylistState.combatTargets)
    PlaylistState.isExploring = MusicSettings.ExploreEnabled and not PlaylistState.isInCombat

    if PlaylistState.isInCombat then
        CombatTargetCacheKey = tostring(PlaylistState.combatTargets)

        for targetId, _ in pairs(PlaylistState.combatTargets) do
            CombatTargetCacheKey = ('%s%s'):format(CombatTargetCacheKey, targetId)
        end

        PlaylistRules.setCombatTargetCacheKey(CombatTargetCacheKey)
    else
        CombatTargetCacheKey = nil; PlaylistRules.setCombatTargetCacheKey(nil)
    end
end

--- @param e combatStartedEventData
local function onCombatTargetStart(e)
    if e.actor.reference ~= tes3.player then
        PlaylistState.combatTargets[e.actor.reference.id] = e.actor.reference

        updateCellHasCombatTargets()
        PlaylistState.isInCombat = MusicSettings.BattleEnabled and musicUtil.isInCombat(PlaylistState.combatTargets)
        PlaylistState.isExploring = MusicSettings.ExploreEnabled and not PlaylistState.isInCombat

        if PlaylistState.isInCombat then
            CombatTargetCacheKey = tostring(PlaylistState.combatTargets)

            for targetId, _ in pairs(PlaylistState.combatTargets) do
                CombatTargetCacheKey = ('%s%s'):format(CombatTargetCacheKey, targetId)
            end

            PlaylistRules.setCombatTargetCacheKey(CombatTargetCacheKey)
        end
    end
end

--- @param e combatStoppedEventData
local function onCombatTargetStop(e)
    if e.actor.reference ~= tes3.player then
        PlaylistState.combatTargets[e.actor.reference.id] = nil
        PlaylistRules.clearCombatCaches(e.actor.reference.id)

        updateCellHasCombatTargets()
        PlaylistState.isInCombat = MusicSettings.BattleEnabled and musicUtil.isInCombat(PlaylistState.combatTargets)
        PlaylistState.isExploring = MusicSettings.ExploreEnabled and not PlaylistState.isInCombat

        if not PlaylistState.isInCombat then
            CombatTargetCacheKey = nil
            PlaylistRules.setCombatTargetCacheKey(nil)
        end
    end
end

local function playerDiedOMW()
    MusicManager.playSpecialTrack('music/special/mw_death.mp3', MusicManager.STATE.Died)
    currentUpdateHandler = nullFunction
end

--- @param e damagedEventData
local function playerDiedMWSE(e)
    if (e.reference == tes3.player and e.killingBlow) then
        MusicManager.playSpecialTrack('music/special/mw_death.mp3', MusicManager.STATE.Died)
        currentUpdateHandler = nullFunction
    end
end

--- If a set of fallback playlists is present, attempt to use them during track selection
--- It should be noted that, for fallback playlists, their `active` parameter is ignored currently.
---@param newPlaylist S3maphorePlaylist
local function getPlaylistIdForTrackSelection(newPlaylist)
    local fallbackData = newPlaylist.fallback
    if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

    local useOtherPlaylist = math.random() <= (fallbackData.playlistChance or 0.5)

    if not useOtherPlaylist then return newPlaylist.id end

    for i = #fallbackData.playlists, 1, -1 do
        local playlistId = fallbackData.playlists[i]
        if not MusicManager.registeredPlaylists[playlistId] then table.remove(fallbackData.playlists, i) end
    end

    local numBackupPlaylists = #fallbackData.playlists
    local selectedPlaylistIndex = math.random(numBackupPlaylists)
    local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]

    if not MusicManager.registeredPlaylists[selectedPlaylistId] then
        if selectedPlaylistId and MusicSettings.DebugEnable then
            musicUtil.debugLog(
                Strings.FallbackPlaylistDoesntExist:format(newPlaylist.id, selectedPlaylistId)
            )
        end

        return newPlaylist.id
    end

    return selectedPlaylistId
end

---@param playlistId string name of a playlist stored in registeredPlaylists table
local function selectTrackFromPlaylist(playlistId)
    local playlist = MusicManager.registeredPlaylists[playlistId]

    assert(playlist, Strings.PlaylistNotRegistered:format(playlistId))

    local playlistOrder = MusicManager.playlistsTracksOrder[playlist.id]
    local nextTrackIndex = table.remove(playlistOrder)

    if nextTrackIndex == nil then
        error(Strings.NextTrackIndexNil)
    end

    -- If there are no tracks left, fill playlist again.
    if next(playlistOrder) == nil then
        playlistOrder = musicUtil.initTracksOrder(playlist.tracks, playlist.randomize)

        if not playlist.cycleTracks then
            playlist.deactivateAfterEnd = true
        end

        -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
        if playlist.randomize and #playlistOrder > 1 and playlistOrder[1] == nextTrackIndex then
            local index = math.random(2, #playlistOrder)
            playlistOrder[1], playlistOrder[index] = playlistOrder[index], playlistOrder[1]
        end

        MusicManager.playlistsTracksOrder[playlist.id] = playlistOrder
    end

    musicUtil.setStoredTracksOrder(playlist.id, playlistOrder)

    local trackPath = playlist.tracks[nextTrackIndex]

    assert(
        trackPath,
        Strings.NoTrackPath:format(nextTrackIndex, playlist.id)
    )

    return trackPath
end

local MusicParams = {
    fadeOut = MusicSettings.FadeOutDuration
}

---@param newPlaylist S3maphorePlaylist
local function switchPlaylist(newPlaylist)
    local nextPlaylist = getPlaylistIdForTrackSelection(newPlaylist)
    local nextTrack = selectTrackFromPlaylist(nextPlaylist)

    if newPlaylist.playOneTrack then
        newPlaylist.deactivateAfterEnd = true
    end

    if MusicManager.currentPlaylist and newPlaylist.id == MusicManager.currentPlaylist.id then
        SilenceManager:updateSilenceParams(newPlaylist)
    end

    MusicManager.currentPlaylist = newPlaylist
    MusicManager.currentTrack = nextTrack
    MusicParams.fadeOut = newPlaylist.fadeOut or MusicSettings.FadeOutDuration
end

---@param oldPlaylist S3maphorePlaylist?
---@param newPlaylist S3maphorePlaylist
---@return boolean canSwitchPlaylist
local function canSwitchPlaylist(oldPlaylist, newPlaylist)
    if not oldPlaylist then                                                                               --- No playlist, eg no music playing, means we can switch
        return true
    elseif oldPlaylist.interruptMode == MusicManager.INTERRUPT.Never then                                 --- But never interrupt a playlist that specifies it can't be interrupted
        return false
    elseif MusicSettings.ForceFinishTrack and oldPlaylist.interruptMode == newPlaylist.interruptMode then --- And also allow battle and explore playlist to flow nicely between themselves
        return false
    elseif oldPlaylist.interruptMode <= MusicManager.INTERRUPT.Other then                                 --- And otherwise, if the interrupt mode changes then allow the new playlist
        return true
    end

    if MusicSettings.DebugEnable then
        musicUtil.debugLog(
            Strings.InterruptModeFallthrough:format(
                oldPlaylist.id,
                oldPlaylist.interruptMode,
                newPlaylist.id,
                newPlaylist.interruptMode
            )
        )
    end

    return false
end

local didChangePlaylist = false

local inExteriorBeforeCellChange = PlaylistState.cellIsExterior

handlePlayback = function(_)
    if queuedEvent.name then
        if isOpenMW then
            self:sendEvent(queuedEvent.name, queuedEvent.data)
        else
            event.trigger(queuedEvent.name, queuedEvent.data)
        end
        queuedEvent.name = nil
        clearQueuedData()
        return
    end

    local musicPlaying = isOpenMW and ambient.isMusicPlaying() or tes3.worldController.audioController.isMusicPlaying

    updatePlaylistState()

    local newPlaylist = musicUtil.getActivePlaylistByPriority(MusicManager.registeredPlaylists, Playback)

    if not newPlaylist then
        if musicPlaying then
            if isOpenMW then
                ambient.stopMusic()
            else
                tes3.worldController.audioController:pauseMusic()
            end
            clearQueuedData()
            queuedEvent.name = 'S3maphoreMusicStopped'
            queuedEvent.data.reason = MusicManager.STATE.NoPlaylist

            if MusicManager.currentPlaylist ~= nil then
                MusicManager.currentPlaylist.deactivateAfterEnd = nil
            end

            MusicManager.currentPlaylist = nil
            MusicManager.currentTrack = nil
        end

        return
    end

    didChangePlaylist = didChangePlaylist or
        (
            MusicManager.currentPlaylist ~= nil
            and newPlaylist ~= nil
            and MusicManager.currentPlaylist ~= newPlaylist
        )

    local didTransition = inExteriorBeforeCellChange ~= PlaylistState.cellIsExterior

    MusicManager.forceSkip = MusicManager.forceSkip or didChangePlaylist
        and (
            didTransition and (
                (
                    (
                        MusicSettings.ForcePlaylistChangeOnFriendlyExteriorTransition
                        and not PlaylistState.cellHasCombatTargets
                    ) or (
                        MusicSettings.ForcePlaylistChangeOnHostileExteriorTransition
                        and PlaylistState.cellHasCombatTargets
                        and not (isOpenMW and self.cell.isExterior or tes3.player.cell.isOrBehavesAsExterior) -- Only do this skip type for *real* interiors
                    )
                )
            ) or (
                MusicSettings.ForcePlaylistChangeOnOverworldTransition and inExteriorBeforeCellChange and PlaylistState.cellIsExterior
                and (
                    newPlaylist.priority < (MusicManager.currentPlaylist and MusicManager.currentPlaylist.priority or 1000)
                )
            )
        )

    if didTransition then
        -- if forceSkip then
        if MusicSettings.DebugEnable then
            musicUtil.debugLog(
                Strings.PlaylistSkipFormatStr:format(
                    didChangePlaylist,
                    didTransition,
                    MusicSettings.ForcePlaylistChangeOnFriendlyExteriorTransition,
                    MusicSettings.ForcePlaylistChangeOnHostileExteriorTransition,
                    MusicSettings.ForcePlaylistChangeOnOverworldTransition,
                    PlaylistState.cellHasCombatTargets
                )
            )
        end

        didChangePlaylist = false
    end

    --- Update this particular state value as it could change before other less-relevant ones are updated, making
    --- skip detection *potentially* less accurate
    inExteriorBeforeCellChange = PlaylistState.cellIsExterior

    --- Only pick a new track, if no music is playing, or we've asked for a forced skip
    local pickNewTrack = not musicPlaying or MusicManager.forceSkip
    if musicPlaying and not MusicManager.forceSkip then
        --- In special cases, we can force a new track to be picked,
        --- if the playlist has changed, and we're allowed to do so (by the new playlist's interrupt mode overriding the old one)
        pickNewTrack = newPlaylist ~= MusicManager.currentPlaylist and
            canSwitchPlaylist(MusicManager.currentPlaylist, newPlaylist)
    end

    if not pickNewTrack then return end

    MusicManager.forceSkip = false
    didChangePlaylist = false

    if newPlaylist and newPlaylist.deactivateAfterEnd then
        newPlaylist.deactivateAfterEnd = nil
        newPlaylist.active = false
        return
    end

    switchPlaylist(newPlaylist)

    if isOpenMW then
        tableUtil.clear(TrackChangeData)
    else
        TrackChangeData = {}
    end
    TrackChangeData.fadeOut = MusicParams.fadeOut
    TrackChangeData.playlistId = newPlaylist and newPlaylist.id
    TrackChangeData.trackName = MusicManager.currentTrack
    TrackChangeData.reason = MusicManager.STATE.TrackChanged
    MusicManager.callTrackChangedHandlers(TrackChangeData)
end

MusicManager.addTrackChangedHandler(
---@param eventData S3maphoreStateChangeEventData
    function(eventData)
        if MusicSettings.DebugEnable then
            musicUtil.debugLog(
                Strings.TrackChanged:format(eventData.playlistId, eventData.trackName)
            )
        end

        MusicParams.fadeOut = eventData.fadeOut or MusicSettings.FadeOutDuration
        ambient.streamMusic(eventData.trackName, MusicParams)
        MusicManager.updateBanner()
    end
)

return {
    interfaceName = 'S3maphore',

    interface = MusicManager,

    engineHandlers = {

        onQuestUpdate = function()
            ---@diagnostic disable-next-line: invisible
            PlaylistRules.clearJournalCache()
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.F8 then
                if key.withShift then
                    self:sendEvent('S3maphoreToggleMusic')
                else
                    self:sendEvent('S3maphoreSkipTrack')
                end
            elseif key.code == input.KEY.F4 then
            end
        end,

        onUpdate = function(dt)
            if isOpenMW then
                currentUpdateHandler(dt)
            else
                currentUpdateHandler(dt.delta)
            end
        end,

        onSave = function()
            local playlistStates = {}

            for playlistId, playlist in pairs(MusicManager.registeredPlaylists) do
                playlistStates[playlistId] = playlist.active
            end

            if isOpenMW then
                return {
                    playlistStates = playlistStates,
                }
            else
                tes3.player.data.playlistStates = playlistStates
            end
        end,

        onLoad = function(data)
            if isOpenMW then
                if not data then return end

                for playlistId, playlistState in pairs(data.playlistStates or {}) do
                    activePlaylistSettings:set(playlistId .. 'Active', playlistState)
                end
            else
                if not tes3.player.data.playlistStates then return end
                
                for playlistId, playlistState in pairs(tes3.player.data.playlistStates or {}) do
                    activePlaylistSettings[playlistId .. 'Active'] = playlistState
                end
            end
        end
    },
    eventHandlers = {
        Died = isOpenMW and playerDiedOMW or playerDiedMWSE,

        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,

        S3maphoreToggleMusic = MusicManager.overrideMusicEnabled,

        S3maphoreSkipTrack = function()
            currentUpdateHandler = onSoundEnabledChanged
            MusicManager.skipTrack()
        end,

        S3maphoreSpecialTrack = MusicManager.playSpecialTrack,

        S3maphoreSetPlaylistActive = function(eventData)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(
                    Strings.ChangingPlaylist:format(eventData.playlist, eventData.state)
                )
            end

            MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreMusicStopped = function(eventData)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(
                    Strings.MusicStopped:format(eventData.reason)
                )
            end

            MusicManager.updateBanner()
        end,

        ---@param hasCombatTargets boolean
        S3maphoreCombatTargetsUpdated = function(hasCombatTargets)
            PlaylistState.cellHasCombatTargets = hasCombatTargets
        end,

        ---@param cellChangeData S3maphoreCellChangeData
        S3maphoreCellChanged = function(cellChangeData)
            updateCellHasCombatTargets()

            PlaylistState.staticList = cellChangeData.staticList
            if cellChangeData.nearestRegion then PlaylistState.nearestRegion = cellChangeData.nearestRegion end

            local thisCell = isOpenMW and self.cell or tes3.getPlayerCell()

            local shouldUseName = thisCell.name ~= ''

            PlaylistState.cellHasWater = thisCell.hasWater
            PlaylistState.cellWaterLevel = thisCell.waterLevel
            PlaylistState.cellIsExterior = isOpenMW and (thisCell.isExterior or thisCell:hasTag('QuasiExterior')) or (thisCell.isOrBehavesAsExterior)
            PlaylistState.cellName = (shouldUseName and thisCell.name or thisCell.id):lower()
            PlaylistState.cellId = thisCell.id

            if isOpenMW and thisCell.isExterior or not thisCell.isInterior then
                CachedCellGrid.x, CachedCellGrid.y = thisCell.gridX, thisCell.gridY
                PlaylistState.currentGrid = CachedCellGrid
            else
                PlaylistState.currentGrid = nil
            end

            --- Really we should check if the cell has changed, and then assign the currentFrameHandler
            --- accordingly, BUT, edge cases might happen, and also, we want to do that check anyway
            --- because if it is the same, we'll later do playlist resolution at this point in time
            if not PlaylistLoader then
                currentUpdateHandler = onSoundEnabledChanged
            end
        end,

        S3maphoreWeatherChanged = function(weatherName)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(
                    Strings.WeatherChanged:format(weatherName)
                )
            end

            PlaylistState.weather = weatherName
        end,

        S3maphoreClearTargetCache = function()
            if MusicSettings.DebugEnable then
                musicUtil.debugLog('clearing target cache for key', CombatTargetCacheKey)
            end
            PlaylistRules.clearGlobalCombatTargetCache()
        end,
    },

    mwse = {
        --- @param e keyEventData
        keyCallback = function(e)
            if e.keyCode == tes3.scanCode.F8 then
                if e.isShiftDown then
                    event.trigger('S3maphoreToggleMusic')
                else
                    event.trigger('S3maphoreSkipTrack')
                end
            elseif e.keyCode == tes3.scanCode.F4 then
                --- TODO: Remove?
            end
        end,

        combatStarted = onCombatTargetStart,

        combatStopped = onCombatTargetStop
    }
}
