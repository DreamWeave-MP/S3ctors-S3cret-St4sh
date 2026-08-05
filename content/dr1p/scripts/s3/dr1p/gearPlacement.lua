---@omw-context none

local Radians = math.rad

local Enum = require 'scripts.s3.dr1p.enum'
local Axis, Transform = Enum.Axis, Enum.Transform

---@type table<string, DR1PTransform>
local GearPlacement = {
  ['some/mesh/path.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = 0,
    },
    [Transform.Rotation] = {
      [Axis.X] = Radians(0),
      [Axis.Y] = Radians(0),
      [Axis.Z] = Radians(0),
    },
    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },
}

return GearPlacement
