---@alias S3maphoreStateChangeReason
---| 'DIED'
---| 'DSBL'
---| 'NPLS'
---| 'SPTR'

---@class StateChangeReasons: StrictReadOnlyTable
---@field Died 'DIED'
---@field Disabled 'DSBL'
---@field NoPlaylist 'NPLS'
---@field SpecialTrackPlaying 'SPTR'
local StateChangeReason = {
  Died = 'DIED',
  Disabled = 'DSBL',
  NoPlaylist = 'NPLS',
  SpecialTrackPlaying = 'SPTR',
}

return require 'scripts.s3.music.util'.makeStrictReadOnly(StateChangeReason)
