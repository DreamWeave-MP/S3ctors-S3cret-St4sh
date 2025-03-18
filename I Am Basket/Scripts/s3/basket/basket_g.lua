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

local ForwardRadsPerSecond = 1.5
---@param dt number deltaTime
---@param movement integer movement on a given axis between -1 and 1
local function getPerFrameRoll(movement, dt)
  return (dt * ForwardRadsPerSecond) * movement
end

local function getPerFrameRollTransform(rollData)
  local side = getPerFrameRoll(rollData.sideMovement, rollData.dt)
  local forward = getPerFrameRoll(rollData.forwardMovement, rollData.dt)

  local xTransform = util.transform.rotateX(-side)
  local yTransform = util.transform.rotateY(-forward)
  return basketObject.rotation * yTransform * xTransform
end

local function basketMove(rollData)
  local newTransform = getPerFrameRollTransform(rollData)

  -- Actually apply the new positions to both entities
  local newBasketPos = basketObject.position + rollData.moveThisFrame
  local newTargetPos = rollData.target.position + rollData.moveThisFrame

  if not basketObject.cell then
    return
  elseif not basketObject:isValid() or basketObject.count == 0 then
    return
  elseif not rollData.target:isValid() or rollData.target.count == 0 then
    return
  end

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
