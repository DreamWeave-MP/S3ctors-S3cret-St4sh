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

local function basketTransform(transformData)
	local target = transformData.target
	local basket = transformData.basket
	local teleportPos = target.position

	local targetScale
	if not basket then
		basket = world.createObject(BASKET_ACTI_ID)
		local basketHeight = target:getBoundingBox().halfSize.z * 2
		local targetPos = util.vector3(teleportPos.x, teleportPos.y, teleportPos.z + basketHeight)

		basket:teleport(target.cell, targetPos)
		target:sendEvent("S3_BasketMode_BasketToPlayer", basket)

		targetScale = 0.01
	else
		basket:remove()
		targetScale = 1.0
	end

	target:setScale(targetScale)
end

local function basketMove(rollData)
	local basket = rollData.basket
	local moveThisFrame = rollData.moveThisFrame
	local rollThisFrame = rollData.rollThisFrame
	local target = rollData.target

	if not basket.cell then
		return
	elseif not basket:isValid() or basket.count == 0 then
		return
	elseif not target:isValid() or target.count == 0 then
		return
	end

	local newTargetRot = util.transform.identity * util.transform.rotateZ(target.rotation:getYaw())

	if rollThisFrame or moveThisFrame:length() > 0 then
		basket:teleport(basket.cell, basket.position + moveThisFrame, rollThisFrame)
	end

	target:teleport(basket.cell, basket.position + moveThisFrame, newTargetRot)
end

local function basketInput(inputData)
	assert(inputData.basket ~= nil, "Basket input functions should never be called without a matching basket!")
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
		S3_BasketMode_BasketUpdateCell = function(basketData)
			local basket = basketData.basket
			local owner = basketData.owner

			if basket:isValid() and basket.count > 0 then
				local newPos = util.vector3(
					owner.position.x,
					owner.position.y,
					owner.position.z + owner:getBoundingBox().halfSize.z * 2
				)

				basket:teleport(owner.cell, newPos)
			else
				print("Basket cannot be teleported!", basket)
			end
		end,
	},
}
