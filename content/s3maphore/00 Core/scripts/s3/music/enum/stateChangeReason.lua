---@omw-context none

---@alias S3maphoreStateChangeReason
---| 'DIED'
---| 'DSBL'
---| 'NPLS'
---| 'PLCH'
---| 'SPTR'
---| 'TRCH'

local StateChangeReason = {
  Died = 'DIED',
  Disabled = 'DSBL',
  NoPlaylist = 'NPLS',
  PlaylistChanged = 'PLCH',
  SpecialTrackPlaying = 'SPTR',
  TrackChanged = 'TRCH',
}

return require('scripts.s3.music.util').makeReadOnly(StateChangeReason, false, true)
