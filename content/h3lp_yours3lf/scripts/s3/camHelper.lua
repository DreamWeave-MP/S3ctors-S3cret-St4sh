local camera = require 'openmw.camera'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local function isObjectBehindCamera(object)
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
local function objectIsOnscreen(object)
    local checkPos = targetPosition(object)
    local viewportPos = camera.worldToViewportVector(checkPos)
    local screenSize = ui.screenSize()

    local validX = viewportPos.x > 0 and viewportPos.x < screenSize.x
    local validY = viewportPos.y > 0 and viewportPos.y < screenSize.y
    local withinViewDistance = viewportPos.z <= camera.getViewDistance()

    if not validX or not validY or not withinViewDistance then return end

    if isObjectBehindCamera(object) then return end

    local normalizedX = util.remap(viewportPos.x, 0, screenSize.x, 0.0, 1.0)
    local normalizedY = util.remap(viewportPos.y, 0, screenSize.y, 0.0, 1.0)

    return util.vector3(normalizedX, normalizedY, viewportPos.z)
end

return {
    interfaceName = 'S3CamHelper',
    interface = {
        isObjectBehindCamera = isObjectBehindCamera,
        objectIsOnscreen = objectIsOnscreen,
        targetPosition = targetPosition,
    }
}
