local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local input = require("openmw.input")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local util = require("openmw.util")

local I = require("openmw.interfaces")

local movementSettings = storage.playerSection("SettingsOMWControls")

local Inventory = self.type.inventory(self)

local RobeSlot = self.type.EQUIPMENT_SLOT.Robe
local BASKET_ROBE_ID = "s3_basket_gear"

local BasketFuncs = {}

local HARD_MODE_ALLOWED_SLOTS = {
  [self.type.EQUIPMENT_SLOT.Ammunition] = true,
  [self.type.EQUIPMENT_SLOT.Amulet] = true,
  [self.type.EQUIPMENT_SLOT.Belt] = true,
  [self.type.EQUIPMENT_SLOT.CarriedLeft] = true,
  [self.type.EQUIPMENT_SLOT.CarriedRight] = true,
  [self.type.EQUIPMENT_SLOT.LeftGauntlet] = true,
  [self.type.EQUIPMENT_SLOT.RightGauntlet] = true,
  [self.type.EQUIPMENT_SLOT.RightRing] = true,
  [self.type.EQUIPMENT_SLOT.LeftRing] = true,
  [self.type.EQUIPMENT_SLOT.Helmet] = true,
  [self.type.EQUIPMENT_SLOT.Robe] = true,
}

local prevHudState
local prevCamMode
local myBasket
input.registerActionHandler(
  "Sneak",
  async:callback(function(sneak)
    if I.UI.getMode() then
      return
    end

    if not sneak then
      return
    end

    core.sendGlobalEvent("S3_BasketMode_BasketTransform", { target = self.object, basket = myBasket })

    local overrideControls = myBasket == nil
    I.Controls.overrideCombatControls(overrideControls)
    I.Controls.overrideUiControls(overrideControls)
    I.Controls.overrideMovementControls(overrideControls)

    -- Dangerous?
    if not myBasket then
      prevHudState = I.UI.isHudVisible()
      I.UI.setHudVisibility(false)
      prevCamMode = camera.getMode()
      -- Get rotation too?
      local camPos = camera.getPosition()
      camera.setMode(camera.MODE.Static)
      camera.setStaticPosition(camPos)
    else
      myBasket = nil
      camera.setMode(prevCamMode)
      I.UI.setHudVisibility(prevHudState)
    end
  end)
)

local isJumping = false
local canJump = false
input.registerTriggerHandler(
  "Jump",
  async:callback(function()
    if canJump then
      isJumping = true
    end
  end)
)

local MoveUnitsPerSecond = 128
local HorizontalMovementMultiplier = 0.75

local Skills = self.type.stats.skills
local Illusion = Skills.illusion(self)
local Athletics = Skills.athletics(self)

BasketFuncs.getPerFrameMoveUnits = function(dt, movement, horizontal)
  local illusionTerm = math.min(0.75, Illusion.modified / 100)
  local speedTerm = math.min(0.25, Athletics.modified / 100)

  local moveTerm = MoveUnitsPerSecond * (1 + illusionTerm + speedTerm)

  local units = (dt * moveTerm)

  if horizontal then
    units = units * HorizontalMovementMultiplier
  end

  return units * movement
end

BasketFuncs.getPerFrameMovement = function(dt, sideMovementControl, forwardMovementControl)
  local horizontalMovementThisFrame = BasketFuncs.getPerFrameMoveUnits(dt, sideMovementControl, true)
  local forwardMovementThisFrame = BasketFuncs.getPerFrameMoveUnits(dt, forwardMovementControl, false)

  -- Get the Z rotation of the player inside the basket
  local zRot, _, _ = self.rotation:getAnglesZYX()
  -- Construct a transform composed of only this rotation
  local zAdjustedTransform = util.transform.identity * util.transform.rotateZ(zRot)
  -- Get corresponding forward + side vectors
  local forwardVector = zAdjustedTransform:apply(util.vector3(0, 1, 0))
  local sideVector = zAdjustedTransform:apply(util.vector3(1, 0, 0))

  -- Apply the distances to each rotation vector
  return (sideVector * horizontalMovementThisFrame) + (forwardVector * forwardMovementThisFrame)
end

BasketFuncs.handleCameraMove = function(moveThisFrame)
  local playerRotZ, _, _ = self.rotation:getAnglesZYX()
  local cameraOffset = util.transform.rotateZ(playerRotZ):apply(util.vector3(0, -96, 64))
  local newCameraPos = self.position + moveThisFrame + cameraOffset
  camera.setStaticPosition(newCameraPos)
  camera.setYaw(playerRotZ)
end

local ForwardRadsPerSecond = 2.5
local RollTimeStep = 1.0 / 60.0
---@param movement integer movement on a given axis between -1 and 1
---@return integer axisTransform Transformation for a given axis relative to the movement provided
function BasketFuncs.getPerFrameRoll(movement)
  return (RollTimeStep * ForwardRadsPerSecond) * movement
end

function BasketFuncs.getPerFrameRollTransform(sideMovement, forwardMovement, basketRotation)
  if sideMovement == 0 and forwardMovement == 0 then
    return nil
  end

  local side = input.isShiftPressed() and 0 or BasketFuncs.getPerFrameRoll(sideMovement)
  local forward = input.isAltPressed() and 0 or BasketFuncs.getPerFrameRoll(forwardMovement)

  local xTransform = util.transform.rotateX(-forward)
  local yTransform = util.transform.rotateY(-side)
  return basketRotation * yTransform * xTransform
end

function BasketFuncs.basketIsColliding(moveThisFrame, rollThisFrame)
  local basketBounds = myBasket:getBoundingBox()

  if not rollThisFrame then
    rollThisFrame = util.transform.identity
  end

  local moveDir = moveThisFrame:normalize()
  local useX = math.abs(moveDir.x) > math.abs(moveDir.y)
  local offset = useX and basketBounds.halfSize.x or basketBounds.halfSize.y

  local basketIgnoreTable = {
    collideType = nearby.COLLISION_TYPE.Default,
    ignore = myBasket,
  }

  local center = basketBounds.center
  local centerRay = nearby.castRay(center, center + moveThisFrame + (moveDir * offset), basketIgnoreTable)

  if centerRay.hit then
    return true
  end

  for _, vertex in ipairs(basketBounds.vertices) do
    if
        nearby.castRay(vertex, vertex + rollThisFrame:apply(moveThisFrame), {
          ignore = myBasket,
          -- collideType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Actor,
        }).hit
    then
      return true
    end
  end
end

local function getLowestVertex(object)
  local box = object:getBoundingBox()
  local vertex

  for _, boxVertex in ipairs(box.vertices) do
    if not vertex or boxVertex.z < vertex.z then
      vertex = boxVertex
    end
  end

  assert(vertex ~= nil, "Failed to find the lowest vertex of the bounding box!")

  return vertex
end

function BasketFuncs.getVerticalVertex(basket, down)
  assert(basket, "")
  local viewDistance = camera.getViewDistance()
  local rangeLow = down and 1 or 5
  local rangeHigh = down and 4 or 8

  local box = basket:getBoundingBox()
  local startPos = util.vector3(box.center.x, box.center.y, box.center.z - box.halfSize.z)
  local downCast = nearby.castRay(
    startPos,
    util.vector3(box.center.x, box.center.y, box.center.z + (down and -viewDistance or viewDistance)),
    { ignore = basket }
  )

  if downCast.hit then
    return box.center, downCast
  end

  -- The lower 4 verts are the minimums of the box
  local vertices = box.vertices
  for i = rangeLow, rangeHigh do
    local vertex = vertices[i]
    downCast = nearby.castRay(
      vertex,
      util.vector3(vertex.x, vertex.y, vertex.z + (down and -viewDistance or viewDistance)),
      { ignore = basket }
    )

    if downCast.hit then
      return vertex, downCast
    end
  end
end

local GravityForce = 98.1 * 2
local MinDistanceToGround = 10
local DTMult = 8

local jumpDist = 0
local JumpTargetDistance = 120
local JumpPerSecond = 800

local DeadZone = 2
BasketFuncs.getPerFrameGravity = function(dt)
  if isJumping then
    local jumpThisFrame = JumpPerSecond * dt
    jumpDist = jumpDist + jumpThisFrame

    if jumpDist <= JumpTargetDistance then
      return jumpThisFrame
    else
      isJumping = false
      jumpDist = 0
    end
  end

  local fallAcceleration = GravityForce * dt

  local startPos = getLowestVertex(myBasket)
  local _, groundResult = BasketFuncs.getVerticalVertex(myBasket, true)

  if not groundResult or not groundResult.hitPos then
    local _, upResult = BasketFuncs.getVerticalVertex(myBasket, false)

    if upResult and upResult.hit and upResult.hitPos then
      return (upResult.hitPos.z - startPos.z) * dt * DTMult
    else
      -- If they get stuck, then, they're stuck, so apply a little gravity and allow jumping
      canJump = true
      return -0.01 * dt
    end
  end

  local distanceToGround = math.floor(getLowestVertex(myBasket).z - groundResult.hitPos.z)

  if distanceToGround < MinDistanceToGround then
    -- Basket is too close to the ground; nudge it up smoothly

    canJump = true
    local targetHeight = MinDistanceToGround - distanceToGround
    local nudgeFactor = math.min(1, targetHeight / MinDistanceToGround)
    return targetHeight * nudgeFactor
  elseif distanceToGround > MinDistanceToGround + DeadZone then
    -- Basket is too far from the ground; apply gravity smoothly

    canJump = false
    return -math.min(distanceToGround, fallAcceleration)
  else
    -- Basket is within the dead zone; no adjustment needed

    canJump = true
    return 0
  end
end

local MovementLocked = false
BasketFuncs.handleBasketMove = function(dt)
  if self.controls.sneak then
    self.controls.sneak = false
  end

  if not myBasket then
    return
  end

  local movement = input.getRangeActionValue("MoveForward") - input.getRangeActionValue("MoveBackward")
  local sideMovement = input.getRangeActionValue("MoveRight") - input.getRangeActionValue("MoveLeft")

  -- local run = input.getBooleanActionValue("Run") ~= movementSettings:get("alwaysRun")

  local xyMoveThisFrame = BasketFuncs.getPerFrameMovement(dt, sideMovement, movement)

  local rollThisFrame = BasketFuncs.getPerFrameRollTransform(sideMovement, movement, myBasket.rotation)

  -- Don't process z movement during collision handling, since the script will try to correct your position
  if BasketFuncs.basketIsColliding(xyMoveThisFrame, rollThisFrame) then
    print("Basket will collide with this move", xyMoveThisFrame, "bailing on XY movement")
    -- xyMoveThisFrame = -xyMoveThisFrame
    xyMoveThisFrame = util.vector3(0, 0, 0)
  end

  local gravityMove = BasketFuncs.getPerFrameGravity(dt)

  local moveThisFrame =
      util.vector3(MovementLocked and 0 or xyMoveThisFrame.x, MovementLocked and 0 or xyMoveThisFrame.y, gravityMove)

  BasketFuncs.handleCameraMove(moveThisFrame)

  core.sendGlobalEvent("S3_BasketMode_BasketMove", {
    rollThisFrame = rollThisFrame,
    basket = myBasket,
    moveThisFrame = moveThisFrame,
    target = self.object,
  })
end

---@return #core.gameObject|nil
BasketFuncs.getBasket = function()
  local equippedRobe = self.type.getEquipment(self, RobeSlot)

  if equippedRobe and equippedRobe.recordId == BASKET_ROBE_ID then
    return equippedRobe
  end
end

BasketFuncs.getGroundPos = function()
  local height = self:getBoundingBox().halfSize.z * 2
  local pos = self.position

  local rayStart = util.vector3(pos.x, pos.y, pos.z + height)
  local rayEnd = util.vector3(pos.x, pos.y, pos.z - camera.getViewDistance())

  local rayHit = nearby.castRay(rayStart, rayEnd, {
    collisionType = nearby.COLLISION_TYPE.AnyPhysical,
    ignore = self.object,
  })

  if rayHit.hit and rayHit.hitPos then
    return rayHit.hitPos
  end
end

local HardMode = true
BasketFuncs.equipBasket = function()
  local currentEquipment = self.type.getEquipment(self)

  if not HardMode then
    if not BasketFuncs.getBasket() then
      currentEquipment[RobeSlot] = BASKET_ROBE_ID

      self.type.setEquipment(self, currentEquipment)
    end
  else
    local allowedEquipment = {}

    for slot, item in pairs(currentEquipment) do
      if HARD_MODE_ALLOWED_SLOTS[slot] then
        allowedEquipment[slot] = item
      end
    end

    allowedEquipment[RobeSlot] = BASKET_ROBE_ID

    self.type.setEquipment(self, allowedEquipment)
  end

  if not BasketFuncs.getBasket() then
    local UIMode = I.UI.getMode()
    if UIMode and UIMode == "Interface" then
      I.UI.setMode()
      ui.showMessage("You have become one with the basket. It may not be removed . . .")
    end
  end
end

BasketFuncs.forceHasBasket = function()
  local basketCount = Inventory:countOf(BASKET_ROBE_ID)

  if basketCount >= 1 then
    return
  end

  core.sendGlobalEvent("S3_BasketMode_AddBasket", self.object)
end

BasketFuncs.basketOnFrame = function(dt)
  BasketFuncs.forceHasBasket()
  BasketFuncs.equipBasket()
  BasketFuncs.handleBasketMove(dt)
end

return {
  eventHandlers = {
    S3_BasketMode_BasketToPlayer = function(basket)
      assert(basket, "Received basket assignment event with no basket!")
      myBasket = basket
    end,
  },
  engineHandlers = {
    onFrame = BasketFuncs.basketOnFrame,
    onKeyPress = function(key)
      if key.code == input.KEY.Tab and myBasket then
        MovementLocked = not MovementLocked
      end
    end,
  },
}
