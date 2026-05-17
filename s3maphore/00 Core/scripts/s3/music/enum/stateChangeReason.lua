---@alias S3maphoreStateChangeReason
---| 'DIED'
---| 'DSBL'
---| 'NPLS'
---| 'PLCH'
---| 'SPTR'
---| 'TRCH'

---@class StateChangeReasons: StrictReadOnlyTable
---@field Died 'DIED'
---@field Disabled 'DSBL'
---@field NoPlaylist 'NPLS'
---@field PlaylistChanged 'PLCH'
---@field SpecialTrackPlaying 'SPTR'
---@field TrackChanged 'TRCH'
local StateChangeReason = {
  Died = 'DIED',
  Disabled = 'DSBL',
  NoPlaylist = 'NPLS',
  PlaylistChanged = 'PLCH',
  SpecialTrackPlaying = 'SPTR',
  TrackChanged = 'TRCH',
}

return require 'scripts.s3.music.util'.makeReadOnly(StateChangeReason, false, true)
