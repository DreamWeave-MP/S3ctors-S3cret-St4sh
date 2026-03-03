--- Meant to be used in conjunction with the output of MusicManager.playlistTimeOfDay OR PlaylistState.playlistTimeOfDay
---@enum TimeMap
return require 'scripts.s3.music.util'.makeReadOnly {
  [0] = 'night',
  [1] = 'morning',
  [2] = 'afternoon',
  [3] = 'evening',
}
