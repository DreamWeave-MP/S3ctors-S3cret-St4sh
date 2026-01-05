local camera = require('openmw.camera')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')

local common = require('openmw.interfaces').toolGun_p
local Mode = require('Scripts.Modes.Mode')

local function getTargetPos(scaler)
  local origin = camera.getPosition()

  local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)) or util.vector3(0, 0, 0)

  return origin + direction * scaler
end

local function getTargetCollision(object)

    local result = nearby.castRay(
        object.position,
        util.vector3(object.position.x, object.position.y, object.position.z - 15000),
        {ignore = object}
    )

    if result and result.hitPos then return util.vector3(
        result.hitPos.x,
        result.hitPos.y,
        result.hitPos.z + object:getBoundingBox().halfSize.z
    ) end
end

local function getPointCollision(objectData)

  local hitPos = objectData.hitPos

  local result = nearby.castRay(
        common.clipboard.rayHit.hitPos,
        hitPos,
        {ignore = common.clipboard.rayHit.hitObject}
    )

    if result and result.hitPos then return result.hitPos end
end

local function getAxisPosition(objectPos, currentScale)
  local origin = camera.getPosition()
  local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)) or util.vector3(0, 0, 0)
  local playerLookingAt = origin + direction * currentScale


  if common.axis.current == 'x' then
    return util.vector3(playerLookingAt.x,
                               objectPos.y,
                               objectPos.z)
  elseif common.axis.current == 'y' then
    return util.vector3(objectPos.x,
                               playerLookingAt.y,
                               objectPos.z)
  elseif common.axis.current == 'z' then
    return util.vector3(objectPos.x,
                               objectPos.y,
                               playerLookingAt.z)
  end
end

local Grab = Mode:new({
  name = "Grab",
  grabStopFn = nil,
  defaultScale = 300,
  scaleVar = 300,
  incrementor = 5,
  scaleMult = 10,
  submodeIndex = 1,
  subModes = {
    "free",
    "ground",
    "axis",
    "point"
  },
  limit = {
    low = -2500,
    high = 2500
  }
})

function Grab:input(key)
  if key.symbol == common.keys.switchMode then
    if key.withShift then
      self:setDefaults(key)
    else
      self:switchSubmode(key)
    end
  end
  self:handleAdjustments(key)
end

function Grab:func()
  local target = self.getTarget()
  local targetObject = target.hitObject
  local mode = self:getSubmode()

  if not target or
    not targetObject or
    targetObject.recordId == "player" then
    return
  end

  if mode == 'free' then
    common.grabStopFn.func = time.runRepeatedly(
      function()
        core.sendGlobalEvent("Grab", { target = targetObject, targetPos = getTargetPos(self.scaleVar) })
      end,
      time.second / 5)

  elseif mode == 'ground' then
    core.sendGlobalEvent("Grab", { target = targetObject, targetPos = getTargetCollision(targetObject) })
  elseif mode == 'axis' then

    common.grabStopFn.func = time.runRepeatedly(
      function()
        core.sendGlobalEvent("Grab", { target = targetObject, targetPos = getAxisPosition(targetObject.position, self.scaleVar) })
      end,
      time.second / 5)

  elseif mode == 'point' then

        if not common.clipboard.rayHit and targetObject then
          common.clipboard.rayHit = target
          ui.showMessage("Captured snap position for object: " .. targetObject.recordId)
          return
        end

        common.grabStopFn.func = time.runRepeatedly(
          function()
            ui.showMessage("Updating position for: " ..
              common.clipboard.rayHit.hitObject.recordId ..
              " Snapping to : " ..
              targetObject.recordId)
            core.sendGlobalEvent("Grab", { target = common.clipboard.rayHit.hitObject, targetPos = getPointCollision(target) })
          end,
          time.second / 5)

  end


end

return Grab
