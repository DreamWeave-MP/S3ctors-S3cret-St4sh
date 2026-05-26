---@omw-context player

local camera = require 'openmw.camera'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v3 = util.vector3

local CAMERA_CONTROL_TAG = 's3ui_inventory'
local STATIC_CAMERA_EXTRA_DISTANCE = 15

---@class S3UI.CameraSnapshot
---@field mode any
---@field yaw number
---@field pitch number
---@field focalOffset openmw.util.Vector3
---@field staticPosition openmw.util.Vector3

---@type S3UI.CameraSnapshot|nil
local cameraSnapshot = nil

---@type boolean|nil
local hudVisibleSnapshot = nil

local M = {}

local function saveCamera()
    if cameraSnapshot then return end
    cameraSnapshot = {
        mode = camera.getMode(),
        yaw = camera.getYaw(),
        pitch = camera.getPitch(),
        focalOffset = camera.getFocalPreferredOffset(),
        staticPosition = camera.getPosition(),
    }
end

local function disableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.disableModeControl then I.Camera.disableModeControl(CAMERA_CONTROL_TAG) end
    if I.Camera.disableZoom then I.Camera.disableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.disableThirdPersonOffsetControl then I.Camera.disableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
end

local function enableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.enableThirdPersonOffsetControl then I.Camera.enableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
    if I.Camera.enableZoom then I.Camera.enableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.enableModeControl then I.Camera.enableModeControl(CAMERA_CONTROL_TAG) end
end

function M.restoreCamera()
    if not cameraSnapshot then return end
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
            if vertex.z > top then top = vertex.z end
            if vertex.z < bottom then bottom = vertex.z end

            local offset = vertex - box.center
            local projectedRight = offset * screenRight
            if projectedRight > rightEdge then rightEdge = projectedRight end
            if projectedRight < leftEdge then leftEdge = projectedRight end
        end
    end

    return {
        target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
        halfHeight = (top - bottom) * 0.5,
        rightEdge = rightEdge,
        width = rightEdge - leftEdge,
    }
end

function M.saveHudVisibility()
    if hudVisibleSnapshot ~= nil then return end
    hudVisibleSnapshot = I.UI.isHudVisible()
    I.UI.setHudVisibility(false)
end

function M.restoreHudVisibility()
    if hudVisibleSnapshot == nil then return end
    I.UI.setHudVisibility(hudVisibleSnapshot)
    hudVisibleSnapshot = nil
end

function M.showStaticInventoryCamera()
    saveCamera()
    disableInventoryCameraControls()

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

    camera.setMode(camera.MODE.Static, true)
    camera.setStaticPosition(pos)
    camera.setYaw(actorYaw + math.pi)
    camera.setPitch(0)
    camera.instantTransition()
end

return M
