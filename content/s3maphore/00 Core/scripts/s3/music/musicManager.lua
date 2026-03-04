local activePlaylistSettings, ambient, core, gameSelf, vfs

local musicUtil = require 'scripts.s3.music.util'

---@type table<string, function>
local L10nCache = {}

local IsOpenMW = require 'scripts.s3.isOpenMW'
local MusicBanner = require 'scripts.s3.music.banner'
local MusicSettings = require 'scripts.s3.music.musicSettings'

-- These are both still api-specific
local PlaylistFileList = musicUtil.getPlaylistFilePaths()

local PlaylistState = require 'scripts.s3.music.playlistState'
local SilenceManager = require 'scripts.s3.music.silenceManager'

---@class MusicManager
---@field Rules PlaylistRules
---@field STATE StateChangeReasons
---@field TIME_MAP TimeMap
---@field INTERRUPT InterruptModes
---@field currentPlaylist S3maphorePlaylist?
---@field currentTrack string?
---@field forceSkip boolean
---@field playlistTracksOrder table<string, string[]>
---@field registrationOrder integer
---@field registeredPlaylists S3maphorePlaylist[]
local MusicManager = {
  STATE = require 'scripts.s3.music.enum.stateChangeReason',
  TIME_MAP = require 'scripts.s3.music.enum.timeMap',
  INTERRUPT = require 'scripts.s3.music.enum.interruptMode',
  currentPlaylist = nil,
  currentTrack = nil,
  forceSkip = false,
  playlistsTracksOrder = musicUtil.getStoredTracksOrder(),
  registrationOrder = 0,
  registeredPlaylists = {},
}

if IsOpenMW then
  local async = require 'openmw.async'
  local storage = require 'openmw.storage'

  ambient = require 'openmw.ambient'
  core = require 'openmw.core'
  gameSelf = require 'openmw.self'
  vfs = require 'openmw.vfs'

  local I = require 'openmw.interfaces'

  activePlaylistSettings = storage.playerSection 'S3maphoreActivePlaylistSettings'
  activePlaylistSettings:setLifeTime(storage.LIFE_TIME.GameSession)
  --- Catches changes to the hidden storage group managing playlist activation and sets the corresponding playlist's active state to match
  --- In other words, this is the bit that responds to changes from the settings menu
  activePlaylistSettings:subscribe(
    async:callback(
      function(_, key)
        if not key then return end
        local playlistAssignedState = activePlaylistSettings:get(key)
        local playlistName = key:gsub('Active$', '')

        if not I.S3maphore then return end

        local targetPlaylist = MusicManager.registeredPlaylists[playlistName]

        if not targetPlaylist then return end

        if targetPlaylist.active ~= playlistAssignedState then
          targetPlaylist.active = playlistAssignedState
        end
      end
    )
  )
else
end

---@param playlistId string
local function initPlaylistL10n(playlistId)
  if L10nCache[playlistId] then return true end

  local l10nContextName = ('S3maphoreTracks_%s'):format(playlistId:gsub('/', '_'))

  if not vfs.pathsWithPrefix('l10n/' .. l10nContextName)() then return end

  local ok, maybeTranslations = pcall(function() return core.l10n(l10nContextName) end)

  if ok then
    L10nCache[playlistId] = maybeTranslations
    musicUtil.debugLog('Cached translations for playlist', playlistId)
  end

  return ok
end

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function MusicManager.registerPlaylist(playlist)
  musicUtil.initMissingPlaylistFields(playlist, MusicManager.INTERRUPT)
  initPlaylistL10n(playlist.id)

  local existingOrder = MusicManager.playlistsTracksOrder[playlist.id]

  if not existingOrder or next(existingOrder) == nil or math.max(unpack(existingOrder)) > #playlist.tracks then
    local fallback = playlist.fallback

    if fallback then
      local fallbackTracks = fallback.tracks

      if fallbackTracks and #fallbackTracks > 0 then
        for i = 1, #fallbackTracks do
          playlist.tracks[#playlist.tracks + 1] = 'music/' .. fallbackTracks[i]
        end
      end
    end

    local newPlaylistOrder = musicUtil.initTracksOrder(playlist.tracks, playlist.randomize)
    MusicManager.playlistsTracksOrder[playlist.id] = newPlaylistOrder
    musicUtil.setStoredTracksOrder(playlist.id, newPlaylistOrder)
  else
    MusicManager.playlistsTracksOrder[playlist.id] = existingOrder
  end

  playlist.registrationOrder = MusicManager.registrationOrder
  if MusicManager.registeredPlaylists[playlist.id] == nil then
    MusicManager.registrationOrder = MusicManager.registrationOrder + 1
  end

  MusicManager.registeredPlaylists[playlist.id] = playlist

  local storedState = next(playlist.tracks) == nil and -1 or playlist.active

  local playlistActiveKey = playlist.id .. 'Active'

  if activePlaylistSettings:get(playlistActiveKey) ~= nil then
    musicUtil.debugLog('loaded playlist state from settings:', playlist.id)

    playlist.active = activePlaylistSettings:get(playlistActiveKey)
  else
    musicUtil.debugLog('stored playlist state in settings:', playlist.id, storedState)

    activePlaylistSettings:set(playlistActiveKey, storedState)
  end
end

--- Decides whether or not a playlist will be used at all, regardless of whether its context is valid.
--- Typically should be used to forcefully disable a playlist, as they default to active.
--- May also be used to reactivate a playlist that was deactivated by a script, or was inactive by default.
---@param id string the ID of the playlist to unregister
---@param state boolean whether or not the playlist should be active in the list of registered playlists
function MusicManager.setPlaylistActive(id, state)
  if id == nil then
    error("Playlist ID is nil")
  end

  local playlist = MusicManager.registeredPlaylists[id]
  if playlist then
    playlist.active = state
    activePlaylistSettings:set(playlist.id .. 'Active', playlist.active)
  else
    error(
      ("Playlist '%s' is not registered."):format(id)
    )
  end
end

--- Returns the path of the currently playing track
---@return string?
function MusicManager.getCurrentTrack()
  return MusicManager.currentTrack
end

--- Returns l10n-localized playlist and track names for the current playlist. If a localization for the track does not exist, return nil
---@return string? playlistName, string? trackName
function MusicManager.getCurrentTrackInfo()
  local currentPlaylist, currentTrack = MusicManager.currentPlaylist, MusicManager.currentTrack

  if not currentPlaylist or not currentTrack then return end

  local playlistId = currentPlaylist.id

  if not L10nCache[playlistId] then return end

  local trackName = L10nCache[playlistId](currentTrack)

  if trackName ~= currentTrack then
    musicUtil.debugLog(
      ('Found S3maphore track translation %s for track %s:'):format(trackName, currentTrack)
    )

    return L10nCache[playlistId](playlistId), trackName
  else
    musicUtil.debugLog(
      ('No translations found for track %s'):format(currentTrack)
    )
  end
end

--- Returns a read-only copy of the current playlist, or nil
---@return ReadOnlyTable? readOnlyPlaylist
function MusicManager.getCurrentPlaylist()
  if not MusicManager.currentPlaylist then return end

  return musicUtil.makeReadOnly(MusicManager.currentPlaylist)
end

--- Returns a read-only list of read-only playlist structs for introspection. To modify playlists in any way, use other functions.
function MusicManager.getRegisteredPlaylists()
  local readOnlyPlaylists = {}

  for k, v in pairs(MusicManager.registeredPlaylists) do
    readOnlyPlaylists[k] = musicUtil.makeStrictReadOnly(v)
  end

  return musicUtil.makeReadOnly(readOnlyPlaylists)
end

local ReadOnlyPlaylistFileList = musicUtil.makeStrictReadOnly(PlaylistFileList)
--- Returns a read-only array of all recognized playlist files (files with the .lua extension under the VFS directory, Playlists/ )
---@return ReadOnlyTable playlistFiles
function MusicManager.listPlaylistFiles()
  return ReadOnlyPlaylistFileList
end

--- Stops the currently playing track, if any.
--- The onFrame handler will naturally switch to the next track or playlist
function MusicManager.skipTrack()
  MusicManager.forceSkip = MusicManager.forceSkip or ambient.isMusicPlaying()
end

--- Tells whether or not music playback is completely disabled
---@return boolean canPlayMusic
function MusicManager.getEnabled()
  return MusicSettings.MusicEnabled
end

local ReadOnlyState = musicUtil.makeReadOnly(PlaylistState)
function MusicManager.getState()
  return ReadOnlyState
end

---@return number duration of current silence track
function MusicManager.silenceTime()
  return SilenceManager.time
end

---@param enabled boolean
function MusicManager.overrideMusicEnabled(enabled)
  if enabled == nil then enabled = not MusicSettings.MusicEnabled end

  MusicSettings.MusicEnabled = enabled
end

--- Returns a string listing all the currently registered playlists, mapped to their (descending) priority.
--- Mostly intended to be used via the `luap` console.
---@return string
function MusicManager.listPlaylistsByPriority()
  local sortedPlaylists = {}
  for _, playlist in pairs(MusicManager.registeredPlaylists) do
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

local specialTrackInfo = {
  tracks = { '' },
  trackChangeInfo = {
    playlistId = 'Special',
    trackName = '',
    reason = MusicManager.STATE.SpecialTrackPlaying,
  },
  trackOrder = { 1 },
}

---@param trackPath string VFS path of the track to play
---@param reason S3maphoreStateChangeReason
function MusicManager.playSpecialTrack(trackPath, reason)
  if not vfs.fileExists(trackPath) then
    return print(('Requested track %s does not exist!'):format(trackPath))
  end

  musicUtil.debugLog(
    ('playing special track: %s'):format(trackPath)
  )

  specialTrackInfo.tracks[1] = trackPath

  --- I guess it's not necessarily guaranteed anymore that the Special playlist exists!
  MusicManager.registeredPlaylists.Special.tracks = specialTrackInfo.tracks
  playlistsTracksOrder.Special = specialTrackInfo.trackOrder

  MusicManager.setPlaylistActive('Special', true)

  local fadeOut
  if MusicManager.currentPlaylist and MusicManager.currentPlaylist.fadeOut ~= nil then
    fadeOut = MusicManager.currentPlaylist.fadeOut
  else
    fadeOut = MusicSettings.FadeOutDuration
  end

  ambient.streamMusic(trackPath, fadeOut)

  specialTrackInfo.trackChangeInfo.trackName = trackPath
  specialTrackInfo.trackChangeInfo.reason = reason or MusicManager.STATE.SpecialTrackPlaying

  gameSelf:sendEvent('S3maphoreTrackChanged', specialTrackInfo.trackChangeInfo)
end

---@return TimeOfDay
local function MWSEPlaylistTimeOfDay()
  local dayPortion = math.floor(tes3.worldController.hour.value / 6)
  return MusicManager.TIME_MAP[dayPortion]
end

---@return TimeOfDay
local function OMWPlaylistTimeOfDay()
  local dayPortion = math.floor(core.getGameTime() / 3600 % 24 / 6)
  return MusicManager.TIME_MAP[dayPortion]
end

function MusicManager.updateBanner()
  local playlist, track = MusicManager.getCurrentTrackInfo()

  if playlist and track and MusicSettings.BannerEnabled then
    MusicBanner.layout.props.visible = true
    MusicBanner.layout.content[1].props.text = ('%s\n\n%s'):format(playlist, track)
  else
    MusicBanner.layout.props.visible = false
  end

  MusicBanner:update()
end

MusicManager.playlistTimeOfDay = IsOpenMW and OMWPlaylistTimeOfDay or MWSEPlaylistTimeOfDay

return MusicManager
