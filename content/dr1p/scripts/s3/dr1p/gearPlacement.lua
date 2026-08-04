----@omw-context none

local Radians = math.rad

---@type table<string, DR1PTransform>
local GearPlacement = {
  ['some/mesh/path.nif'] = {
    pos = {
      x = 0,
      y = 0,
      z = 0,
    },
    rot = {
      x = Radians(0),
      y = Radians(0),
      z = Radians(0),
    },
    scale = {
      x = 1,
      y = 1,
      z = 1,
    },
  },
}

return GearPlacement
