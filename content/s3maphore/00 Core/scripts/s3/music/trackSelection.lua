---@module 'doc.s3maphoreTypes'
---@omw-context player

local MusicManager = require 'scripts.s3.music.musicManager'
local MusicSettings = require 'scripts.s3.music.musicSettings'
local SilenceManager = require 'scripts.s3.music.silenceManager'
local Strings = require 'scripts.s3.music.staticStrings'
local musicUtil = require 'scripts.s3.music.util'
local randomGen = require 'scripts.s3.randomGen'

local error, next, Remove, StrFormat = error, next, table.remove, string.format

--- If a set of fallback playlists is present, attempt to use them during track selection
--- It should be noted that, for fallback playlists, their `active` parameter is ignored currently.
---@param newPlaylist S3maphorePlaylist
local function getPlaylistIdForTrackSelection(newPlaylist)
  local fallbackData = newPlaylist.fallback
  if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

  local useOtherPlaylist = randomGen.float() <= (fallbackData.playlistChance or 0.5)

  if not useOtherPlaylist then return newPlaylist.id end

  for i = #fallbackData.playlists, 1, -1 do
    local playlistId = fallbackData.playlists[i]
    if not MusicManager.registeredPlaylists[playlistId] then Remove(fallbackData.playlists, i) end
  end

  local numBackupPlaylists = #fallbackData.playlists
  local selectedPlaylistIndex = randomGen.range(numBackupPlaylists, true)
  local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]

  if not MusicManager.registeredPlaylists[selectedPlaylistId] then
    if selectedPlaylistId then
      musicUtil.debugLog(Strings.FallbackPlaylistDoesntExist, newPlaylist.id, selectedPlaylistId)
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

  if not nextTrackIndex then error(Strings.NextTrackIndexNil) end

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

  if not trackPath then error(StrFormat(Strings.NoTrackPath, nextTrackIndex, playlist.id)) end

  return trackPath
end

---@param newPlaylist S3maphorePlaylist
---@param playbackParams S3maphorePlaybackParamsTable
local function switchPlaylist(newPlaylist, playbackParams)
  local nextPlaylist = getPlaylistIdForTrackSelection(newPlaylist)
  local nextTrack = selectTrackFromPlaylist(nextPlaylist)

  if newPlaylist.playOneTrack then newPlaylist.deactivateAfterEnd = true end

  if MusicManager.currentPlaylist and newPlaylist.id == MusicManager.currentPlaylist.id then
    SilenceManager:updateSilenceParams(newPlaylist)
  end

  MusicManager.currentPlaylist = newPlaylist
  MusicManager.currentTrack = nextTrack
  playbackParams.fadeOut = newPlaylist.fadeOut or MusicSettings.FadeOutDuration
end

---@param oldPlaylist S3maphorePlaylist?
---@param newPlaylist S3maphorePlaylist
---@return boolean canSwitchPlaylist
local function canSwitchPlaylist(oldPlaylist, newPlaylist)
  if not oldPlaylist then
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
    Strings.InterruptModeFallthrough,
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
