---@omw-context player

local camera = require 'openmw.camera'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local s3math = require 'scripts.s3.math'
local nullFunction = require 'scripts.s3.nullFunction'

local v3 = util.vector3

local CAMERA_CONTROL_TAG = 's3ui_inventory'
local OPEN_DURATION = 0.28
local CLOSE_DURATION = 0.2
local STATIC_CAMERA_EXTRA_DISTANCE = 15

---@class S3UI.CameraSnapshot
---@field mode any
---@field yaw number
---@field pitch number
---@field focalOffset openmw.util.Vector2
---@field position openmw.util.Vector3
---@field staticPosition openmw.util.Vector3

---@class S3UI.CameraAnimation
---@field phase 'opening'|'closing'
---@field elapsed number
---@field duration number
---@field startPosition openmw.util.Vector3
---@field targetPosition openmw.util.Vector3
---@field startYaw number
---@field targetYaw number
---@field startPitch number
---@field targetPitch number

---@type S3UI.CameraSnapshot|nil
local cameraSnapshot = nil

---@type boolean|nil
local hudVisibleSnapshot = nil

---@type S3UI.CameraAnimation|nil
local animation = nil

local M = {}

local finishRestoreCamera
local updateAnimation

---@type fun(dt: number)
local currentUpdate = nullFunction

local function clamp01(value)
	return s3math.clamp(value, 0, 1)
end

local function lerpAngle(a, b, t)
	return a + s3math.normalizeAngle(b - a) * t
end

local function saveCamera()
	if cameraSnapshot then
		return
	end
	local position = camera.getPosition()
	cameraSnapshot = {
		mode = camera.getMode(),
		yaw = camera.getYaw(),
		pitch = camera.getPitch(),
		focalOffset = camera.getFocalPreferredOffset(),
		position = position,
		staticPosition = position,
	}
end

local function disableInventoryCameraControls()
	if not I.Camera then
		return
	end
	if I.Camera.disableModeControl then
		I.Camera.disableModeControl(CAMERA_CONTROL_TAG)
	end
	if I.Camera.disableZoom then
		I.Camera.disableZoom(CAMERA_CONTROL_TAG)
	end
	if I.Camera.disableThirdPersonOffsetControl then
		I.Camera.disableThirdPersonOffsetControl(CAMERA_CONTROL_TAG)
	end
end

local function enableInventoryCameraControls()
	if not I.Camera then
		return
	end
	if I.Camera.enableThirdPersonOffsetControl then
		I.Camera.enableThirdPersonOffsetControl(CAMERA_CONTROL_TAG)
	end
	if I.Camera.enableZoom then
		I.Camera.enableZoom(CAMERA_CONTROL_TAG)
	end
	if I.Camera.enableModeControl then
		I.Camera.enableModeControl(CAMERA_CONTROL_TAG)
	end
end

---@param instant? boolean
function M.restoreCamera(instant)
	if not cameraSnapshot then
		return
	end
	if instant then
		finishRestoreCamera()
		return
	end
	animation = {
		phase = 'closing',
		elapsed = 0,
		duration = CLOSE_DURATION,
		startPosition = camera.getPosition(),
		targetPosition = cameraSnapshot.position,
		startYaw = camera.getYaw(),
		targetYaw = cameraSnapshot.yaw,
		startPitch = camera.getPitch(),
		targetPitch = cameraSnapshot.pitch,
	}
	currentUpdate = updateAnimation
end

function finishRestoreCamera()
	if not cameraSnapshot then
		animation = nil
		currentUpdate = nullFunction
		return
	end
	animation = nil
	currentUpdate = nullFunction
	enableInventoryCameraControls()

	camera.setFocalPreferredOffset(cameraSnapshot.focalOffset)
	camera.setYaw(cameraSnapshot.yaw)
	camera.setPitch(cameraSnapshot.pitch)
	camera.setMode(cameraSnapshot.mode, true)

	if cameraSnapshot.mode == camera.MODE.Static then
		camera.setStaticPosition(cameraSnapshot.staticPosition)
	end

	camera.instantTransition()
	cameraSnapshot = nil
end

---@param box table
---@param screenRight openmw.util.Vector3
---@return table
local function playerFrame(box, screenRight)
	local top = box.center.z + box.halfSize.z
	local bottom = box.center.z - box.halfSize.z
	local rightEdge = box.halfSize.x
	local leftEdge = -box.halfSize.x

	if box.vertices then
		top = -math.huge
		bottom = math.huge
		rightEdge = -math.huge
		leftEdge = math.huge

		for _, vertex in ipairs(box.vertices) do
			if vertex.z > top then
				top = vertex.z
			end
			if vertex.z < bottom then
				bottom = vertex.z
			end

			local offset = vertex - box.center
			local projectedRight = offset * screenRight
			if projectedRight > rightEdge then
				rightEdge = projectedRight
			end
			if projectedRight < leftEdge then
				leftEdge = projectedRight
			end
		end
	end

	return {
		target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
		halfHeight = (top - bottom) * 0.5,
		rightEdge = rightEdge,
		width = rightEdge - leftEdge,
	}
end

local function inventoryPose()
	local actorYaw = self.object.rotation:getYaw()
	local front = util.transform.rotateZ(actorYaw) * v3(0, 1, 0)
	local screenRight = util.transform.rotateZ(actorYaw) * v3(-1, 0, 0)
	local bodyBounds = self.object:getBoundingBox()
	local frame = playerFrame(bodyBounds, screenRight)
	local screen = ui.screenSize()
	local aspect = screen.x / screen.y
	local verticalTan = math.tan(camera.getFieldOfView() * 0.5)
	local distance = frame.halfHeight / verticalTan + STATIC_CAMERA_EXTRA_DISTANCE
	local halfViewWidth = distance * verticalTan * aspect
	local lateralOffset = halfViewWidth - frame.rightEdge - frame.width
	local pos = frame.target + front * distance - screenRight * lateralOffset

	return {
		position = pos,
		yaw = actorYaw + math.pi,
		pitch = 0,
	}
end

local function applyPose(position, yaw, pitch)
	camera.setStaticPosition(position)
	camera.setYaw(yaw)
	camera.setPitch(pitch)
end

function M.saveHudVisibility()
	if hudVisibleSnapshot ~= nil then
		return
	end
	hudVisibleSnapshot = I.UI.isHudVisible()
	I.UI.setHudVisibility(false)
end

function M.restoreHudVisibility()
	if hudVisibleSnapshot == nil then
		return
	end
	I.UI.setHudVisibility(hudVisibleSnapshot)
	hudVisibleSnapshot = nil
end

function M.showStaticInventoryCamera()
	saveCamera()
	disableInventoryCameraControls()
	local startPosition = camera.getPosition()
	local startYaw = camera.getYaw()
	local startPitch = camera.getPitch()
	local target = inventoryPose()

	camera.setMode(camera.MODE.Static, true)
	applyPose(startPosition, startYaw, startPitch)
	camera.instantTransition()
	animation = {
		phase = 'opening',
		elapsed = 0,
		duration = OPEN_DURATION,
		startPosition = startPosition,
		targetPosition = target.position,
		startYaw = startYaw,
		targetYaw = target.yaw,
		startPitch = startPitch,
		targetPitch = target.pitch,
	}
	currentUpdate = updateAnimation
end

function updateAnimation(dt)
	if not animation then
		currentUpdate = nullFunction
		return
	end

	animation.elapsed = animation.elapsed + (tonumber(dt) or 0)
	local rawT = clamp01(animation.elapsed / animation.duration)
	local t = s3math.smootherstep(0, 1, rawT)

	if animation.phase == 'opening' then
		local target = inventoryPose()
		animation.targetPosition = target.position
		animation.targetYaw = target.yaw
		animation.targetPitch = target.pitch
	end

	local position = animation.startPosition + (animation.targetPosition - animation.startPosition) * t
	applyPose(
		position,
		lerpAngle(animation.startYaw, animation.targetYaw, t),
		s3math.lerp(animation.startPitch, animation.targetPitch, t)
	)

	if rawT < 1 then
		return
	end

	if animation.phase == 'closing' then
		finishRestoreCamera()
	else
		animation = nil
		currentUpdate = nullFunction
	end
end

function M.update(dt)
	currentUpdate(dt)
end

return M
