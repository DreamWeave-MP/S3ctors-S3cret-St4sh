---@module 'doc.s3maphoreTypes'
---@omw-context player

local MusicManager = require 'scripts.s3.music.musicManager'
local MusicSettings = require 'scripts.s3.music.musicSettings'
local SilenceManager = require 'scripts.s3.music.silenceManager'
local musicUtil = require 'scripts.s3.music.util'
local randomGen = require 'scripts.s3.randomGen'

local error, next, Remove, StrFormat = error, next, table.remove, string.format

--- Maximum depth for recursive fallback resolution.
--- Fallback chains are validated eagerly at startup in core.lua, so the hot path
--- never needs to check registration — just pick one, check active, recurse or return.
local MAX_FALLBACK_DEPTH = 10

--- Resolve a playlist ID through its fallback chain.
--- Startup validation guarantees all fallback playlist IDs exist in registeredPlaylists.
---@param newPlaylist S3maphorePlaylist
---@param depth integer? internal recursion depth counter
local function getPlaylistIdForTrackSelection(newPlaylist, depth)
  depth = (depth or 0) + 1

  if depth > MAX_FALLBACK_DEPTH then
    musicUtil.debugLog(
      'Fallback chain exceeded max depth (%d) for playlist "%s". Breaking to prevent infinite recursion.',
      MAX_FALLBACK_DEPTH,
      newPlaylist.id
    )
    return newPlaylist.id
  end

  local fallbackData = newPlaylist.fallback
  if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

  local useOtherPlaylist = randomGen.float() <= (fallbackData.playlistChance or 0.5)
  if not useOtherPlaylist then return newPlaylist.id end

  local numBackupPlaylists = #fallbackData.playlists
  if numBackupPlaylists == 0 then return newPlaylist.id end

  local selectedPlaylistIndex = randomGen.range(numBackupPlaylists, true)
  local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]
  local selectedPlaylist = MusicManager.registeredPlaylists[selectedPlaylistId]

  -- Skip inactive fallback playlists
  if not selectedPlaylist.active then return newPlaylist.id end

  -- Recurse into nested fallback chains
  local fallback = selectedPlaylist.fallback
  if fallback and fallback.playlists then
    return getPlaylistIdForTrackSelection(selectedPlaylist, depth)
  end

  return selectedPlaylistId
end

---@param playlistId string name of a playlist stored in registeredPlaylists table
local function selectTrackFromPlaylist(playlistId)
  local playlist = MusicManager.registeredPlaylists[playlistId]

  if not playlist then error(StrFormat('Playlist %s has not been registered!', playlistId)) end

  local playlistOrder = MusicManager.playlistsTracksOrder[playlist.id]
  local nextTrackIndex = Remove(playlistOrder)

  if not nextTrackIndex then error 'Can not fetch track: nextTrackIndex is nil' end

  -- If there are no tracks left, fill playlist again.
  if not next(playlistOrder) then
    playlistOrder = musicUtil.initTracksOrder(playlist.tracks, playlist.randomize)

    if not playlist.cycleTracks then playlist.deactivateAfterEnd = true end

    -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
    if playlist.randomize and #playlistOrder > 1 and playlistOrder[1] == nextTrackIndex then
      local index = randomGen.range(2, #playlistOrder, true)
      playlistOrder[1], playlistOrder[index] = playlistOrder[index], playlistOrder[1]
    end

    MusicManager.playlistsTracksOrder[playlist.id] = playlistOrder
  end

  musicUtil.setStoredTracksOrder(playlist.id, playlistOrder)

  local trackPath = playlist.tracks[nextTrackIndex]

  if not trackPath then
    error(
      StrFormat(
        'Can not fetch track with index %s from playlist \'%s\'.',
        nextTrackIndex,
        playlist.id
      )
    )
  end

  return trackPath
end

---@param newPlaylist S3maphorePlaylist
---@param playbackParams S3maphorePlaybackParamsTable
local function switchPlaylist(newPlaylist, playbackParams)
  -- Resolve fallback chain before reading playlist state, so currentPlaylist
  -- always matches the playlist that actually produced currentTrack.
  local resolvedPlaylistId = getPlaylistIdForTrackSelection(newPlaylist)
  local resolvedPlaylist = MusicManager.registeredPlaylists[resolvedPlaylistId]
  local nextTrack = selectTrackFromPlaylist(resolvedPlaylistId)

  -- playOneTrack/deactivateAfterEnd still governed by the original playlist's intent
  if newPlaylist.playOneTrack then newPlaylist.deactivateAfterEnd = true end

  if MusicManager.currentPlaylist and newPlaylist.id == MusicManager.currentPlaylist.id then
    SilenceManager:updateSilenceParams(newPlaylist)
  end

  MusicManager.currentPlaylist = resolvedPlaylist
  MusicManager.currentTrack = nextTrack
  playbackParams.fadeOut = resolvedPlaylist.fadeOut or MusicSettings.FadeOutDuration
end

---@param oldPlaylist S3maphorePlaylist?
---@param newPlaylist S3maphorePlaylist
---@return boolean canSwitchPlaylist
local function canSwitchPlaylist(oldPlaylist, newPlaylist)
  if newPlaylist.interruptMode == MusicManager.INTERRUPT.Override then
    return true
  elseif not oldPlaylist then
    return true
  elseif oldPlaylist.interruptMode == MusicManager.INTERRUPT.Override then
    return true
  elseif oldPlaylist.interruptMode == MusicManager.INTERRUPT.Never then
    return false
  elseif
    MusicSettings.ForceFinishTrack and oldPlaylist.interruptMode == newPlaylist.interruptMode
  then
    return false
  elseif oldPlaylist.interruptMode <= MusicManager.INTERRUPT.Other then
    return true
  end

  musicUtil.debugLog(
    'Playlist Interrupt Modes Fell Through!\nOld Playlist: %s Interrupt Mode: %s\nNew Playlist: %s InterruptMode: %s',
    oldPlaylist.id,
    oldPlaylist.interruptMode,
    newPlaylist.id,
    newPlaylist.interruptMode
  )

  return false
end

return {
  canSwitchPlaylist = canSwitchPlaylist,
  getPlaylistIdForTrackSelection = getPlaylistIdForTrackSelection,
  selectTrackFromPlaylist = selectTrackFromPlaylist,
  switchPlaylist = switchPlaylist,
}
