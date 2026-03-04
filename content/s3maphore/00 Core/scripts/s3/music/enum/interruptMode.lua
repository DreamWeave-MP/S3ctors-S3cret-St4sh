---@alias InterruptMode
---| 0
---| 1
---| 2

---@class InterruptModes: StrictReadOnlyTable
---@field Me 0
---@field Other 1
---@field Never 2
local InterruptModes = require 'scripts.s3.music.util'.makeStrictReadOnly {
  Me = 0,    -- Explore
  Other = 1, -- Battle
  Never = 2, -- Special
}

---@type InterruptModes
return InterruptModes
