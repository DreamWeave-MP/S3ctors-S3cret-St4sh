local Mode = require('Scripts.Modes.Mode')

local Scale = Mode:new({
  name = "Scale",
  shouldRepeat = true,
  defaultScale = 1.0,
  scaleVar = 1.0,
  incrementor = 0.01,
  scaleMult = 10,
  limit = {
    low = -20,
    high = 20
  }
})

function Scale:input(key)
  self:setDefaults(key)
  self:handleAdjustments(key)
end

function Scale:auxD()
  return self.scaleVar
end

return Scale
