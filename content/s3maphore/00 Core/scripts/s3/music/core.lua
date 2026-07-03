---@module 'doc.s3maphoreTypes'
---@omw-context player

local ambient                                                    = require 'openmw.ambient'
local async                                                      = require 'openmw.async'
local core                                                       = require 'openmw.core'
local input                                                      = require 'openmw.input'
local nearby                                                     = require 'openmw.nearby'
local self                                                       = require 'openmw.self'
local storage                                                    = require 'openmw.storage'
local types                                                      = require 'openmw.types'

local MusicManager                                               = require 'scripts.s3.music.musicManager'
local MusicSettings                                              = require 'scripts.s3.music.musicSettings'

---@type S3maphorePlaylistEnv
local PlaylistEnv
---@type function?
local PlaylistLoader                                             = require 'scripts.s3.music.playlistLoader'
---@type PlaylistRules
local PlaylistRules
---@type PlaylistState
local PlaylistState

local SilenceManager                                             = require 'scripts.s3.music.silenceManager'
local Strings                                                    = require 'scripts.s3.music.staticStrings'

local activePlaylistSettings                                     = storage.playerSection 'S3maphoreActivePlaylistSettings'
local musicUtil                                                  = require 'scripts.s3.music.util'

local NullFunction                                               = require 'scripts.s3.nullFunction'

local error, next, pairs, Random, Remove, tostring, TableSort    =
    error, next, pairs, math.random, table.remove, tostring, table.sort

local StrFormat, StrLower                                        = string.format, string.lower

local AIFight, IsDead, IsNPC, IsSoundEnabled, SendEvent          =
    types.Actor.stats.ai.fight, types.Actor.isDead, types.NPC.objectIsInstance, core.sound.isEnabled, self.sendEvent

---@type fun(dt: number)
local currentUpdateHandler

local handlePlayback, updateActorChain, resolvePlaylist          = NullFunction, NullFunction, NullFunction

local desiredPlaylist, resolverDirty, didTransition, wasExterior = nil, false, false, false

local CachedCellGrid                                             = { x = 0, y = 0, }

---@type QueuedEvent
local queuedEvent                                                = { name = '', data = {} }

local NPCFightThreshold                                          = 90
local CreatureFightThreshold                                     = 83

local Actors                                                     = nearby.actors
local BATCH_SIZE                                                 = 4
local chainPosition                                              = 2

local function checkSilenceManager()
    if not SilenceManager:silenceActive() then
        currentUpdateHandler = handlePlayback
    end
end
local function onSoundEnabledChanged()
    if not IsSoundEnabled() then return end

    currentUpdateHandler = checkSilenceManager
end

local function realUpdateActorChain()
    for _ = 1, BATCH_SIZE do
        local actor = Actors[chainPosition]
        if not actor then
            chainPosition = 2
            actor = Actors[chainPosition]
            if not actor then break end
        end
        SendEvent(actor, 'S3maphoreCheckCombat')
        chainPosition = chainPosition + 1
    end
end

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
    PlaylistState.playlistTimeOfDay = MusicManager.playlistTimeOfDay()

    PlaylistState.isUnderwater = PlaylistState.cellHasWater
        and self.type.isSwimming(self)
        and
        self.position.z + self:getBoundingBox().halfSize.z * 2 <
        PlaylistState.cellWaterLevel -- - 100 -- Hardcoded value for now, but, PLEASE make this a s3tting later
end

local function checkTimeOfDay()
    local newTOD = MusicManager.playlistTimeOfDay()

    if newTOD == PlaylistState.playlistTimeOfDay then return end

    PlaylistState.playlistTimeOfDay = newTOD
    queuedEvent.name = 'S3maphoreTODChanged'
end

local function realResolvePlaylist()
    updatePlaylistState()
    local newPlaylist = musicUtil.getActivePlaylistByPriority(
        MusicManager.specialPlaylists,
        PlaylistEnv.Playback,
        MusicManager.activePlaydeck
    )

    if newPlaylist == desiredPlaylist then return end
    desiredPlaylist = newPlaylist
    resolverDirty = true
end

---@type fun(_: number)
currentUpdateHandler = function(_)
    if not PlaylistLoader then error('Playlist loader not found during initialization!') end

    ---@type S3maphorePlaylistEnv?
    local playlistEnv = PlaylistLoader()

    if playlistEnv then
        PlaylistEnv = playlistEnv
        PlaylistState, PlaylistRules = PlaylistEnv.Playback.state, PlaylistEnv.Playback.rules
    else
        return
    end

    PlaylistLoader = nil
    updateActorChain = realUpdateActorChain
    resolvePlaylist = realResolvePlaylist

    local function priorityThenRegistration(a, b)
        return a.priority < b.priority
            or (a.priority == b.priority and a.registrationOrder > b.registrationOrder)
    end
    TableSort(MusicManager.explorePlaylists, priorityThenRegistration)
    TableSort(MusicManager.battlePlaylists, priorityThenRegistration)
    TableSort(MusicManager.specialPlaylists, priorityThenRegistration)

    resolvePlaylist()

    core.sendGlobalEvent('S3maphoreInitializationComplete', self.id)
    currentUpdateHandler = NullFunction
end

---@type S3maphoreStateChangeEventData
local TrackChangeData = {
    fadeOut = MusicSettings.FadeOutDuration,
    playlistId = '',
    reason = MusicManager.STATE.TrackChanged,
    trackName = '',
}
local function clearQueuedData()
    for key in next, queuedEvent.data do queuedEvent.data[key] = nil end
end

storage.playerSection('SettingsS3Music'):subscribe(
    async:callback(
        function(_, key)
            if key == 'BannerEnabled' then
                MusicManager.updateBanner()
            elseif key == 'MusicEnabled' then
                if MusicSettings.DebugEnable then
                    musicUtil.debugLog('Music state changed to', MusicSettings.MusicEnabled)
                end

                MusicManager.forceSkip = false
                queuedEvent.name = nil
                clearQueuedData()

                if MusicSettings.MusicEnabled then
                    currentUpdateHandler = onSoundEnabledChanged
                else
                    currentUpdateHandler = NullFunction

                    if ambient.isMusicPlaying() then
                        ambient.stopMusic()
                        MusicManager.currentPlaylist = nil
                        MusicManager.currentTrack = nil

                        queuedEvent.data.reason = MusicManager.STATE.Disabled
                        SendEvent(self, 'S3maphoreMusicStopped', queuedEvent.data)
                    end
                end
            end
        end
    )
)
local function updateCellHasCombatTargets()
    local nearbyCombatTargets = false

    -- Player is always at index 1, so if we start at 2
    -- We can skip the identity check
    for i = 2, #Actors do
        local actor = Actors[i]

        local fightStat = AIFight(actor)
        ---@cast fightStat openmw.types.AIStat

        local fightLimit = IsNPC(actor) and NPCFightThreshold or CreatureFightThreshold

        if fightStat.modified >= fightLimit and not IsDead(actor) then
            nearbyCombatTargets = true
            break
        end
    end

    PlaylistState.cellHasCombatTargets = nearbyCombatTargets
end

local CombatTargetCacheKey
---@param eventData CombatTargetChangedData
local function onCombatTargetsChanged(eventData)
    if IsDead(self) then return end

    if next(eventData.targets) then
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
            CombatTargetCacheKey = StrFormat('%s%s', CombatTargetCacheKey, targetId)
        end

        PlaylistRules.setCombatTargetCacheKey(CombatTargetCacheKey)
    else
        CombatTargetCacheKey = nil; PlaylistRules.setCombatTargetCacheKey()
    end

    MusicManager.activePlaydeck = PlaylistState.isInCombat and MusicManager.battlePlaylists or
        MusicManager.explorePlaylists
    resolvePlaylist()
end

local function playerDied()
    SendEvent(
        self,
        'S3maphoreSpecialTrack',
        { trackPath = 'music/special/mw_death.mp3', reason = MusicManager.STATE.Died, }
    )
    currentUpdateHandler = NullFunction
end

--- If a set of fallback playlists is present, attempt to use them during track selection
--- It should be noted that, for fallback playlists, their `active` parameter is ignored currently.
---@param newPlaylist S3maphorePlaylist
local function getPlaylistIdForTrackSelection(newPlaylist)
    local fallbackData = newPlaylist.fallback
    if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

    local useOtherPlaylist = Random() <= (fallbackData.playlistChance or 0.5)

    if not useOtherPlaylist then return newPlaylist.id end

    for i = #fallbackData.playlists, 1, -1 do
        local playlistId = fallbackData.playlists[i]
        if not MusicManager.registeredPlaylists[playlistId] then Remove(fallbackData.playlists, i) end
    end

    local numBackupPlaylists = #fallbackData.playlists
    local selectedPlaylistIndex = Random(numBackupPlaylists)
    local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]

    if not MusicManager.registeredPlaylists[selectedPlaylistId] then
        if selectedPlaylistId and MusicSettings.DebugEnable then
            musicUtil.debugLog(
                StrFormat(Strings.FallbackPlaylistDoesntExist, newPlaylist.id, selectedPlaylistId)
            )
        end

        return newPlaylist.id
    end

    return selectedPlaylistId
end

---@param playlistId string name of a playlist stored in registeredPlaylists table
local function selectTrackFromPlaylist(playlistId)
    local playlist = MusicManager.registeredPlaylists[playlistId]

    if not playlist then error(StrFormat(Strings.PlaylistNotRegistered, playlistId)) end

    local playlistOrder = MusicManager.playlistsTracksOrder[playlist.id]
    local nextTrackIndex = Remove(playlistOrder)

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
            local index = Random(2, #playlistOrder)
            playlistOrder[1], playlistOrder[index] = playlistOrder[index], playlistOrder[1]
        end

        MusicManager.playlistsTracksOrder[playlist.id] = playlistOrder
    end

    musicUtil.setStoredTracksOrder(playlist.id, playlistOrder)

    local trackPath = playlist.tracks[nextTrackIndex]

    if not trackPath then
        error(StrFormat(Strings.NoTrackPath, nextTrackIndex, playlist.id))
    end

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
            StrFormat(
                Strings.InterruptModeFallthrough,
                oldPlaylist.id,
                oldPlaylist.interruptMode,
                newPlaylist.id,
                newPlaylist.interruptMode
            )
        )
    end

    return false
end

handlePlayback = function(_)
    checkTimeOfDay()
    if queuedEvent.name then
        SendEvent(self, queuedEvent.name, queuedEvent.data)
        queuedEvent.name = nil
        clearQueuedData()
        return
    end

    local musicPlaying = ambient.isMusicPlaying()

    -- Resolver flagged a new playlist this tick
    if resolverDirty then
        resolverDirty = false

        if not desiredPlaylist then
            if musicPlaying then
                ambient.stopMusic()
                MusicManager.currentPlaylist = nil
                MusicManager.currentTrack = nil
            end

            clearQueuedData()
            queuedEvent.data.reason = MusicManager.STATE.NoPlaylist
            SendEvent(self, 'S3maphoreMusicStopped', queuedEvent.data)
            return
        end

        if desiredPlaylist ~= MusicManager.currentPlaylist
            and canSwitchPlaylist(MusicManager.currentPlaylist, desiredPlaylist) then
            MusicManager.forceSkip = true
        elseif desiredPlaylist ~= MusicManager.currentPlaylist and didTransition then
            local isExterior     = PlaylistState.cellIsExterior
            local friendlyEnter  = not PlaylistState.cellHasCombatTargets
            local hostileEnter   = PlaylistState.cellHasCombatTargets

            local overworldCross = wasExterior and isExterior
                and desiredPlaylist.priority <
                (MusicManager.currentPlaylist and MusicManager.currentPlaylist.priority or 1000)

            if (MusicSettings.ForcePlaylistChangeOnFriendlyExteriorTransition and friendlyEnter)
                or (MusicSettings.ForcePlaylistChangeOnHostileExteriorTransition and hostileEnter)
                or (MusicSettings.ForcePlaylistChangeOnOverworldTransition and overworldCross) then
                MusicManager.forceSkip = true
            end
        end
        didTransition = false
    end

    -- Need a new track?
    local pickNewTrack = not musicPlaying or MusicManager.forceSkip

    if not pickNewTrack then return end

    MusicManager.forceSkip = false

    local target = desiredPlaylist or MusicManager.currentPlaylist
    if not target then return end

    if target.deactivateAfterEnd then
        target.deactivateAfterEnd = nil
        target.active = false
        desiredPlaylist = nil
        MusicManager.currentPlaylist = nil
        MusicManager.currentTrack = nil
        resolvePlaylist()
        return
    end

    if target ~= MusicManager.currentPlaylist then
        switchPlaylist(target)
    else
        local nextTrack = selectTrackFromPlaylist(target.id)
        MusicManager.currentTrack = nextTrack
        MusicParams.fadeOut = target.fadeOut or MusicSettings.FadeOutDuration
    end

    for key in next, TrackChangeData do TrackChangeData[key] = nil end
    TrackChangeData.fadeOut = MusicParams.fadeOut
    TrackChangeData.playlistId = target.id
    TrackChangeData.trackName = MusicManager.currentTrack
    TrackChangeData.reason = MusicManager.STATE.TrackChanged
    SendEvent(self, 'S3maphoreTrackChanged', TrackChangeData)
end

MusicManager.addTrackChangedHandler(
---@param eventData S3maphoreStateChangeEventData
    function(eventData)
        if MusicSettings.DebugEnable then
            musicUtil.debugLog(
                StrFormat(Strings.TrackChanged, eventData.playlistId, eventData.trackName)
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
            resolvePlaylist()
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.F8 then
                if key.withShift then
                    SendEvent(self, 'S3maphoreToggleMusic')
                else
                    SendEvent(self, 'S3maphoreSkipTrack')
                end
            elseif key.code == input.KEY.F4 then
            end
        end,

        onUpdate = function(dt)
            updateActorChain()
            currentUpdateHandler(dt)
        end,

        onSave = function()
            local playlistStates = {}

            for playlistId, playlist in pairs(MusicManager.registeredPlaylists) do
                playlistStates[playlistId] = playlist.active
            end

            return {
                playlistStates = playlistStates,
            }
        end,

        onLoad = function(data)
            if not data then return end

            if data.playlistStates then
                for playlistId, playlistState in pairs(data.playlistStates) do
                    activePlaylistSettings:set(playlistId .. 'Active', playlistState)
                end
            end
        end
    },
    eventHandlers = {
        Died = playerDied,

        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,

        S3maphoreToggleMusic = function(enabled)
            MusicManager.overrideMusicEnabled(enabled)
            if MusicSettings.MusicEnabled then
                resolvePlaylist()
            end
        end,

        S3maphoreSkipTrack = function()
            currentUpdateHandler = onSoundEnabledChanged
            MusicManager.skipTrack()
            resolvePlaylist()
        end,

        S3maphoreSpecialTrack = function(eventData)
            MusicManager.playSpecialTrack(eventData.trackPath, eventData.reason)
        end,

        S3maphoreSetPlaylistActive = function(eventData)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(
                    StrFormat(Strings.ChangingPlaylist, eventData.playlist, eventData.state)
                )
            end

            MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
            resolvePlaylist()
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreMusicStopped = function(eventData)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(
                    StrFormat(Strings.MusicStopped, eventData.reason)
                )
            end

            MusicManager.updateBanner()
        end,

        ---@param cellChangeData S3maphoreCellChangeData
        S3maphoreCellChanged = function(cellChangeData)
            chainPosition = 2
            wasExterior = PlaylistState.cellIsExterior
            didTransition = true
            updateCellHasCombatTargets()

            PlaylistState.staticList = cellChangeData.staticList
            if cellChangeData.nearestRegion then PlaylistState.nearestRegion = cellChangeData.nearestRegion end

            local thisCell = self.cell
            ---@cast thisCell openmw.core.LCell

            local shouldUseName = thisCell.name ~= ''

            PlaylistState.cellHasWater = thisCell.hasWater
            PlaylistState.cellWaterLevel = thisCell.waterLevel
            PlaylistState.cellIsExterior = thisCell.isExterior or thisCell:hasTag 'QuasiExterior'
            PlaylistState.cellName = StrLower(shouldUseName and thisCell.name or thisCell.id)
            PlaylistState.cellId = thisCell.id

            if thisCell.isExterior then
                CachedCellGrid.x, CachedCellGrid.y = thisCell.gridX, thisCell.gridY
                PlaylistState.currentGrid = CachedCellGrid
            else
                PlaylistState.currentGrid = nil
            end

            resolvePlaylist()
            currentUpdateHandler = onSoundEnabledChanged
        end,

        S3maphoreWeatherChanged = function(weatherName)
            if MusicSettings.DebugEnable then
                musicUtil.debugLog(StrFormat(Strings.WeatherChanged, weatherName))
            end

            PlaylistState.weather = weatherName
            resolvePlaylist()
        end,

        S3maphoreClearTargetCache = function()
            if MusicSettings.DebugEnable then
                musicUtil.debugLog('clearing target cache for key', CombatTargetCacheKey)
            end

            PlaylistRules.clearGlobalCombatTargetCache()
        end,

        S3maphoreTODChanged = realResolvePlaylist,

        S3maphoreTrackChanged = MusicManager.callTrackChangedHandlers,
    }
}
