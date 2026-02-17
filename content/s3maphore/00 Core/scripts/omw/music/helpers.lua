local isOpenMW, debug = pcall(require, 'openmw.debug')
local storage, vfs, playlistsSection, musicSettings

if isOpenMW then
    storage = require('openmw.storage')
    vfs = require('openmw.vfs')

    playlistsSection = storage.playerSection('S3MusicPlaylistsTrackOrder')
    playlistsSection:setLifeTime(storage.LIFE_TIME.GameSession)
    musicSettings = storage.playerSection('SettingsS3Music')
else
    playlistsSection = {}
    musicSettings = require('s3maphore.mcm').get('SettingsS3Music')
end

---@type S3maphoreStaticStrings
local Strings

local function deepToString(val, level, prefix)
    level = (level or 1) - 1

    local ok, iter, t = pcall(function() return pairs(val) end)
    if level < 0 or not ok then
        return tostring(val)
    end

    local newPrefix = prefix .. '  '
    local strs = { tostring(val) .. ' {\n' }

    for k, v in iter, t do
        strs[#strs + 1] = newPrefix .. tostring(k) .. ' = ' .. deepToString(v, level, newPrefix) .. ',\n'
    end

    strs[#strs + 1] = prefix .. '}'
    return table.concat(strs)
end

---@param ... any
local function debugLog(...)
    if isOpenMW then
        if not musicSettings:get('DebugEnable') then return end
    else
        if not musicSettings['DebugEnable'] then return end
    end

    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    local msg = table.concat(args, " ")
    print(
        Strings.LogFormatStr:format(msg)
    )
end

local pathsMatching = isOpenMW and vfs.pathsWithPrefix or lfs.walkdir
local fileExists = isOpenMW and vfs.fileExists or lfs.fileexists

local function getTracksFromDirectory(path, exclusions)
    local result = {}

    if not exclusions.tracks then exclusions.tracks = {} end
    if not exclusions.playlists then exclusions.playlists = {} end

    table.insert(exclusions.tracks, '.*/.gitkeep$')

    for fileName in pathsMatching(path) do
        --- Playlists must have a particular starting prefix in order to be excluded
        for _, playlistName in ipairs(exclusions.playlists) do
            playlistName = 'music/' .. playlistName:lower()
            if fileName:sub(1, #playlistName) == playlistName then goto TRACKEXCLUDED end
        end

        -- Whereas specific track names can match more loosely, although it is recommended to try to macth the path as closely as possible
        for _, trackName in ipairs(exclusions.tracks) do
            trackName = 'music/' .. trackName:lower()
            if fileName:match(trackName) then goto TRACKEXCLUDED end
        end

        table.insert(result, fileName)

        ::TRACKEXCLUDED::
    end

    return result
end

local function getPlaylistFilePaths()
    local result = {}
    for fileName in pathsMatching('playlists/') do
        if fileName:find('%.lua$') then
            table.insert(result, fileName)
        end
    end

    return result
end

local PlaylistPriority = isOpenMW and require('doc.playlistPriority') or require('playlistPriority')

---@param playlist S3maphorePlaylist
local function initMissingPlaylistFields(playlist, INTERRUPT)
    if playlist.id == nil or playlist.priority == nil then
        error(Strings.InvalidPlaylistFields)
    end

    if playlist.tracks == nil then
        playlist.tracks = getTracksFromDirectory(
            ("music/%s/"):format(playlist.id),
            playlist.exclusions or {}
        )
    end

    if playlist.active == nil then
        playlist.active = true
    end

    if playlist.randomize == nil then
        playlist.randomize = false
    end

    if playlist.cycleTracks == nil then
        playlist.cycleTracks = true
    end

    if playlist.playOneTrack == nil then
        playlist.playOneTrack = false
    end

    if playlist.interruptMode == nil then
        if playlist.priority <= PlaylistPriority.Special then
            playlist.interruptMode = INTERRUPT.Never
        elseif playlist.priority <= PlaylistPriority.BattleVanilla then
            playlist.interruptMode = INTERRUPT.Other
        elseif playlist.priority <= PlaylistPriority.Explore then
            playlist.interruptMode = INTERRUPT.Me
        else
            debugLog(
                Strings.CantAutoAssignInterruptModeStr:format(playlist.priority, playlist.id)
            )
        end
    end
end

local function shuffle(data)
    for i = #data, 1, -1 do
        local j = math.random(i)
        data[i], data[j] = data[j], data[i]
    end
    return data
end

local function initTracksOrder(tracks, randomize)
    local tracksOrder = {}

    for i = #tracks, 1, -1 do
        if not fileExists(tracks[i]) then
            table.remove(tracks, i)
        end
    end

    for i in ipairs(tracks) do
        tracksOrder[i] = i
    end

    if randomize then
        shuffle(tracksOrder)
    end

    return tracksOrder
end

local function isPlaylistActive(playlist)
    return playlist.active and next(playlist.tracks) ~= nil
end

local function OMWGetStoredTracksOrder()
    -- We need a writeable playlists table here.
    return playlistsSection:asTable()
end

local function MWSEGetStoredTracksOrder()
    return playlistsSection
end

local function OMWSetStoredTracksOrder(playlistId, playlistTracksOrder)
    playlistsSection:set(playlistId, playlistTracksOrder)
end

local function MWSESetStoredTracksOrder(playlistId, playlistTracksOrder)
    playlistsSection[playlistId] = playlistTracksOrder
end

local function OMWIsInCombat(fightingActors)
    return next(fightingActors) ~= nil and debug.isAIEnabled()
end

local function MWSEIsInCombat(fightingActors)
    return next(fightingActors) ~= nil and not tes3.worldController.menuController.aiDisabled
end

---@param playlists S3maphorePlaylist[]
---@param playback Playback
---@return S3maphorePlaylist|nil
local function getActivePlaylistByPriority(playlists, playback)
    local newPlaylist = nil

    for _, playlist in pairs(playlists) do
        if isPlaylistActive(playlist) then
            -- a new playlist hasn't yet been selected
            if newPlaylist == nil

                -- the one found in this iteration has a higher priority
                or playlist.priority < newPlaylist.priority
                -- the one found in this iteration has the same priority but was registered later
                or (playlist.priority == newPlaylist.priority and playlist.registrationOrder > newPlaylist.registrationOrder) then
                -- Allow playing the playlist if its valid callback passes
                if playlist.priority ~= PlaylistPriority.Never and playlist.isValidCallback(playback) then
                    newPlaylist = playlist
                end
            end
        end
    end

    return newPlaylist
end

local functions = {
    debugLog = debugLog,
    deepToString = deepToString,
    getActivePlaylistByPriority = getActivePlaylistByPriority,
    getPlaylistFilePaths = getPlaylistFilePaths,
    getStoredTracksOrder = isOpenMW and OMWGetStoredTracksOrder or MWSEGetStoredTracksOrder,
    getTracksFromDirectory = getTracksFromDirectory,
    initMissingPlaylistFields = initMissingPlaylistFields,
    initTracksOrder = initTracksOrder,
    isInCombat = isOpenMW and OMWIsInCombat or MWSEIsInCombat,
    isPlaylistActive = isPlaylistActive,
    setStoredTracksOrder = isOpenMW and OMWSetStoredTracksOrder or MWSESetStoredTracksOrder,
}

---@param staticStrings S3maphoreStaticStrings
return function(staticStrings)
    assert(staticStrings)
    Strings = staticStrings

    return functions
end
