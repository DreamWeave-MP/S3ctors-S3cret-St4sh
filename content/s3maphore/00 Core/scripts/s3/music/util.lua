local isOpenMW = require 'scripts.s3.isOpenMW'
local async, debug, fileExists, musicSettings, pathsMatching, playlistsSection, storage, vfs

---@type PlaylistPriority
local PlaylistPriority = require 'doc.playlistPriority'
---@type S3maphoreStaticStrings
local Strings = require 'scripts.s3.music.staticStrings'

local ReadOnlyMT = {
    __newindex = function(t)
        error(('Write attempt to read-only table %s'):format(t))
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
                error(
                    ('Failed to locate key %s in table %s!'):format(key, inTable),
                    2
                )
            end
        end,
        __newindex = function(inTable)
            error(('Write attempt to read-only table %s'):format(inTable))
        end,
        __metatable = false,
    }
}

if isOpenMW then
    async = require 'openmw.async'
    debug = require 'openmw.debug'
    storage = require 'openmw.storage'
    vfs = require 'openmw.vfs'

    fileExists = vfs.fileExists
    musicSettings = storage.playerSection('SettingsS3Music')
    pathsMatching = vfs.pathsWithPrefix
    playlistsSection = storage.playerSection('S3MusicPlaylistsTrackOrder')
    playlistsSection:setLifeTime(storage.LIFE_TIME.GameSession)
end

---@param ... any
local function debugLog(...)
    if isOpenMW then
        if not musicSettings:get('DebugEnable') then return end
    else
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

local function getPlaylistFilePaths()
    local result = {}
    for fileName in pathsMatching('playlists/') do
        if fileName:find('%.lua$') then
            table.insert(result, fileName)
        end
    end

    return result
end

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
        --- This used to be the `shuffle` function but it annoyed me
        --- as it was an unnecessary call that wasn't part of the library and fucked up
        --- my alphabetization
        for i = #tracksOrder, 1, -1 do
            local j = math.random(i)
            tracksOrder[i], tracksOrder[j] = tracksOrder[j], tracksOrder[i]
        end
    end

    return tracksOrder
end

local function isPlaylistActive(playlist)
    return playlist.active and next(playlist.tracks) ~= nil
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

        for _, tk in ipairs(tableKeys) do
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
    return next(fightingActors) ~= nil and debug.isAIEnabled()
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
    isPlaylistActive = isPlaylistActive,
    makeReadOnly = makeReadOnly,
    setStoredTracksOrder = isOpenMW and OMWSetStoredTracksOrder,
}

return utilModule
