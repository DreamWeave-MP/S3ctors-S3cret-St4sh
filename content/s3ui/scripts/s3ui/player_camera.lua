---@omw-context player

local camera = require 'openmw.camera'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local transition = require 'scripts.s3ui.inventory.transition'
local s3math = require 'scripts.s3.math'
local nullFunction = require 'scripts.s3.nullFunction'

local v3 = util.vector3
local Camera = {
	getFieldOfView = camera.getFieldOfView,
	getFocalPreferredOffset = camera.getFocalPreferredOffset,
	getMode = camera.getMode,
	getPitch = camera.getPitch,
	getPosition = camera.getPosition,
	getYaw = camera.getYaw,
	instantTransition = camera.instantTransition,
	setFocalPreferredOffset = camera.setFocalPreferredOffset,
	setMode = camera.setMode,
	setPitch = camera.setPitch,
	setStaticPosition = camera.setStaticPosition,
	setYaw = camera.setYaw,
}
local CameraMode = {
	FirstPerson = camera.MODE.FirstPerson,
	Static = camera.MODE.Static,
}
local Transform = {
	rotateZ = util.transform.rotateZ,
}
local Ui = {
	screenSize = ui.screenSize,
}
local getSelfBoundingBox = self.getBoundingBox
local ACTOR_FORWARD = v3(0, 1, 0)
local ACTOR_SCREEN_LEFT = v3(-1, 0, 0)

local CAMERA_CONTROL_TAG = 's3ui_inventory'
-- Normalized horizontal screen position for the actor center: 0 = left edge, 0.5 = center, 1 = right edge.
local INVENTORY_ACTOR_SCREEN_X = 0.8
local STATIC_CAMERA_EXTRA_DISTANCE = 15

---@class S3UI.CameraSnapshot
---@field mode any
---@field yaw number
---@field pitch number
---@field focalOffset openmw.util.Vector2
---@field position openmw.util.Vector3
---@field staticPosition openmw.util.Vector3
---@field firstPersonRestorePosition? openmw.util.Vector3

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

local function closeTargetPosition(snapshot)
	if snapshot.mode ~= CameraMode.FirstPerson then
		return snapshot.position
	end
	return snapshot.firstPersonRestorePosition or snapshot.position
end

---@param box table
---@param origin openmw.util.Vector3
---@param front openmw.util.Vector3
---@return number
local function projectedFrontDistance(box, origin, front)
	local distance = -s3math.huge

	for _, vertex in ipairs(box.vertices) do
		local projectedFront = (vertex - origin) * front
		if projectedFront > distance then
			distance = projectedFront
		end
	end

	return s3math.max(0, distance)
end

local function saveCamera()
	if cameraSnapshot then
		return
	end
	local position = Camera.getPosition()
	local mode = Camera.getMode()
	local yaw = Camera.getYaw()
	local firstPersonRestorePosition = nil

	if mode == CameraMode.FirstPerson then
		local bodyBounds = getSelfBoundingBox(self)
		local forward = Transform.rotateZ(yaw) * ACTOR_FORWARD
		firstPersonRestorePosition = position + forward * projectedFrontDistance(bodyBounds, position, forward)
	end

	cameraSnapshot = {
		mode = mode,
		yaw = yaw,
		pitch = Camera.getPitch(),
		focalOffset = Camera.getFocalPreferredOffset(),
		position = position,
		staticPosition = position,
		firstPersonRestorePosition = firstPersonRestorePosition,
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
		phase = transition.CLOSING,
		elapsed = 0,
		duration = transition.duration(transition.CLOSING),
		startPosition = Camera.getPosition(),
		targetPosition = closeTargetPosition(cameraSnapshot),
		startYaw = Camera.getYaw(),
		targetYaw = cameraSnapshot.yaw,
		startPitch = Camera.getPitch(),
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

	Camera.setFocalPreferredOffset(cameraSnapshot.focalOffset)
	Camera.setYaw(cameraSnapshot.yaw)
	Camera.setPitch(cameraSnapshot.pitch)
	Camera.setMode(cameraSnapshot.mode, true)

	if cameraSnapshot.mode == CameraMode.Static then
		Camera.setStaticPosition(cameraSnapshot.staticPosition)
	end

	Camera.instantTransition()
	cameraSnapshot = nil
end

---@param box table
---@return table
local function playerFrame(box)
	local top = -s3math.huge
	local bottom = s3math.huge

	for _, vertex in ipairs(box.vertices) do
		if vertex.z > top then
			top = vertex.z
		end
		if vertex.z < bottom then
			bottom = vertex.z
		end
	end

	return {
		target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
		halfHeight = (top - bottom) * 0.5,
	}
end

local function inventoryPose()
	local actorYaw = self.rotation:getYaw()
	local actorFacing = Transform.rotateZ(actorYaw)
	local front = actorFacing * ACTOR_FORWARD
	local screenRight = actorFacing * ACTOR_SCREEN_LEFT
	local bodyBounds = getSelfBoundingBox(self)
	local frame = playerFrame(bodyBounds)
	local screen = Ui.screenSize()
	local aspect = screen.x / screen.y
	local verticalTan = s3math.tan(Camera.getFieldOfView() * 0.5)
	local distance = frame.halfHeight / verticalTan + STATIC_CAMERA_EXTRA_DISTANCE
	local halfViewWidth = distance * verticalTan * aspect
	local lateralOffset = (INVENTORY_ACTOR_SCREEN_X * 2 - 1) * halfViewWidth
	local pos = frame.target + front * distance - screenRight * lateralOffset

	return {
		position = pos,
		yaw = actorYaw + s3math.pi,
		pitch = 0,
	}
end

local function applyPose(position, yaw, pitch)
	Camera.setStaticPosition(position)
	Camera.setYaw(yaw)
	Camera.setPitch(pitch)
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
	local startPosition = Camera.getPosition()
	local startYaw = Camera.getYaw()
	local startPitch = Camera.getPitch()
	local target = inventoryPose()

	Camera.setMode(CameraMode.Static, true)
	applyPose(startPosition, startYaw, startPitch)
	Camera.instantTransition()
	animation = {
		phase = transition.OPENING,
		elapsed = 0,
		duration = transition.duration(transition.OPENING),
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
	local t = transition.progress(animation.phase, rawT)

	if animation.phase == transition.OPENING then
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

	if animation.phase == transition.CLOSING then
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
