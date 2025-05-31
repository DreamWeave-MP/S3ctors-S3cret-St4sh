local debug = require('openmw.debug')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local playlistsSection = storage.playerSection('S3MusicPlaylistsTrackOrder')
playlistsSection:setLifeTime(storage.LIFE_TIME.GameSession)

local PlaylistRules = require 'scripts.s3.music.playlistRules'

---@class Playback
---@field state PlaylistState
---@field rules PlaylistRules
local Playback = {
    rules = PlaylistRules
}

local function getTracksFromDirectory(path)
    local result = {}
    for fileName in vfs.pathsWithPrefix(path) do
        table.insert(result, fileName)
    end

    return result
end

local function getPlaylistFilePaths()
    local result = {}
    for fileName in vfs.pathsWithPrefix('playlists/') do
        if fileName:find('%.lua$') then
            table.insert(result, fileName)
        end
    end

    return result
end

local function initMissingPlaylistFields(playlist)
    if playlist.id == nil or playlist.priority == nil then
        error("Can not register playlist: 'id' and 'priority' are mandatory fields")
    end

    if playlist.tracks == nil then
        playlist.tracks = getTracksFromDirectory(string.format("music/%s/", playlist.id))
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
        if not vfs.fileExists(tracks[i]) then
            table.remove(tracks, i)
        end
    end

    for i, track in ipairs(tracks) do
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

local function getStoredTracksOrder()
    -- We need a writeable playlists table here.
    return playlistsSection:asTable()
end

local function setStoredTracksOrder(playlistId, playlistTracksOrder)
    playlistsSection:set(playlistId, playlistTracksOrder)
end

local function isInCombat(fightingActors)
    return next(fightingActors) ~= nil and debug.isAIEnabled()
end

---@param playlists S3maphorePlaylist[]
---@param playlistState PlaylistState
---@return S3maphorePlaylist|nil
local function getActivePlaylistByPriority(playlists, playlistState)
    local newPlaylist = nil
    PlaylistRules.state = playlistState
    Playback.state = playlistState

    for _, playlist in pairs(playlists) do
        if isPlaylistActive(playlist) then
            -- a new playlist hasn't yet been selected
            if newPlaylist == nil

                -- the one found in this iteration has a higher priority
                or playlist.priority < newPlaylist.priority

                -- the one found in this iteration has the same priority but was registered earlier
                or (playlist.priority == newPlaylist.priority and playlist.registrationOrder > newPlaylist.registrationOrder) then
                -- Allow playing the playlist if its valid callback passes, or the valid callback is not defined.

                if (playlist.isValidCallback == nil or playlist.isValidCallback(Playback)) then
                    newPlaylist = playlist
                end
            end
        end
    end

    return newPlaylist
end

local functions = {
    getActivePlaylistByPriority = getActivePlaylistByPriority,
    getPlaylistFilePaths = getPlaylistFilePaths,
    getStoredTracksOrder = getStoredTracksOrder,
    getTracksFromDirectory = getTracksFromDirectory,
    initMissingPlaylistFields = initMissingPlaylistFields,
    initTracksOrder = initTracksOrder,
    isInCombat = isInCombat,
    isPlaylistActive = isPlaylistActive,
    setStoredTracksOrder = setStoredTracksOrder
}

return functions
