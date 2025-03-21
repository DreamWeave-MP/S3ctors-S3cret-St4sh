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
	async:callback(function(jump)
		if not canJump then
			return
		end
		print(jump)
		isJumping = true
	end)
)

local MoveUnitsPerSecond = 128
local HorizontalMovementMultiplier = 0.75

local Illusion = self.type.stats.skills.illusion(self)
local Speed = self.type.stats.attributes.speed(self)

BasketFuncs.getPerFrameMoveUnits = function(dt, movement, horizontal)
	local illusionTerm = math.min(0.75, Illusion.modified / 100)
	local speedTerm = math.min(0.25, Speed.modified / 100)

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
	local cameraOffset = util.transform.rotateZ(playerRotZ):apply(util.vector3(0, -64, 128))
	local newCameraPos = self.position + moveThisFrame + cameraOffset
	camera.setStaticPosition(newCameraPos)
	camera.setYaw(playerRotZ)
end

local ForwardRadsPerSecond = 2.5
---@param dt number deltaTime
---@param movement integer movement on a given axis between -1 and 1
function BasketFuncs.getPerFrameRoll(movement, dt)
	return (dt * ForwardRadsPerSecond) * movement
end

local xAxisLocked = false
local yAxisLocked = false
function BasketFuncs.getPerFrameRollTransform(sideMovement, forwardMovement, dt, basket)
	local side = 0
	if not input.isShiftPressed() then
		side = BasketFuncs.getPerFrameRoll(sideMovement, dt)
	end

	local forward = 0
	if not input.isAltPressed() then
		forward = BasketFuncs.getPerFrameRoll(forwardMovement, dt)
	end

	local xTransform = util.transform.rotateX(-forward)
	local yTransform = util.transform.rotateY(-side)
	return basket.rotation * yTransform * xTransform
end

function BasketFuncs.basketIsColliding(moveThisFrame, rollThisFrame)
	local basketBounds = myBasket:getBoundingBox()

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
			nearby.castRay(
				vertex,
				vertex + rollThisFrame:apply(moveThisFrame),
				{
					ignore = myBasket,
					collideType = nearby.COLLISION_TYPE.World
						+ nearby.COLLISION_TYPE.Door
						+ nearby.COLLISION_TYPE.Actor,
				}
			).hit
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

local GravityForce = 98.1 * 2
local MinDistanceToGround = 15
local DTMult = 8

local jumpDist = 0
local JumpTargetDistance = 120
local JumpPerSecond = 800
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

	-- Cast a ray downward from the center to detect the ground
	local startPos = getLowestVertex(myBasket)
	local endPos = util.vector3(startPos.x, startPos.y, startPos.z - camera.getViewDistance())

	local result = nearby.castRay(startPos, endPos, {
		ignore = myBasket,
	})

	if not result or not result.hitPos then
		-- If not down, try up
		endPos = util.vector3(startPos.x, startPos.y, startPos.z + camera.getViewDistance())
		local raiseResult = nearby.castRay(startPos, endPos, {
			ignore = myBasket,
		})

		if raiseResult.hit and raiseResult.hitPos then
			return (raiseResult.hitPos.z - startPos.z) * dt * DTMult
		else
			-- If neither up nor down, just try raising them
			return 60 * dt * DTMult
		end
	end

	-- Calculate how far we need to fall
	local distanceToGround = startPos.z - result.hitPos.z

	if math.floor(distanceToGround) <= MinDistanceToGround then
		canJump = true
		local raiseThisFrame = (MinDistanceToGround - distanceToGround) * dt * DTMult

		return math.max(0.001, raiseThisFrame)
	else
		canJump = false
	end

	-- Smooth falling using a lerp-like approach
	local fallDistance = math.min(distanceToGround, fallAcceleration)
	return -fallDistance
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

	local rollThisFrame = BasketFuncs.getPerFrameRollTransform(sideMovement, movement, dt, myBasket)

	-- Don't process z movement during collision handling, since the script will try to correct your position
	if BasketFuncs.basketIsColliding(xyMoveThisFrame, rollThisFrame) then
		print("Basket will collide with this move", xyMoveThisFrame, "bailing on XY movement")
		xyMoveThisFrame = -xyMoveThisFrame
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
			if key.code == input.KEY.Tab then
				MovementLocked = not MovementLocked
			end
		end,
	},
}
