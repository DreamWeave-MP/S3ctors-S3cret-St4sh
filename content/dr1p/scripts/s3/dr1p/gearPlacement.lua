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

  ['meshes/c/amulet_common_3.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = -0.5,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-5),
      [Axis.Y] = Radians(5),
      [Axis.Z] = Radians(-20),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/amulet_expensive_2.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = -0.5,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-5),
      [Axis.Y] = Radians(5),
      [Axis.Z] = Radians(20),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/amulet_exquisit_1.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = -0.3,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-5),
      [Axis.Y] = Radians(0),
      [Axis.Z] = Radians(-5),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/amulet_extravagant_1.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = -0.3,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-5),
      [Axis.Y] = Radians(0),
      [Axis.Z] = Radians(-5),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/amulet_extravagant_2.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0,
      [Axis.Z] = -0.3,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-5),
      [Axis.Y] = Radians(0),
      [Axis.Z] = Radians(-10),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/c_ring_exquisite_1.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 1.5,
      [Axis.Z] = 0,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-45),
      [Axis.Y] = Radians(0),
      [Axis.Z] = Radians(0),
    },

    [Transform.Scale] = {
      [Axis.X] = 1,
      [Axis.Y] = 1,
      [Axis.Z] = 1,
    },
  },

  ['meshes/c/c_ring_extravagant_1.nif'] = {
    [Transform.Position] = {
      [Axis.X] = 0,
      [Axis.Y] = 0.75,
      [Axis.Z] = 0,
    },

    [Transform.Rotation] = {
      [Axis.X] = Radians(-10),
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
