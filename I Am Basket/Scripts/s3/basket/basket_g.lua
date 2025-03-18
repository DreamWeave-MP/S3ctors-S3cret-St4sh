local core = require("openmw.core")
local util = require("openmw.util")
local world = require("openmw.world")

local BASKET_ROBE_ID = "s3_basket_gear"
local BASKET_ACTI_ID = "s3_basket_transform"

local function addBasketGear(actor)
  local actorInventory = actor.type.inventory(actor)
  local basketRobeCount = actorInventory:countOf(BASKET_ROBE_ID)

  if basketRobeCount == 1 then
    return
  elseif basketRobeCount > 1 then
    local basketRobes = actorInventory:find(BASKET_ROBE_ID)
    basketRobes:remove(basketRobeCount - 1)
    return
  end

  local newBasket = world.createObject(BASKET_ROBE_ID)
  newBasket:moveInto(actorInventory)
end

local function onPlayerAddedHandler(player)
  addBasketGear(player)
end

local basketObject
local function basketTransform(transformData)
  local target = transformData.target
  local toggle = transformData.toggle
  local teleportPos = transformData.teleportPos

  assert(basketObject == nil == toggle, "BasketObject state should match the toggle state!")

  local targetScale
  if toggle then
    basketObject = world.createObject(BASKET_ACTI_ID)
    local basketHeight = basketObject:getBoundingBox().halfSize.z
    local targetPos = util.vector3(teleportPos.x, teleportPos.y, teleportPos.z + basketHeight)

    basketObject:teleport(target.cell, targetPos)

    targetScale = 0.01
  else
    basketObject:remove()
    basketObject = nil
    targetScale = 1.0
  end

  target:setScale(targetScale)
end

local ForwardRadsPerSecond = 1.0
---@param dt float deltaTime
---@param movement integer movement on a given axis between -1 and 1
local function getPerFrameRoll(movement, dt)
  return (dt * ForwardRadsPerSecond) * movement
end

local MoveUnitsPerSecond = 64
local HorizontalMovementMultiplier = 0.75
local function getPerFrameMoveUnits(dt, movement, horizontal)
  local units = (dt * MoveUnitsPerSecond)
  if horizontal then
    units = units * HorizontalMovementMultiplier
  end
  return units * movement
end

local function basketMove(rollData)
  local side = getPerFrameRoll(rollData.sideMovement, rollData.dt)
  local forward = getPerFrameRoll(rollData.forwardMovement, rollData.dt)

  local xTransform = util.transform.rotateX(-side)
  local yTransform = util.transform.rotateY(-forward)
  local newTransform = basketObject.rotation * yTransform * xTransform

  local horizontalMovement = getPerFrameMoveUnits(rollData.dt, rollData.sideMovement, true)
  local forwardMovement = getPerFrameMoveUnits(rollData.dt, rollData.forwardMovement, false)
  print("Horizontal", horizontalMovement, "Forward", forwardMovement)

  -- Get the Z rotation of the player inside the basket
  local zRot, _, _ = rollData.target.rotation:getAnglesZYX()
  -- Construct a transform composed of only this rotation
  local zAdjustedTransform = util.transform.identity * util.transform.rotateZ(zRot)
  -- Get corresponding forward + side vectors
  local forwardVector = zAdjustedTransform:apply(util.vector3(0, 1, 0))
  local sideVector = zAdjustedTransform:apply(util.vector3(1, 0, 0))

  -- Apply the distances to each rotation vector
  local forwardMovementVector = forwardVector * forwardMovement
  local sideMovementVector = sideVector * horizontalMovement

  -- Actually apply the new positions to both entities
  local newBasketPos = basketObject.position + forwardMovementVector + sideMovementVector
  local newTargetPos = rollData.target.position + forwardMovementVector + sideMovementVector

  -- Move them
  basketObject:teleport(basketObject.cell, newBasketPos, newTransform)
  rollData.target:teleport(rollData.target.cell, newTargetPos)
end

local function basketInput(inputData)
  assert(basketObject ~= nil, "Basket input functions should never be called without a matching basket!")
  basketMove(inputData)
end

return {
  engineHandlers = {
    onPlayerAdded = onPlayerAddedHandler,
  },
  eventHandlers = {
    S3_BasketMode_AddBasket = addBasketGear,
    S3_BasketMode_BasketTransform = basketTransform,
    S3_BasketMode_BasketMove = basketInput,
  },
}
