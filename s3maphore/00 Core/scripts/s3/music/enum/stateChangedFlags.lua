---@omw-context none

---@class StateChangedFlags: StrictReadOnlyTable
---@field TOD 1
---@field MOVEMENT 2
---@field SPELL_SCHOOL 4
---@field STANCE 8
local StateChangedFlags = {
  TOD = 1,
  MOVEMENT = 2,
  SPELL_SCHOOL = 4,
  STANCE = 8,
}

return require('scripts.s3.music.util').makeReadOnly(StateChangedFlags, false, true)
