local ambient = require('openmw.ambient')
local async = require 'openmw.async'
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

local MusicBanner = require 'scripts.s3.music.banner'
local TrackTranslations = core.l10n('SemaphoreTrackNames')

local musicSettings = storage.playerSection('SettingsS3Music')
local activePlaylistSettings = storage.playerSection('S3maphoreActivePlaylistSettings')
activePlaylistSettings:setLifeTime(storage.LIFE_TIME.GameSession)

activePlaylistSettings:subscribe(
    async:callback(
        function(_, key)
            if not key then return end
            local playlistAssignedState = activePlaylistSettings:get(key)
            local playlistName = key:gsub('Active$', '')

            if not I.S3maphore then return end
            local targetPlaylist = I.S3maphore.getRegisteredPlaylists()[playlistName]
            if not targetPlaylist then return end

            if targetPlaylist.active ~= playlistAssignedState then
                targetPlaylist.active = playlistAssignedState
            end
        end
    )
)

local helpers = require('scripts.omw.music.helpers')
local PlaylistFileList = helpers.getPlaylistFilePaths()

local registeredPlaylists = {}
local playlistsTracksOrder = helpers.getStoredTracksOrder()

---@alias FightingActors table<string, boolean>
local fightingActors = {}
local registrationOrder = 0

local currentPlaylist = nil

local battlePriority = 200
local explorePriority = 1000
---@type table<string, function>
local L10nCache = {}

---@param playlistId string
local function initPlaylistL10n(playlistId)
    if L10nCache[playlistId] then return true end

    local l10nContextName = ('S3maphoreTracks%s'):format(playlistId)

    local ok, maybeTranslations = pcall(function() return core.l10n(l10nContextName) end)

    if ok then
        L10nCache[playlistId] = maybeTranslations
        helpers.debugLog('Cached translations for playlist', playlistId)
    end

    return ok
end

---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules' (PlaylistState)


---@alias ValidPlaylistCallback fun(playback: Playback): boolean? a function that returns true if the playlist is valid for the current context. If not provided, the playlist will always be valid.

---@class S3maphorePlaylist
---@field id string name of the playlist
---@field priority number priority of the playlist, lower value means higher priority
---@field tracks string[]? list of tracks in the playlist. If not provided, tracks will be loaded from the music/ subdirectory with the same name as the playlist ID.
---@field randomize boolean? if true, tracks will be played in random order. Defaults to false.
---@field active boolean? if true, the playlist is active and will be played. Defaults to false
---@field cycleTracks boolean? if true, the playlist will cycle through tracks. Defaults to true
---@field playOneTrack boolean? if true, the playlist will play only one track and then deactivate. Defaults to false
---@field registrationOrder number? the order in which the playlist was registered, used for sorting playlists by priority. Do not provide in the playlist definition, it will be assigned automatically.
---@field deactivateAfterEnd boolean? if true, the playlist will be deactivated after the current track ends. Defaults to false.
---@field noInterrupt boolean? If true, playback is not interrupted when the playlist is invalid and will wait for the track to finish. Defaults to false
---@field isValidCallback ValidPlaylistCallback?

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function MusicManager.registerPlaylist(playlist)
    helpers.initMissingPlaylistFields(playlist)
    initPlaylistL10n(playlist.id)

    local existingOrder = playlistsTracksOrder[playlist.id]

    if not existingOrder or next(existingOrder) == nil or math.max(unpack(existingOrder)) > #playlist.tracks then
        local newPlaylistOrder = helpers.initTracksOrder(playlist.tracks, playlist.randomize)
        playlistsTracksOrder[playlist.id] = newPlaylistOrder
        helpers.setStoredTracksOrder(playlist.id, newPlaylistOrder)
    else
        playlistsTracksOrder[playlist.id] = existingOrder
    end

    if registeredPlaylists[playlist.id] == nil then
        playlist.registrationOrder = registrationOrder
        registrationOrder = registrationOrder + 1
    end

    registeredPlaylists[playlist.id] = playlist

    local storedState = next(playlist.tracks) == nil and -1 or playlist.active

    local playlistActiveKey = playlist.id .. 'Active'

    if activePlaylistSettings:get(playlistActiveKey) ~= nil then
        if musicSettings:get('DebugEnable') then
            print('loaded playlist state from settings:', playlist.id)
        end
        playlist.active = activePlaylistSettings:get(playlistActiveKey)
    else
        if musicSettings:get('DebugEnable') then
            print('stored playlist state in settings:', playlist.id, storedState)
        end
        activePlaylistSettings:set(playlist.id .. 'Active', storedState)
    end
end

--- Decided whether or not a playlist will be used at all, regardless of whether its context is valid.
--- Typically should be used to forcefully disable a playlist, as they default to active.
--- May also be used to reactivate a playlist that was deactivated by a script, or was inactive by default.
---@param id string the ID of the playlist to unregister
---@param state boolean whether or not the playlist should be active in the list of registered playlists
function MusicManager.setPlaylistActive(id, state)
    if id == nil then
        error("Playlist ID is nil")
    end

    local playlist = registeredPlaylists[id]
    if playlist then
        playlist.active = state
        activePlaylistSettings:set(playlist.id .. 'Active', playlist.active)
    else
        error(string.format("Playlist '%s' is not registered.", id))
    end
end

--- Returns the path of the currently playing track
---@return string?
function MusicManager.getCurrentTrack()
    return currentTrack
end

function MusicManager.getCurrentTrackInfo()
    if not currentPlaylist or not currentTrack then return end

    local playlistId = currentPlaylist.id

    if not L10nCache[playlistId] then return end

    local trackName = L10nCache[playlistId](currentTrack)

    if trackName ~= currentTrack then
        helpers.debugLog(
            ('Found S3maphore track translation %s for track %s:'):format(trackName, currentTrack)
        )

        return L10nCache[playlistId](playlistId), trackName
    else
        helpers.debugLog(
            ('No translations found for track %s'):format(currentTrack)
        )
    end
end

function MusicManager.getCurrentPlaylist()
    if not currentPlaylist then return end

    return util.makeReadOnly(currentPlaylist)
end

function MusicManager.getRegisteredPlaylists()
    return util.makeReadOnly(registeredPlaylists)
end

function MusicManager.listPlaylistFiles()
    return PlaylistFileList
end

--- Stops the currently playing track, if any.
--- The onFrame handler will naturally switch to the next track or playlist
function MusicManager.skipTrack()
    if ambient.isMusicPlaying() then
        ambient.stopMusic()
    end
end

function MusicManager.getEnabled()
    return musicSettings:get("MusicEnabled")
end

---@param enabled boolean
function MusicManager.overrideMusicEnabled(enabled)
    if enabled == nil then enabled = not musicSettings:get('MusicEnabled') end

    musicSettings:set("MusicEnabled", enabled)
end

function MusicManager.listPlaylistsByPriority()
    local sortedPlaylists = {}
    for _, playlist in pairs(registeredPlaylists) do
        table.insert(sortedPlaylists, playlist)
    end

    table.sort(sortedPlaylists, function(a, b)
        return a.priority < b.priority or (a.priority == b.priority and a.registrationOrder < b.registrationOrder)
    end)

    local playlistsByName = ''

    for _, v in pairs(sortedPlaylists) do
        playlistsByName = string.format('%s%s: %s\n', playlistsByName, v.id, v.priority)
    end

    return playlistsByName
end

---@param trackPath string VFS path of the track to play
---@param reason S3maphoreStateChangeReason
function MusicManager.playSpecialTrack(trackPath, reason)
    if not vfs.fileExists(trackPath) then
        return print(('Requested track %s does not exist!'):format(trackPath))
    end

    helpers.debugLog(
        ('playing special track: %s'):format(trackPath)
    )

    registeredPlaylists.Special.tracks = { trackPath }
    playlistsTracksOrder.Special = { 1 }

    MusicManager.setPlaylistActive('Special', true)

    local fadeOut = currentPlaylist and currentPlaylist.fadeOut ~= nil and currentPlaylist.fadeOut or 1.0

    ambient.streamMusic(trackPath, fadeOut)

    self:sendEvent('S3maphoreTrackChanged',
        {
            playlistId = 'Special',
            trackName = trackPath,
            reason = reason or MusicManager.TrackChangeReasons.SpecialTrackPlaying
        })
end

local function playlistCoroutineLoader()
    for _, file in ipairs(PlaylistFileList) do
        local ok, playlists = pcall(require, file:gsub("%.lua$", ""))
        if ok and type(playlists) == "table" then
            for _, playlist in ipairs(playlists) do
                MusicManager.registerPlaylist(playlist)
                coroutine.yield(playlist)
            end
        else
            print(string.format("Failed to load playlist file: %s", file))
        end
    end
end

-- Create the coroutine
local playlistLoaderCo = coroutine.create(playlistCoroutineLoader)

---@return boolean? canPlayback if true, loading has finished and playback can start
local function loadNextPlaylistStep()
    local status = coroutine.status(playlistLoaderCo)
    if status == 'dead' then return true end

    local ok, playlist = coroutine.resume(playlistLoaderCo)

    if ok and playlist then
        if musicSettings:get('DebugEnable') then
            print("Registered playlist:", playlist.id)
        end
    elseif coroutine.status(playlistLoaderCo) == "dead" then
        print("All playlists loaded. Ready to play music!")
        return true
    end
end

local function onCombatTargetsChanged(eventData)
    if eventData.actor == nil then return end

    if next(eventData.targets) ~= nil then
        fightingActors[eventData.actor.id] = true
    else
        fightingActors[eventData.actor.id] = nil
    end
end

local function playerDied()
    MusicManager.playSpecialTrack('music/special/mw_death.mp3', MusicManager.STATE.Died)
end

local function switchPlaylist(newPlaylist)
    local newPlaylistOrder = playlistsTracksOrder[newPlaylist.id]
    local nextTrackIndex = table.remove(newPlaylistOrder)

    if nextTrackIndex == nil then
        error("Can not fetch track: nextTrackIndex is nil")
    end

    -- If there are no tracks left, fill playlist again.
    if next(newPlaylistOrder) == nil then
        newPlaylistOrder = helpers.initTracksOrder(newPlaylist.tracks, newPlaylist.randomize)

        if not newPlaylist.cycleTracks then
            newPlaylist.deactivateAfterEnd = true
        end

        -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
        if newPlaylist.randomize and #newPlaylistOrder > 1 and newPlaylistOrder[1] == nextTrackIndex then
            local index = math.random(2, #newPlaylistOrder)
            newPlaylistOrder[1], newPlaylistOrder[index] = newPlaylistOrder[index], newPlaylistOrder[1]
        end

        playlistsTracksOrder[newPlaylist.id] = newPlaylistOrder
    end

    helpers.setStoredTracksOrder(newPlaylist.id, newPlaylistOrder)

    local trackPath = newPlaylist.tracks[nextTrackIndex]
    if trackPath == nil then
        error(string.format("Can not fetch track with index %s from playlist '%s'.", nextTrackIndex, newPlaylist.id))
    else
        currentTrack = trackPath
        ambient.streamMusic(trackPath, newPlaylist.fadeOut)

        if newPlaylist.playOneTrack then
            newPlaylist.deactivateAfterEnd = true
        end
    end

    currentPlaylist = newPlaylist
end

---@enum TimeMap
local playlistsToTime = {
    [0] = 'night',
    [1] = 'dawn',
    [2] = 'noon',
    [3] = 'dusk',
}

local function playlistTimeOfDay()
    local dayPortion = math.floor(core.getGameTime() / 3600 % 24 / 6)
    return playlistsToTime[dayPortion]
end

---@class PlaylistState
---@field self userdata the player actor
---@field playlistTimeOfDay TimeMap the time of day for the current playlist
---@field isInCombat boolean whether the player is in combat or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field combatTargets FightingActors a read-only table of combat targets, where keys are actor IDs and values are booleans indicating if the actor is currently fighting
---@field staticList userdata[] a read-only list of static objects in the cell, if the cell is not exterior. If the static list is not yet valid, is an empty table.
local PlaylistState = {}

---@return PlaylistState
local function getPlaylistState()
    local shouldUseName = self.cell.name ~= nil and self.cell.name ~= ''

    PlaylistState.self = self
    PlaylistState.playlistTimeOfDay = playlistTimeOfDay()
    PlaylistState.isInCombat = helpers.isInCombat(fightingActors)
    PlaylistState.cellIsExterior = self.cell.isExterior or self.cell:hasTag('QuasiExterior')
    PlaylistState.cellName = shouldUseName and self.cell.name:lower() or self.cell.id:lower()
    PlaylistState.staticList = self.cell.isExterior and nil or StaticList
    PlaylistState.combatTargets = util.makeReadOnly(fightingActors)

    return PlaylistState
end

---@class QueuedEvent
---@field name string the name of the event to send
---@field data any the data to send with the event

---@type QueuedEvent?
local queuedEvent

local function onFrame(dt)
    if queuedEvent then
        self:sendEvent(queuedEvent.name, queuedEvent.data)
        queuedEvent = nil
    end

    if not loadNextPlaylistStep() or not core.sound.isEnabled() then return end

    -- Do not allow to switch playlists when player is dead
    local musicPlaying = ambient.isMusicPlaying()

    if not MusicManager.getEnabled() and musicPlaying then
        ambient.stopMusic()
        currentPlaylist = nil
        currentTrack = nil
        queuedEvent = { name = 'S3maphoreMusicStopped', data = { reason = 'disabled' } }
        return
    end

    if types.Actor.isDead(self) and musicPlaying then return end

    local startTime = core.getRealTime()

    local newPlaylist = helpers.getActivePlaylistByPriority(registeredPlaylists, getPlaylistState())

    -- print('playlist lookup duration was:', (core.getRealTime() - startTime), 'seconds')

    if not newPlaylist then
        ambient.stopMusic()
        queuedEvent = { name = 'S3maphoreMusicStopped', data = { reason = 'no active playlist' } }

        if currentPlaylist ~= nil then
            currentPlaylist.deactivateAfterEnd = nil
        end

        currentPlaylist = nil
        currentTrack = nil
        return
    end

    -- Bail on switch if the current playlist is the same as the current one, or the current one cannot be interrupted.
    if musicPlaying
        and (
            (newPlaylist == currentPlaylist)
            or (currentPlaylist and currentPlaylist.noInterrupt)
        ) then
        return
    end

    if newPlaylist and newPlaylist.deactivateAfterEnd then
        newPlaylist.deactivateAfterEnd = nil
        newPlaylist.active = false
        return
    end

    local currentPlaylistId, queuedEventName = currentPlaylist and currentPlaylist.id or nil, 'S3maphoreTrackChanged'

    if currentPlaylistId ~= newPlaylist.id then
        queuedEventName = 'S3maphorePlaylistChanged'
    end

    switchPlaylist(newPlaylist)

    queuedEvent = { name = queuedEventName, data = { playlistId = newPlaylist.id, trackName = MusicManager.getCurrentTrackName() } }
end

MusicManager.registerPlaylist {
    id = "battle",
    priority = battlePriority,
    randomize = true,

    isValidCallback = function(playback)
        return (activePlaylistSettings:get("BattleActive") or true) and playback.state.isInCombat
    end,
}

MusicManager.registerPlaylist {
    id = "explore",
    priority = explorePriority,
    randomize = true,

    isValidCallback = function(playback)
        return (activePlaylistSettings:get("ExploreActive") or true) and not playback.state.isInCombat
    end,
}
MusicManager.registerPlaylist {
    id = 'Special',
    priority = 50,
    playOneTrack = true,
    noInterrupt = true,
    active = false,

    tracks = {},
}

return {
    interfaceName = 'S3maphore',
    interface = MusicManager,
    engineHandlers = {
        onFrame = onFrame,
        onTeleported = function()
            StaticList = {}
            core.sendGlobalEvent('S3maphoreStaticUpdate', self)
        end,
        onSave = function()
            local playlistStates = {}
            for playlistId, playlist in pairs(registeredPlaylists) do
                playlistStates[playlistId] = playlist.active
            end

            return {
                StaticList = StaticList,
                playlistStates = playlistStates,
            }
        end,
        onLoad = function(data)
            if not data then return end

            StaticList = data.StaticList or {}

            for playlistId, playlistState in pairs(data.playlistStates or {}) do
                activePlaylistSettings:set(playlistId .. 'Active', playlistState)
            end
        end
    },
    eventHandlers = {
        Died = playerDied,
        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
        S3maphoreToggleMusic = MusicManager.overrideMusicEnabled,
        S3maphoreSkipTrack = MusicManager.skipTrack,

        S3maphoreSpecialTrack = MusicManager.playSpecialTrack,
        S3maphoreSetPlaylistActive = function(eventData)
            if musicSettings:get('DebugEnable') then
                print(string.format('Setting playlist %s to %s', eventData.playlist, eventData.state))
            end
            MusicManager(eventData.playlist, eventData.state)
        end,
        S3maphoreMusicStopped = function(eventData)
            if musicSettings:get('DebugEnable') then
                print("Music stopped:", eventData.reason)
            end
        end,
        S3maphorePlaylistChanged = function(eventData)
            if musicSettings:get('DebugEnable') then
                print("Playlist changed:", eventData.playlistId, "Track:", eventData.trackName)
            end
        end,
        S3maphoreTrackChanged = function(eventData)
            if musicSettings:get('DebugEnable') then
                print("Track changed:", eventData.playlistId, "Track:", eventData.trackName)
            end

            local trackName = MusicManager.getCurrentTrack()
            print(TrackTranslations[trackName] or 'NOT FOUND')
            trackName = TrackTranslations[trackName] or trackName

            if trackName then
                MusicBanner.layout.props.visible = true
                MusicBanner.layout.content[1].props.text = trackName
            else
                MusicBanner.layout.props.visible = false
            end
            MusicBanner:update()
        end,
        S3maphoreStaticCollectionUpdated = function(staticList)
            StaticList = staticList
        end,
    }
}
