---@alias TimeOfDay
---| 'night'
---| 'morning'
---| 'afternoon'
---| 'evening'

--- Meant to be used in conjunction with the output of MusicManager.playlistTimeOfDay OR PlaylistState.playlistTimeOfDay
---@class TimeMap: StrictReadOnlyTable
---@field [0] 'night'
---@field [1] 'morning'
---@field [2] 'afternoon'
---@field [3] 'evening'
return require 'scripts.s3.music.util'.makeStrictReadOnly {
  [0] = 'night',
  [1] = 'morning',
  [2] = 'afternoon',
  [3] = 'evening',
}
