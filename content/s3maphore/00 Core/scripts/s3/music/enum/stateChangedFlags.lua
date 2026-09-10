---@omw-context none

local StateChangedFlags = {
  TOD = 1,
  MOVEMENT = 2,
  SPELL_SCHOOL = 4,
  STANCE = 8,
}

return require('scripts.s3.music.util').makeReadOnly(StateChangedFlags, false, true)
