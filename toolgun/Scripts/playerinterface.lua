local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local adjustStopFn = {}

local grabStopFn = {}

local clipboard = {}

local axis = {}

local keys = {
  scaleDown = 'z',
  scaleUp = 'x',
  switchMode = 'c'
}

local colors = {
  white = '#FFFFFF',
  green = '#35CEOC',
  warn = '#C90913'
}

local function getTarget()
  local origin = camera.getPosition()

  local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5)) or util.vector3(0, 0, 0)

  local result = nearby.castRenderingRay(
    origin,
    origin + direction * camera.getViewDistance()
    )

  if (result) then return result end
end

return {
  interfaceName = "toolGun_p",
  interface = {
    adjustStopFn = adjustStopFn,
    axis = axis,
    clipboard = clipboard,
    colors = colors,
    getTarget = getTarget,
    grabStopFn = grabStopFn,
    keys = keys
  }
}
