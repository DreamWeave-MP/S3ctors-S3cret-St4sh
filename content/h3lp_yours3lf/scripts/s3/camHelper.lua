---@omw-context player

local Forward, GetCamPosition, GetCamYaw, GetViewDistance, IdentityTransform, IsNPC, Remap, RotateZ, ScreenSize, Vector3, Vector3Dot, Vector3Normalize, WorldToViewport

local NPC_HEIGHT_OFFSET = 1.6

do
  local camera = require 'openmw.camera'
  GetCamPosition, GetCamYaw, GetViewDistance, WorldToViewport =
    camera.getPosition, camera.getYaw, camera.getViewDistance, camera.worldToViewportVector

  local types = require 'openmw.types'
  IsNPC = types.NPC.objectIsInstance

  local ui = require 'openmw.ui'
  ScreenSize = ui.screenSize

  ---@class mathlib
  --- Optional integration with Rubic0n math extensions
  ---@field remap fun(value: number, lowin: number, highin: number, lowout: number, highout: number): number

  local util = require 'openmw.util'
  Remap, RotateZ, Vector3 = math.remap or util.remap, util.transform.rotateZ, util.vector3

  Forward = Vector3(0, 1, 0)
  Vector3Dot, Vector3Normalize = Forward.dot, Forward.normalize
end

---@param position openmw.util.Vector3
---@return boolean
local function isPositionBehindCamera(position)
  local cameraPos = GetCamPosition()
  local cameraForward = RotateZ(GetCamYaw()) * Forward

  -- Direction vector from camera to object
  local toObject = position - cameraPos

  -- Normalize both vectors
  cameraForward, toObject = Vector3Normalize(cameraForward), Vector3Normalize(toObject)

  -- Calculate the dot product
  local dotProduct = Vector3Dot(cameraForward, toObject)

  -- If the dot product is negative, the object is behind the camera
  return dotProduct < 0
end

---@param object openmw.Object
---@param position openmw.util.Vector3
local function targetPosition(object, position)
  local box = object:getBoundingBox()

  if IsNPC(object) then
    return Vector3(position.x, position.y, position.z + box.halfSize.z * NPC_HEIGHT_OFFSET)
  else
    return box.center
  end
end

---@param object openmw.Object object whose position will be checked
---@return openmw.util.Vector3? viewportPos If the object is onscreen, the identified screenSize position is returned. If not, then nil. Viewpos is NOT normalized.
local function objectIsOnscreen(object)
  local objectPos = object.position

  local checkPos = targetPosition(object, objectPos)
  local viewportPos = WorldToViewport(checkPos)
  local screenSize = ScreenSize()

  local viewX, viewY, viewZ, screenX, screenY =
    viewportPos.x, viewportPos.y, viewportPos.z, screenSize.x, screenSize.y

  local validX = viewX > 0 and viewX < screenX
  local validY = viewY > 0 and viewY < screenY
  local withinViewDistance = viewZ <= GetViewDistance()

  if not validX or not validY or not withinViewDistance then return end

  if isPositionBehindCamera(checkPos) then return end

  local normalizedX = Remap(viewX, 0, screenX, 0.0, 1.0)
  local normalizedY = Remap(viewY, 0, screenY, 0.0, 1.0)

  return Vector3(normalizedX, normalizedY, viewZ)
end

--- Player-scoped interface for easily determining whether an
--- object is onscreen or not.
---@class H3CamHelperInterface
local Interface = {
  isPositionBehindCamera = isPositionBehindCamera,
  objectIsOnscreen = objectIsOnscreen,
  targetPosition = targetPosition,
  version = 2,
}

---@class openmw.interfaces
---@field S3CamHelper H3CamHelperInterface

return {
  interfaceName = 'S3CamHelper',
  interface = Interface,
}
