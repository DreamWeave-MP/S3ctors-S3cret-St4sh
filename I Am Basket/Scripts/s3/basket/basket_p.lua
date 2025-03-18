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
local isBasket = false
input.registerActionHandler(
	"Sneak",
	async:callback(function(sneak)
		-- Should this happen...?
		if not BasketFuncs.getBasket() then
			print("Bailing early on basket sneak handler . . .")
			return
		end

		if not sneak then
			return
		end

		isBasket = not isBasket

		local teleportPos = BasketFuncs.getGroundPos()

		print("Teleport pos is . . . ", teleportPos)
		core.sendGlobalEvent(
			"S3_BasketMode_BasketTransform",
			{ teleportPos = teleportPos, toggle = isBasket, target = self.object }
		)
		I.Controls.overrideCombatControls(isBasket)
		I.Controls.overrideMovementControls(isBasket)
		I.Controls.overrideUiControls(isBasket)

		-- Dangerous?
		if isBasket then
			prevHudState = I.UI.isHudVisible()
			I.UI.setHudVisibility(false)
			prevCamMode = camera.getMode()
			-- Get rotation too?
			local camPos = camera.getPosition()
			camera.setMode(camera.MODE.Static)
			camera.setStaticPosition(camPos)
		else
			camera.setMode(prevCamMode)
			I.UI.setHudVisibility(prevHudState)
			-- self.controls.sneak = 0
		end
		-- if sneak then
		-- Do Something else
		-- else
		-- Do Stuff
		-- end
	end)
)

local forwardRadsPerSecond = 1.0

---@param dt float deltaTime
---@param movement integer movement on a given axis between -1 and 1
function BasketFuncs.getPerFrameRoll(dt, movement)
	return (dt * forwardRadsPerSecond) * movement
end

local MoveUnitsPerSecond = 64
local HorizontalMovementMultiplier = 0.75
BasketFuncs.getPerFrameMoveUnits = function(dt, movement, horizontal)
	local units = (dt * MoveUnitsPerSecond)
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

BasketFuncs.handleBasketMove = function(dt)
	if not isBasket then
		return
	end

	local movement = input.getRangeActionValue("MoveForward") - input.getRangeActionValue("MoveBackward")
	local sideMovement = input.getRangeActionValue("MoveRight") - input.getRangeActionValue("MoveLeft")
	local run = input.getBooleanActionValue("Run") ~= movementSettings:get("alwaysRun")

	local moveThisFrame = BasketFuncs.getPerFrameMovement(dt, sideMovement, movement)

	print("Basket forward:", movement, "Basket horizontal:", sideMovement, "Basket Run:", run)

	if movement ~= 0 or sideMovement ~= 0 then
		core.sendGlobalEvent("S3_BasketMode_BasketMove", {
			moveThisFrame = moveThisFrame,
			target = self.object,
			forwardMovement = movement,
			sideMovement = sideMovement,
			dt = dt,
		})
	end
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

	print("Ray Result", rayHit, rayHit.hit, rayHit.hitObject, rayHit.hitPos, rayHit.hitNormal)

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
		local modified = 1

		for slot, item in pairs(currentEquipment) do
			if HARD_MODE_ALLOWED_SLOTS[slot] then
				allowedEquipment[slot] = item
			else
				modified = modified + 1
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
	engineHandlers = {
		onFrame = BasketFuncs.basketOnFrame,
	},
}
