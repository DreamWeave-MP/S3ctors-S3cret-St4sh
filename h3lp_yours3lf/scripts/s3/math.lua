local abs, acos, asin, atan, atan2, ceil,
cos, cosh, deg, exp, floor, fmod,
frexp, ldexp, log, log10, max, min, modf,
pi, pow, rad, random, sin, sinh, sqrt,
tan, tanh =
    math.abs, math.acos, math.asin, math.atan, math.atan2, math.ceil,
    math.cos, math.cosh, math.deg, math.exp, math.floor, math.fmod,
    math.frexp, math.ldexp, math.log, math.log10, math.max, math.min, math.modf,
    math.pi, math.pow, math.rad, math.random, math.sin, math.sinh, math.sqrt,
    math.tan, math.tanh

local Epsilon, HUGE = 2.2204460492503e-16, math.huge

--- @param v0 number
--- @param v1 number
--- @param t number
--- @return number result
local function lerp(v0, v1, t)
  return (1 - t) * v0 + t * v1;
end


--- @param value number
--- @param low number
--- @param high number
--- @return number result
local function clamp(value, low, high)
  if (low > high) then
    low, high = high, low
  end
  return max(low, min(high, value))
end


--- @param value number
--- @param lowIn number
--- @param highIn number
--- @param lowOut number
--- @param highOut number
--- @return number result
local function remap(value, lowIn, highIn, lowOut, highOut)
  return lowOut + (value - lowIn) * (highOut - lowOut) / (highIn - lowIn)
end


--- @param value number
--- @param digits? number
--- @return number result
local function round(value, digits)
  local mult = 10 ^ (digits or 0)

  return floor(value * mult + 0.5) / mult
end


--- @param a number
--- @param b number
--- @param absoluteTolerance? number
--- @param relativeTolerance? number
--- @return boolean result
local function isClose(a, b, absoluteTolerance, relativeTolerance)
  absoluteTolerance = absoluteTolerance or Epsilon
  relativeTolerance = relativeTolerance or 1e-9
  return abs(a - b) <= max(relativeTolerance * max(abs(a), abs(b)), absoluteTolerance)
end


local Log2 = log(2)
--- @param value number
--- @return integer result
local function nextPowerOfTwo(value)
  return pow(
    2,
    ceil(
      log(value) / Log2
    )
  )
end


local TwoPi = 2 * pi
--- Adds 2pi*k and puts the angle in range [-pi, pi].
---@param angle number
---@return number normalized
local function normalizeAngle(angle)
  local fullTurns = angle / (TwoPi) + 0.5

  return (fullTurns - floor(fullTurns) - 0.5) * (TwoPi)
end


---@class H3MathLib
return {
  abs = abs,
  acos = acos,
  asin = asin,
  atan = atan,
  atan2 = atan2,
  ceil = ceil,
  clamp = clamp,
  cos = cos,
  cosh = cosh,
  deg = deg,
  epsilon = Epsilon,
  exp = exp,
  floor = floor,
  fmod = fmod,
  frexp = frexp,
  huge = HUGE,
  isClose = isClose,
  ldexp = ldexp,
  lerp = lerp,
  log = log,
  log10 = log10,
  max = max,
  min = min,
  modf = modf,
  nextPowerOfTwo = nextPowerOfTwo,
  normalizeAngle = normalizeAngle,
  pi = pi,
  pow = pow,
  rad = rad,
  random = random,
  remap = remap,
  round = round,
  sin = sin,
  sinh = sinh,
  sqrt = sqrt,
  tan = tan,
  tanh = tanh,
}
