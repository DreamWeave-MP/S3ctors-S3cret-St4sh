---@omw-context none

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

---Moves `current` toward `target` by at most `step`, without overshooting.
---@param current number
---@param target number
---@param step number Must be positive; negative values are not validated and move away from target.
---@return number result
local function approach(current, target, step)
  local delta = target - current
  if abs(delta) <= step then
    return target
  end
  return current + (delta > 0 and step or -step)
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

---Remaps a value from one range to another, then clamps to the output range.
---@param value number
---@param inMin number
---@param inMax number Must differ from inMin; this function does not validate it.
---@param outMin number
---@param outMax number
---@return number result
local function remapClamped(value, inMin, inMax, outMin, outMax)
  local result = remap(value, inMin, inMax, outMin, outMax)
  local lo = outMin < outMax and outMin or outMax
  local hi = outMin < outMax and outMax or outMin
  return math.max(lo, math.min(hi, result))
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

---Exponential interpolation between two positive values.
---@param a number Must be positive; this function does not validate it.
---@param b number Must be positive; this function does not validate it.
---@param t number Interpolation factor; not clamped, so values outside 0..1 extrapolate.
---@return number result
local function eerp(a, b, t)
  return a * (b / a) ^ t
end

---Bounces a phase value back and forth between min and max.
---@param phase number Monotonically increasing phase/counter.
---@param inMin number Lower bound.
---@param inMax number Upper bound; must differ from inMin. This function does not validate it.
---@return number result
local function oscillate(phase, inMin, inMax)
  local range = inMax - inMin
  -- Normalize phase into [0, 2*range) and fold.
  local t = (phase - inMin) % (2 * range)
  if t > range then t = 2 * range - t end
  return inMin + t
end

---@param x number
---@return number
local function _clamp01(x)
  return x < 0 and 0 or (x > 1 and 1 or x)
end

---Returns smooth cubic interpolation over edge0..edge1.
---@param edge0 number
---@param edge1 number Must differ from edge0; reversed edges invert the ramp.
---@param x number
---@return number result
local function smoothstep(edge0, edge1, x)
  assert(edge0 ~= edge1, 'smoothstep: edge0 and edge1 must differ')
  x = _clamp01((x - edge0) / (edge1 - edge0))
  return x * x * (3 - 2 * x)
end

---Returns smoother quintic interpolation over edge0..edge1.
---@param edge0 number
---@param edge1 number Must differ from edge0; reversed edges invert the ramp.
---@param x number
---@return number result
local function smootherstep(edge0, edge1, x)
  assert(edge0 ~= edge1, 'smootherstep: edge0 and edge1 must differ')
  x = _clamp01((x - edge0) / (edge1 - edge0))
  return x * x * x * (x * (x * 6 - 15) + 10)
end

---Rounds `value` to the nearest multiple of positive `step`.
---Half steps round toward positive infinity, including negative halves.
---@param value number
---@param step number Positive step is expected; this function does not validate it.
---@return number result
local function snap(value, step)
  return floor(value / step + 0.5) * step
end


---@class H3MathLib
return {
  abs = abs,
  acos = acos,
  approach = approach,
  asin = asin,
  atan = atan,
  atan2 = atan2,
  ceil = ceil,
  clamp = clamp,
  cos = cos,
  cosh = cosh,
  deg = deg,
  eerp = eerp,
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
  oscillate = oscillate,
  pi = pi,
  pow = pow,
  rad = rad,
  random = random,
  remap = remap,
  remapClamped = remapClamped,
  round = round,
  sin = sin,
  sinh = sinh,
  smoothstep = smoothstep,
  smootherstep = smootherstep,
  snap = snap,
  sqrt = sqrt,
  tan = tan,
  tanh = tanh,
}
