---@omw-context none

---@class StateChangedFlags: StrictReadOnlyTable
---@field TOD 1
---@field MOVEMENT 2
local StateChangedFlags = {
  TOD = 1,
  MOVEMENT = 2,
}

return require('scripts.s3.music.util').makeReadOnly(StateChangedFlags, false, true)
