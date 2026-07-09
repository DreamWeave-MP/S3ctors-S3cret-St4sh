---@omw-context player

local gameSelf = require 'openmw.self'
local activePlaylistSettings

--- FIXME: This isn't API-agnostic, but, I don't care ATM
local aux_util = require 'openmw_aux.util'

local IsOpenMW = require 'scripts.s3.isOpenMW'

local MetadataRegistry = require 'scripts.s3.music.musicMetadata'
local MusicBanner = require 'scripts.s3.music.banner'
local MusicSettings = require 'scripts.s3.music.musicSettings'
local PlaylistPriority = require 'doc.playlistPriority'
local PlaylistState = require 'scripts.s3.music.playlistState'
local SilenceManager = require 'scripts.s3.music.silenceManager'
local musicUtil = require 'scripts.s3.music.util'

--- Overkill, yes, but we're going to document making modifications to this file.
--- If someone who doesn't know what they're doing tweaks it, because we told them to,
--- and the mod breaks, guess whose fault that its for making flimsy code?
--- So, yes, unfortunately, for robustness we not only wish to pcall this file,
--- AND hardcode the default death track locally since we're about to import it, because if the import
--- fails we need a fallback and the mod should still work!
---
--- 👏
--- moddability
--- 👏
--- in
--- 👏
--- depth
--- 👏

local ok, DefaultDeathTrack = pcall(require, 'scripts.s3.music.defaultDeathTrack')

if not ok then
  print '[ S3MAPHORE ]: Failed loading default death track module, falling back to hardcoded literal path music/special/mw_death.mp3'
  DefaultDeathTrack = 'music/special/mw_death.mp3'
end

--- Initializes to the default death track at module scope, but,
--- overwritten by onLoad if any eventHandler/setDeathTrack call overwrote it
local DeathTrackPath = DefaultDeathTrack

local Floor, Insert, Max, StrFormat, TableSort, next, print, unpack =
  math.floor, table.insert, math.max, string.format, table.sort, next, print, unpack

local ReadOnlyPlaylistFileList =
  musicUtil.makeReadOnly(musicUtil.getPlaylistFilePaths(), false, false)

---@type TrackChangedHandler[]
local TrackChangeHandlers = {}

---@class MusicManager
---@field Rules PlaylistRules
---@field STATE StateChangeReasons
---@field TIME_MAP TimeMap
---@field INTERRUPT InterruptModes
---@field STATE_FLAGS StateChangedFlags
---@field currentPlaylist S3maphorePlaylist?
---@field currentTrack string?
---@field forceSkip boolean
---@field playlistMetadata S3maphoreMusicMetadataRegistry
---@field playlistTracksOrder table<string, string[]>
---@field registrationOrder integer
---@field registeredPlaylists table<string, S3maphorePlaylist>
---@field getDeathTrack fun(): string
---@field resetDeathTrack fun()
---@field setDeathTrack fun(path: string)
local MusicManager = {
  STATE = require 'scripts.s3.music.enum.stateChangeReason',
  TIME_MAP = require 'scripts.s3.music.enum.timeMap',
  INTERRUPT = require 'scripts.s3.music.enum.interruptMode',
  STATE_FLAGS = require 'scripts.s3.music.enum.stateChangedFlags',
  ---@param handler TrackChangedHandler
  addTrackChangedHandler = function(handler)
    TrackChangeHandlers[#TrackChangeHandlers + 1] = handler
  end,
  ---@param eventData S3maphorePlaybackChangeEventData
  callTrackChangedHandlers = function(eventData)
    aux_util.callEventHandlers(TrackChangeHandlers, eventData)
  end,
  currentPlaylist = nil,
  currentTrack = nil,
  forceSkip = false,
  playlistMetadata = MetadataRegistry,
  playlistsTracksOrder = musicUtil.getStoredTracksOrder(),
  registrationOrder = 0,
  registeredPlaylists = {},
  explorePlaylists = {},
  battlePlaylists = {},
  specialPlaylists = {},
  activePlaydeck = nil,
}

local specialTrackInfo = {
  tracks = { '' },
  trackChangeInfo = {
    playlistId = 'Special',
    trackName = '',
    reason = MusicManager.STATE.SpecialTrackPlaying, -- assigned after MusicManager.STATE exists
    fadeOut = MusicSettings.FadeOutDuration,
  },
  trackOrder = { 1 },
}

local FileExists, GetGameTime, IsMusicPlaying, SendEvent, StopMusic
if IsOpenMW then
  local ambient, async, core, storage, vfs =
    require 'openmw.ambient',
    require 'openmw.async',
    require 'openmw.core',
    require 'openmw.storage',
    require 'openmw.vfs'

  local I = require 'openmw.interfaces'

  FileExists = vfs.fileExists
  GetGameTime = core.getGameTime
  IsMusicPlaying = ambient.isMusicPlaying
  SendEvent = gameSelf.sendEvent
  StopMusic = ambient.stopMusic

  activePlaylistSettings = storage.playerSection 'S3maphoreActivePlaylistSettings'

  ---@diagnostic disable-next-line: param-type-mismatch
  activePlaylistSettings:setLifeTime(storage.LIFE_TIME.GameSession)

  --- Catches changes to the hidden storage group managing playlist activation and sets the corresponding playlist's active state to match
  --- In other words, this is the bit that responds to changes from the settings menu
  activePlaylistSettings:subscribe(async:callback(function(_, key)
    if not key then return end
    local playlistAssignedState = activePlaylistSettings:get(key)
    local playlistName = key:gsub('Active$', '')

    if not I.S3maphore then return end

    local targetPlaylist = MusicManager.registeredPlaylists[playlistName]

    if not targetPlaylist then return end

    if targetPlaylist.active ~= playlistAssignedState then
      targetPlaylist.active = playlistAssignedState
    end
  end))
else
end

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function MusicManager.registerPlaylist(playlist)
  local existing = MusicManager.registeredPlaylists[playlist.id]
  if existing then
    local oldDeck, newDeck
    if existing.priority <= PlaylistPriority.Special then
      oldDeck = 'special'
    elseif existing.priority <= PlaylistPriority.BattleVanilla then
      oldDeck = 'battle'
    else
      oldDeck = 'explore'
    end
    if playlist.priority <= PlaylistPriority.Special then
      newDeck = 'special'
    elseif playlist.priority <= PlaylistPriority.BattleVanilla then
      newDeck = 'battle'
    else
      newDeck = 'explore'
    end
    if oldDeck ~= newDeck then
      error(
        StrFormat(
          'Cannot change playlist "%s" from %s deck (priority %d) to %s deck (priority %d). '
            .. 'Re-registering a playlist under a different priority bracket is not supported.',
          playlist.id,
          oldDeck,
          existing.priority,
          newDeck,
          playlist.priority
        ),
        2
      )
    end
  end

  musicUtil.initMissingPlaylistFields(playlist, MusicManager.INTERRUPT)

  local existingOrder = MusicManager.playlistsTracksOrder[playlist.id]

  if
    not existingOrder
    or next(existingOrder) == nil
    or Max(unpack(existingOrder)) > #playlist.tracks
  then
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
  if not MusicManager.registeredPlaylists[playlist.id] then
    MusicManager.registrationOrder = MusicManager.registrationOrder + 1
  end

  MusicManager.registeredPlaylists[playlist.id] = playlist

  local newDeck
  if playlist.priority <= PlaylistPriority.Special then
    newDeck = MusicManager.specialPlaylists
  elseif playlist.priority <= PlaylistPriority.BattleVanilla then
    newDeck = MusicManager.battlePlaylists
  else
    newDeck = MusicManager.explorePlaylists
  end

  local replaced
  for i = 1, #newDeck do
    if newDeck[i].id == playlist.id then
      newDeck[i] = playlist
      replaced = true
      break
    end
  end

  if not replaced then newDeck[#newDeck + 1] = playlist end

  local storedState = not next(playlist.tracks) and -1 or playlist.active

  local playlistActiveKey = playlist.id .. 'Active'

  if activePlaylistSettings:get(playlistActiveKey) ~= nil then
    musicUtil.debugLog('loaded playlist state from settings: %s', playlist.id)

    playlist.active = activePlaylistSettings:get(playlistActiveKey)
  else
    musicUtil.debugLog('stored playlist state in settings: %s %s', playlist.id, storedState)

    activePlaylistSettings:set(playlistActiveKey, storedState)
  end
end

--- Decides whether or not a playlist will be used at all, regardless of whether its context is valid.
--- Typically should be used to forcefully disable a playlist, as they default to active.
--- May also be used to reactivate a playlist that was deactivated by a script, or was inactive by default.
---@param id string the ID of the playlist to unregister
---@param state boolean whether or not the playlist should be active in the list of registered playlists
function MusicManager.setPlaylistActive(id, state)
  if not id then error 'Playlist ID is nil' end

  local playlist = MusicManager.registeredPlaylists[id]
  if playlist then
    playlist.active = state
    activePlaylistSettings:set(playlist.id .. 'Active', playlist.active)
  else
    error(StrFormat('Playlist \'%s\' is not registered.', id))
  end
end

--- Returns the path of the currently playing track
---@return string?
function MusicManager.getCurrentTrack() return MusicManager.currentTrack end

--- Returns display names for the current playlist and track.
--- Returns nil if no playlist or track is active.
---@return S3maphorePlaylistMetadata? playlistMetadata
---@return S3maphoreTrackMetadata? trackMetadata
function MusicManager.getCurrentTrackInfo()
  local currentPlaylist, currentTrack = MusicManager.currentPlaylist, MusicManager.currentTrack
  if not currentPlaylist or not currentTrack then return end

  return MetadataRegistry.getPlaylistMetadata(currentPlaylist.id),
    MetadataRegistry.getTrackMetadata(currentTrack)
end

--- Returns a read-only copy of the current playlist, or nil
---@return ReadOnlyTable? readOnlyPlaylist
function MusicManager.getCurrentPlaylist()
  if not MusicManager.currentPlaylist then return end

  return musicUtil.makeReadOnly(MusicManager.currentPlaylist, true)
end

--- Returns a read-only list of read-only playlist structs for introspection. To modify playlists in any way, use other functions.
function MusicManager.getRegisteredPlaylists()
  local readOnlyPlaylists = {}

  for k, v in next, MusicManager.registeredPlaylists do
    readOnlyPlaylists[k] = musicUtil.makeReadOnly(v, true)
  end

  return musicUtil.makeReadOnly(readOnlyPlaylists)
end

--- Returns a read-only array of all recognized playlist files (files with the .lua extension under the VFS directory, Playlists/ )
---@return ReadOnlyTable playlistFiles
function MusicManager.listPlaylistFiles() return ReadOnlyPlaylistFileList end

--- Stops the currently playing track, if any.
--- The onFrame handler will naturally switch to the next track or playlist
function MusicManager.skipTrack()
  if IsMusicPlaying() then StopMusic() end
end

--- Tells whether or not music playback is completely disabled
---@return boolean canPlayMusic
function MusicManager.getEnabled() return MusicSettings.MusicEnabled end

function MusicManager.getState() return musicUtil.makeReadOnly(PlaylistState, true) end

---@return number duration of current silence track
function MusicManager.silenceTime() return SilenceManager.time end

---@param enabled boolean
function MusicManager.overrideMusicEnabled(enabled)
  if enabled == nil then enabled = not MusicSettings.MusicEnabled end

  MusicSettings.MusicEnabled = enabled
end

function MusicManager.getDeathTrack() return DeathTrackPath end

function MusicManager.setDeathTrack(path)
  if not FileExists(path) then
    return print(StrFormat('[ S3MAPHORE ]: Death track not found: %s', path))
  end

  DeathTrackPath = path
end

function MusicManager.resetDeathTrack() DeathTrackPath = DefaultDeathTrack end

local function priorityThenRegistration(a, b)
  return a.priority < b.priority
    or (a.priority == b.priority and a.registrationOrder < b.registrationOrder)
end

MusicManager.priorityThenRegistration = priorityThenRegistration

--- Returns a string listing all the currently registered playlists, mapped to their (descending) priority.
--- Mostly intended to be used via the `luap` console.
---@return string
function MusicManager.listPlaylistsByPriority()
  local sortedPlaylists = {}

  for _, playlist in next, MusicManager.registeredPlaylists do
    Insert(sortedPlaylists, playlist)
  end

  TableSort(sortedPlaylists, priorityThenRegistration)

  local playlistsByName = ''

  for i = 1, #sortedPlaylists do
    local v = sortedPlaylists[i]
    playlistsByName = StrFormat('%s%s: %s\n', playlistsByName, v.id, v.priority)
  end

  return playlistsByName
end

---@param trackPath string VFS path of the track to play
---@param reason S3maphoreStateChangeReason
function MusicManager.playSpecialTrack(trackPath, reason)
  if not FileExists(trackPath) then
    return print(StrFormat('Requested track %s does not exist!', trackPath))
  end

  musicUtil.debugLog('playing special track: %s', trackPath)

  specialTrackInfo.tracks[1] = trackPath

  MusicManager.registeredPlaylists.Special.tracks = specialTrackInfo.tracks
  MusicManager.playlistsTracksOrder.Special = specialTrackInfo.trackOrder

  MusicManager.setPlaylistActive('Special', true)

  local fadeOut
  if MusicManager.currentPlaylist and MusicManager.currentPlaylist.fadeOut ~= nil then
    fadeOut = MusicManager.currentPlaylist.fadeOut
  else
    fadeOut = MusicSettings.FadeOutDuration
  end

  specialTrackInfo.trackChangeInfo.fadeOut = fadeOut
  specialTrackInfo.trackChangeInfo.reason = reason or MusicManager.STATE.SpecialTrackPlaying
  specialTrackInfo.trackChangeInfo.trackName = trackPath

  SendEvent(gameSelf, 'S3maphoreTrackChanged', specialTrackInfo.trackChangeInfo)
end

---@return TimeOfDay
local function MWSEPlaylistTimeOfDay()
  local dayPortion = Floor(tes3.worldController.hour.value / 6)
  return MusicManager.TIME_MAP[dayPortion]
end

---@return TimeOfDay
local function OMWPlaylistTimeOfDay()
  local dayPortion = Floor(GetGameTime() / 3600 % 24 / 6)
  return MusicManager.TIME_MAP[dayPortion]
end

function MusicManager.updateBanner()
  local playlistMetadata, trackMetadata = MusicManager.getCurrentTrackInfo()
  local playlistName = playlistMetadata and playlistMetadata.title

  if playlistName and trackMetadata and MusicSettings.BannerEnabled then
    MusicBanner.layout.props.visible = true
    MusicBanner.layout.content[1].props.text =
      StrFormat('%s\n\n%s', playlistName, trackMetadata.title)
  else
    MusicBanner.layout.props.visible = false
  end

  MusicBanner:update()
end

MusicManager.playlistTimeOfDay = IsOpenMW and OMWPlaylistTimeOfDay or MWSEPlaylistTimeOfDay
MusicManager.registerPlaylist {
  active = false,
  id = 'Special',
  isValidCallback = function() return false end,
  playOneTrack = true,
  priority = PlaylistPriority.Special,
  tracks = {},
}
MusicManager.activePlaydeck = MusicManager.explorePlaylists

return MusicManager
