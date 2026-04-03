local util = require("openmw.util")
local world = require("openmw.world")

local BasketData = require("scripts.s3.basket.basketData")
local BASKET_ROBE_ID = BasketData.DefaultRobeId
local BASKET_ACTI_ID = BasketData.ActivatorId
local TransformStates = BasketData.TransformStates

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

local cellGrid = BasketData.TestInfo.cellGrid
local ExtTestCell = world.getExteriorCell(cellGrid.x, cellGrid.y) -- Above Arrile's place
local function onPlayerAddedHandler(player)
  addBasketGear(player)

  if BasketData.DoDebug then
    player:teleport(ExtTestCell, BasketData.TestInfo.position, player.rotation)
  end
end

local DelayedTeleport
local function basketTransform(transformData)
  local target = transformData.target
  local transformState = transformData.state
  local basket = transformData.basket
  local teleportPos = target.position

  assert(
    transformState == TransformStates.Start or transformState == TransformStates.End,
    "Transformation global event should only be called when the transform state is Start or End!"
  )

  local targetScale
  if transformState == TransformStates.Start then
    basket = world.createObject(BASKET_ACTI_ID)
    local basketHeight = target:getBoundingBox().halfSize.z * 2
    local targetPos = util.vector3(teleportPos.x, teleportPos.y, teleportPos.z + basketHeight)

    basket:teleport(target.cell, targetPos)

    targetScale = 0.01
    target:sendEvent("S3_BasketMode_BasketToPlayer", basket)
    -- target.type.setTeleportingEnabled(target, true)
  else
    basket:remove()
    targetScale = 1.0
    target:sendEvent("S3_BasketMode_BasketOff")
    -- DelayedTeleport = { target = target, pos = transformData.groundPos }
    -- target:teleport(target.cell, transformData.groundPos, { onGround = true })
    -- target.type.setTeleportingEnabled(target, false)
  end

  target:setScale(targetScale)
  print("Event transmitter:", target.cell, target.position)
end

local prevCell
local function basketMove(rollData)
  if DelayedTeleport then
    return
  end

  local basket = rollData.basket
  local moveThisFrame = rollData.moveThisFrame
  local rollThisFrame = rollData.rollThisFrame
  local target = rollData.target

  assert(basket ~= nil, "Cannot process basket movement event without a basket!")
  assert(target ~= nil, "Cannot process basket movement event without a target!")

  if not basket:isValid() or basket.count == 0 then
    print("basket was invalid or had count of 0")
    return
  elseif not target:isValid() or target.count == 0 then
    print("target was invalid or had count of 0")
    return
  end

  if prevCell and prevCell ~= target.cell then
    print("Movement Handler:", target, "is now in cell", target.cell)
  end

  local newTargetRot = util.transform.identity * util.transform.rotateZ(target.rotation:getYaw())

  if rollThisFrame or moveThisFrame:length() > 0 then
    basket:teleport(basket.cell, basket.position + moveThisFrame, { onGround = false, rotation = rollThisFrame })
  end

  local targetPos = util.vector3(target.position.x, target.position.y, basket.position.z) + moveThisFrame

  if not target.type.isTeleportingEnabled(target) then
    print("Target can't teleport")
  end

  target:teleport(target.cell.name, targetPos, { onGround = false, rotation = newTargetRot })
  prevCell = target.cell
end

return {
  engineHandlers = {
    onPlayerAdded = onPlayerAddedHandler,
    onUpdate = function(_)
      if DelayedTeleport then
        DelayedTeleport.target:teleport(DelayedTeleport.target.cell, DelayedTeleport.pos, { onGround = true })
        DelayedTeleport = nil
      end
    end,
  },
  eventHandlers = {
    S3_BasketMode_AddBasket = addBasketGear,
    S3_BasketMode_BasketTransform = basketTransform,
    S3_BasketMode_BasketMove = basketMove,
  },
}
