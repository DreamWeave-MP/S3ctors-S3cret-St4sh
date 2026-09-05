---@omw-context none

---@alias InterruptMode
---| 0
---| 1
---| 2
---| 3

---@class InterruptModes: StrictReadOnlyTable
---@field Me 0
---@field Other 1
---@field Never 2
---@field Override 3
local InterruptModes = require('scripts.s3.music.util').makeReadOnly({
  Me = 0, -- Explore
  Other = 1, -- Battle
  Never = 2, -- Special
  Override = 3,
}, false, true)

---@type InterruptModes
return InterruptModes
