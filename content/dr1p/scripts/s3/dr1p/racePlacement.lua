---@omw-context none

local Dr1pEnum = require 'scripts.s3.dr1p.enum'
local AuxSlot, Axis, Finger, Hand, Transform =
  Dr1pEnum.AuxSlot,
  Dr1pEnum.Axis,
  Dr1pEnum.Finger,
  Dr1pEnum.Hand,
  Dr1pEnum.Transform

---@type table<string, RacePlacementMap>
local RacePlacement = {
  ['redguard'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['dark elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['imperial'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['breton'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['nord'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['wood elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['high elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['khajiit'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['argonian'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
  ['orc'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Index] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Middle] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Ring] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
      [Finger.Pinky] = {
        [Transform.Position] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Rotation] = {
          [Axis.X] = 0,
          [Axis.Y] = 0,
          [Axis.Z] = 0,
        },
        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
    [AuxSlot.Belt] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
    [AuxSlot.Amulet] = {
      [Transform.Position] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Rotation] = {
        [Axis.X] = 0,
        [Axis.Y] = 0,
        [Axis.Z] = 0,
      },
      [Transform.Scale] = {
        [Axis.X] = 1,
        [Axis.Y] = 1,
        [Axis.Z] = 1,
      },
    },
  },
}

return RacePlacement
