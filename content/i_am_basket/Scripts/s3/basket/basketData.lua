local types = require("openmw.types")
local util = require("openmw.util")

local ActorType = types.Actor

BasketData = {
  ActivatorId = "s3_basket_transform",
  DeadZone = 2,
  DefaultRobeId = "s3_basket_gear",
  DoDebug = false,
  DTMult = 8,
  ForwardRadsPerSecond = 2.5,
  GravityForce = 98.1 * 2,
  HardMode = true,
  HardModeAllowedSlots = {
    [ActorType.EQUIPMENT_SLOT.Ammunition] = true,
    [ActorType.EQUIPMENT_SLOT.Amulet] = true,
    [ActorType.EQUIPMENT_SLOT.Belt] = true,
    [ActorType.EQUIPMENT_SLOT.CarriedLeft] = true,
    [ActorType.EQUIPMENT_SLOT.CarriedRight] = true,
    [ActorType.EQUIPMENT_SLOT.LeftGauntlet] = true,
    [ActorType.EQUIPMENT_SLOT.RightGauntlet] = true,
    [ActorType.EQUIPMENT_SLOT.RightRing] = true,
    [ActorType.EQUIPMENT_SLOT.LeftRing] = true,
    [ActorType.EQUIPMENT_SLOT.Helmet] = true,
    [ActorType.EQUIPMENT_SLOT.Robe] = true,
  },
  HorizontalMoveMult = 0.75,
  JumpPerSecond = 800,
  JumpTargetDistance = 120,
  MinDistanceToGround = 10,
  RollTimeStep = 1.0 / 60.0,
  TestInfo = {
    position = util.vector3(-12225, -69560, 25000),
    cellGrid = { x = -2, y = -9 },
  },
  TransformStates = {
    Start = 1,
    Transforming = 2,
    Normal = 3,
    Basket = 4,
    End = 5,
  },
}

BasketData.MoveUnitsPerSecond = BasketData.DoDebug and 1024 or 128

return BasketData
