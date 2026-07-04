---@omw-context none
local floor, sqrt = math.floor, math.sqrt

return {
  getIndex = function(x, y)
    local xx = x >= 0 and x * 2 or x * -2 - 1
    local yy = y >= 0 and y * 2 or y * -2 - 1
    return (xx >= yy) and (xx * xx + xx + yy) or (yy * yy + xx)
  end,
  unpair = function(z)
    local sqrtz = floor(sqrt(z))
    local sqz = sqrtz * sqrtz

    local squareFirst = (z - sqz) >= sqrtz; local result1, result2

    if squareFirst then
      result1, result2 = sqrtz, z - sqz - sqrtz
    else
      result1, result2 = z - sqz, sqrtz
    end

    local xx = result1 % 2 == 0 and result1 / 2 or (result1 + 1) / -2
    local yy = result2 % 2 == 0 and result2 / 2 or (result2 + 1) / -2
    return xx, yy
  end
}
