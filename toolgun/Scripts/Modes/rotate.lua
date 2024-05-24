local core = require('openmw.core')
local time = require('openmw_aux.time')
local util = require('openmw.util')

local common = require('openmw.interfaces').toolGun_p
local Mode = require('Scripts.Modes.Mode')

local Rotate = Mode:new({
  name = "Rotate",
  grabStopFn = nil,
  defaultScale = 0.0,
  scaleVar = 0.01,
  incrementor = 0.1,
  scaleMult = 10,
  limit = {
    low = -5.0,
    high = 5.0
  }
})

function Rotate:input(key)
  self:setDefaults(key)
  self:handleAdjustments(key)
end

function Rotate:getAxisTransform()
  if common.axis.current == 'x' then return util.transform.rotateX(self.scaleVar)
  elseif common.axis.current == 'y' then return util.transform.rotateY(self.scaleVar)
  elseif common.axis.current == 'z' then return util.transform.rotateZ(self.scaleVar)
  end
end

function Rotate:func()
  local target = self.getTarget()
  local targetObject = target.hitObject

  if not target or
    not targetObject or
    targetObject.recordId == "player" then return end

  common.grabStopFn.func = time.runRepeatedly(
    function()
      core.sendGlobalEvent("Rotate", {target = targetObject, rotation = self:getAxisTransform()})
    end,
    time.second / 2)

end

return Rotate
