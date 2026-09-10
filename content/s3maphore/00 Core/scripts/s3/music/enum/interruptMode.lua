---@omw-context none

---@alias InterruptMode
---| 0
---| 1
---| 2
---| 3

local InterruptModes = require('scripts.s3.music.util').makeReadOnly({
  Me = 0, -- Explore
  Other = 1, -- Battle
  Never = 2, -- Special
  Override = 3,
}, false, true)

---@type InterruptModes
return InterruptModes
