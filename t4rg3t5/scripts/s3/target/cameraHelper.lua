local camera = require 'openmw.camera'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

CamHelper = {}

function CamHelper.isObjectBehindCamera(object)
    local cameraPos = camera.getPosition()
    local cameraForward = util.transform.identity
        * util.transform.rotateZ(camera.getYaw())
        * util.vector3(0, 1, 0)

    -- Direction vector from camera to object
    local toObject = object.position - cameraPos

    -- Normalize both vectors
    cameraForward = cameraForward:normalize()
    toObject = toObject:normalize()

    -- Calculate the dot product
    local dotProduct = cameraForward:dot(toObject)

    -- If the dot product is negative, the object is behind the camera
    return dotProduct < 0
end

local OFFSET = 1.6
local function targetPosition(object)
    local box = object:getBoundingBox()

    if types.NPC.objectIsInstance(object) then
        return object.position + util.vector3(0, 0, box.halfSize.z * OFFSET)
    else
        return box.center
    end
end

---@param object GameObject object whose position will be checked
---@return util.vector3? viewportPos If the object is onscreen, the identified screenSize position is returned. If not, then nil. Viewpos is NOT normalized.
function CamHelper.objectIsOnscreen(object)
    local checkPos = targetPosition(object)
    local viewportPos = camera.worldToViewportVector(checkPos)
    local screenSize = ui.layers[1].size

    local validX = viewportPos.x > 0 and viewportPos.x < screenSize.x
    local validY = viewportPos.y > 0 and viewportPos.y < screenSize.y
    local withinViewDistance = viewportPos.z <= camera.getViewDistance()

    if not validX or not validY or not withinViewDistance then return end

    if CamHelper.isObjectBehindCamera(object) then return end

    local normalizedX = util.remap(viewportPos.x, 0, screenSize.x, 0.0, 1.0)
    local normalizedY = util.remap(viewportPos.y, 0, screenSize.y, 0.0, 1.0)

    return util.vector3(normalizedX, normalizedY, viewportPos.z)
end

local MaxRot = math.rad(12.0)
local MaxPitchRot = math.rad(10.0)

function CamHelper.getAngleDiff(desiredYaw, desiredPitch, currentYaw, currentPitch)
    local yawDiff = util.normalizeAngle(desiredYaw - currentYaw)
    local pitchDiff = util.normalizeAngle(desiredPitch - currentPitch)

    local finalYaw = util.clamp(yawDiff * 0.6, -MaxRot, MaxRot)
    local finalPitch = util.clamp(pitchDiff * 0.4, -MaxPitchRot, MaxPitchRot)

    return finalYaw, finalPitch
end

function CamHelper.trackTarget(targetObject, shouldTrack)
    if not targetObject then return end

    local playerPos = camera.getPosition()
    local targetPos = targetPosition(targetObject)
    local toTarget = (targetPos - playerPos):normalize()

    local currentYaw = camera.getYaw()
    local currentPitch = camera.getPitch()

    local desiredYaw = math.atan2(toTarget.x, toTarget.y)
    local desiredPitch = math.atan2(-toTarget.z, math.sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y))

    local camYaw, camPitch = CamHelper.getAngleDiff(
        desiredYaw,
        desiredPitch,
        currentYaw,
        currentPitch
    )

    local eps = 0.001

    if math.abs(camYaw) >= eps then
        camera.setYaw(currentYaw + camYaw)
    end

    if math.abs(camPitch) >= eps then
        camera.setPitch(currentPitch + camPitch)
    end

    if not shouldTrack then return end

    local rotation = I.s3lf.rotation
    local playerYaw, playerPitch = CamHelper.getAngleDiff(
        desiredYaw,
        desiredPitch,
        rotation:getYaw(),
        rotation:getPitch()
    )

    if math.abs(playerYaw) >= eps then
        I.s3lf.controls.yawChange = playerYaw
    end

    if math.abs(playerPitch) >= eps then
        I.s3lf.controls.pitchChange = playerPitch
    end
end

return CamHelper
