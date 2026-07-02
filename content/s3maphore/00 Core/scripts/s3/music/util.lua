---@omw-context player

local isOpenMW = require 'scripts.s3.isOpenMW'

---@type PlaylistPriority
local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphoreStaticStrings
local Strings = require 'scripts.s3.music.staticStrings'

local async, fileExists, isAIEnabled, musicSettings, pathsMatching, playlistsSection,
storage, storageGet, vfs

local error, getmetatable, next, pairs, pcall, rawget, rawset, setmetatable, type =
    error, getmetatable, next, pairs, pcall, rawget, rawset, setmetatable, type

local Random, print, StrFormat, StrLower, StrMatch, StrSub,
TableConcat, TableInsert, TableRemove, tostring =
    math.random, print, string.format, string.lower, string.match, string.sub,
    table.concat, table.insert, table.remove, tostring

local ReadOnlyMT = {
    __newindex = function(t)
        error(StrFormat('Write attempt to read-only table %s', t))
    end,
    __metatable = false,
}

local StrictReadOnlyMT = {
    {
        __index = function(inTable, key)
            local found = inTable[key]

            if found ~= nil then
                return found
            else
                error(StrFormat('Failed to locate key %s in table %s!', key, inTable), 2)
            end
        end,
        __newindex = function(inTable)
            error(StrFormat('Write attempt to read-only table %s', inTable))
        end,
        __metatable = false,
    }
}

if isOpenMW then
    async = require 'openmw.async'
    storage = require 'openmw.storage'
    vfs = require 'openmw.vfs'

    fileExists = vfs.fileExists
    isAIEnabled = require 'openmw.debug'.isAIEnabled
    musicSettings = storage.playerSection('SettingsS3Music')
    pathsMatching = vfs.pathsWithPrefix
    playlistsSection = storage.playerSection('S3MusicPlaylistsTrackOrder')
    playlistsSection:setLifeTime(storage.LIFE_TIME.GameSession)
    storageGet = musicSettings.get
end

---@param ... any
local function debugLog(...)
    if isOpenMW then
        if not storageGet(musicSettings, 'DebugEnable') then return end
    else
    end

    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end

    local msg = TableConcat(args, " ")

    print(StrFormat(Strings.LogFormatStr, msg))
end

---@param root table
---@return table outTable
local function deepCopy(root, copies)
    copies = copies or {}
    if copies[root] then return copies[root] end

    local new = {}
    copies[root] = new
    for k, v in pairs(root) do
        local key = type(k) == "table" and deepCopy(k, copies) or k
        local val = type(v) == "table" and deepCopy(v, copies) or v
        new[key] = val
    end

    return setmetatable(new, getmetatable(root))
end

local function deepToString(val, level, prefix)
    prefix = prefix or ''
    level = (level or 1) - 1

    local ok, iter, t = pcall(pairs, val)
    if level < 0 or not ok then
        return tostring(val)
    end

    local newPrefix = prefix .. '  '
    local strs = { tostring(val) .. ' {\n' }

    for k, v in iter, t do
        strs[#strs + 1] = newPrefix .. tostring(k) .. ' = ' .. deepToString(v, level, newPrefix) .. ',\n'
    end

    strs[#strs + 1] = prefix .. '}'
    return TableConcat(strs)
end

local function getPlaylistFilePaths()
    local result = {}
    for fileName in pathsMatching('playlists/') do
        if fileName:find('%.lua$') then
            TableInsert(result, fileName)
        end
    end

    return result
end

local function getTracksFromDirectory(path, exclusions)
    local result = {}

    for fileName in pathsMatching(path) do
        local includeTrack = StrMatch(fileName, '.*/.gitkeep$') == nil

        if includeTrack and exclusions then
            local excludedPlaylists, excludedTracks = exclusions.playlists, exclusions.tracks

            if excludedPlaylists then
                --- Playlists must have a particular starting prefix in order to be excluded
                for i = 1, #excludedPlaylists do
                    local playlistName = excludedPlaylists[i]
                    playlistName = 'music/' .. StrLower(playlistName)

                    if StrSub(fileName, 1, #playlistName) == playlistName then
                        includeTrack = false; break
                    end
                end
            end

            if excludedTracks and includeTrack then
                -- Whereas specific track names can match more loosely, although it is recommended to try to macth the path as closely as possible
                for i = 1, #exclusions.tracks do
                    local trackName = exclusions.tracks[i]
                    trackName = 'music/' .. StrLower(trackName)

                    if StrMatch(fileName, trackName) then
                        includeTrack = false; break
                    end
                end
            end
        end

        if includeTrack then TableInsert(result, fileName) end
    end

    return result
end

---@param playlist S3maphorePlaylist
local function initMissingPlaylistFields(playlist, INTERRUPT)
    if not playlist.id or not playlist.priority then
        error(Strings.InvalidPlaylistFields)
    end

    if not playlist.tracks then
        playlist.tracks = getTracksFromDirectory(
            ("music/%s/"):format(playlist.id),
            playlist.exclusions
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

    if not playlist.interruptMode then
        if playlist.priority <= PlaylistPriority.Special then
            playlist.interruptMode = INTERRUPT.Never
        elseif playlist.priority <= PlaylistPriority.BattleVanilla then
            playlist.interruptMode = INTERRUPT.Other
        elseif playlist.priority <= PlaylistPriority.Explore then
            playlist.interruptMode = INTERRUPT.Me
        else
            debugLog(
                StrFormat(Strings.CantAutoAssignInterruptModeStr, playlist.priority, playlist.id)
            )
        end
    end
end

local function initTracksOrder(tracks, randomize)
    local tracksOrder = {}

    for i = #tracks, 1, -1 do
        if not fileExists(tracks[i]) then
            TableRemove(tracks, i)
        end
    end

    for i = 1, #tracks do
        tracksOrder[i] = i
    end

    if randomize then
        --- This used to be the `shuffle` function but it annoyed me
        --- as it was an unnecessary call that wasn't part of the library and fucked up
        --- my alphabetization
        for i = #tracksOrder, 1, -1 do
            local j = Random(i)
            tracksOrder[i], tracksOrder[j] = tracksOrder[j], tracksOrder[i]
        end
    end

    return tracksOrder
end

---@param deck S3maphorePlaylist[]
---@param playback S3maphorePlayback
---@return S3maphorePlaylist|nil
local function firstActivePlaylist(deck, playback)
    for i = 1, #deck do
        local playlist = deck[i]
        if playlist.active and next(playlist.tracks) ~= nil and playlist.isValidCallback(playback) then
            return playlist
        end
    end
end

---@param specialPlaylists S3maphorePlaylist[]
---@param playback S3maphorePlayback
---@param activePlaydeck S3maphorePlaylist[] sorted deck for the current combat state
---@return S3maphorePlaylist|nil
local function getActivePlaylistByPriority(specialPlaylists, playback, activePlaydeck)
    return firstActivePlaylist(specialPlaylists, playback)
        or firstActivePlaylist(activePlaydeck, playback)
end

---@param groupName string
---@param mcmPath string?
---@param originalTable table?
---@return UpdatingSettingTable
local function getUpdatingSettingsTable(groupName, mcmPath, originalTable)
    local settingTable = originalTable or {}

    local settingGroup
    if isOpenMW then
        settingGroup = storage.playerSection(groupName)
    else
        assert(mcmPath)
        settingGroup = require(mcmPath).get(groupName)
    end

    local updateSettings
    if isOpenMW then
        updateSettings = function(_, updated)
            if updated then
                settingTable[updated] = settingGroup:get(updated)
            else
                for key, value in pairs(settingGroup:asTable()) do
                    rawset(settingTable, key, value)
                end
            end
        end
    else
        updateSettings = function(_, updated)
            if updated then
                settingTable[updated] = rawget(settingGroup, updated)
            else
                for key, value in pairs(settingGroup) do
                    rawset(settingTable, key, value)
                end
            end
        end
    end

    updateSettings()

    local newIndexFunction
    local shadowTable = {}

    if originalTable then
        for k, v in next, originalTable do
            rawset(originalTable, k, nil)
            rawset(shadowTable, k, v)
        end
    end

    if isOpenMW then
        settingGroup:subscribe(async:callback(updateSettings))

        newIndexFunction = function(_, k, v)
            if rawget(settingGroup:asTable(), k) ~= nil then
                settingGroup:set(k, v)
            else
                rawset(shadowTable, k, v)
            end
        end
    else
        ---@diagnostic disable-next-line: undefined-field
        table.subscribe(settingGroup, updateSettings)

        newIndexFunction = function(_, k, v)
            if rawget(settingGroup, k) ~= nil then
                rawset(settingGroup, k, v)
            else
                rawset(shadowTable, k, v)
            end
        end
    end

    return setmetatable({},
        {
            __index = function(_, k)
                local value = rawget(settingTable, k)
                if value ~= nil then return value end

                value = rawget(shadowTable, k)
                if value ~= nil then return value end
            end,
            __newindex = newIndexFunction,
        }
    )
end

--- Takes a table as input and returns a read-only one.
--- Commits seppuku if the input is not a table, so do be careful
---@param inTable table
---@param copy boolean? Whether to copy the table or make the original read-only
---@param strict boolean? Whether to make the table throw when indexing keys that don't exist
---@param visited table<table, table>?
---@return ReadOnlyTable
local function makeReadOnly(inTable, copy, strict, visited)
    if type(inTable) ~= "table" then
        error(("makeReadOnly: expected table, got %s"):format(type(inTable)), 2)
    end
    visited = visited or {}

    -- Return already processed result if seen
    if visited[inTable] then return visited[inTable] end

    local res
    if copy then
        res = {}
        visited[inTable] = res
        for k, v in pairs(inTable) do
            local newk = (type(k) == "table") and makeReadOnly(k, copy, strict, visited) or k
            local newv = (type(v) == "table") and makeReadOnly(v, copy, strict, visited) or v
            res[newk] = newv
        end
    else
        res = inTable
        visited[inTable] = res
        -- Process all values
        for _, v in pairs(inTable) do
            if type(v) == "table" then
                makeReadOnly(v, copy, strict, visited) -- modifies in place
            end
        end

        -- Process all table keys (must be done after values to avoid iteration issues)
        local tableKeys = {}
        for k in pairs(inTable) do
            if type(k) == "table" then
                tableKeys[#tableKeys + 1] = k
            end
        end

        for i = 1, #tableKeys do
            local tk = tableKeys[i]
            makeReadOnly(tk, copy, strict, visited)
        end
    end

    local MT = strict and StrictReadOnlyMT or ReadOnlyMT
    return setmetatable(res, MT)
end

local function OMWGetStoredTracksOrder()
    -- We need a writeable playlists table here.
    return playlistsSection:asTable()
end

local function OMWSetStoredTracksOrder(playlistId, playlistTracksOrder)
    playlistsSection:set(playlistId, playlistTracksOrder)
end

local function OMWIsInCombat(fightingActors)
    return next(fightingActors) ~= nil and isAIEnabled()
end

---@class S3maphoreHelperModule
local utilModule = {
    debugLog = debugLog,
    deepCopy = deepCopy,
    deepToString = deepToString,
    getActivePlaylistByPriority = getActivePlaylistByPriority,
    getPlaylistFilePaths = getPlaylistFilePaths,
    getStoredTracksOrder = isOpenMW and OMWGetStoredTracksOrder,
    getTracksFromDirectory = getTracksFromDirectory,
    getUpdatingSettingsTable = getUpdatingSettingsTable,
    initMissingPlaylistFields = initMissingPlaylistFields,
    initTracksOrder = initTracksOrder,
    isInCombat = isOpenMW and OMWIsInCombat,
    makeReadOnly = makeReadOnly,
    setStoredTracksOrder = isOpenMW and OMWSetStoredTracksOrder,
}

return utilModule
