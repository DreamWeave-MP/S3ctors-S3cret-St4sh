---@omw-context runtime

local bitXor, bitAnd, realTime
local floor, type = math.floor, type

if require 'scripts.s3.isOpenMW' then
  realTime = require('openmw.core').getRealTime

  do
    local util = require 'openmw.util'
    bitXor = util.bitXor
    bitAnd = util.bitAnd
  end
else
  realTime = os.time

  do
    local bit = require 'bit'
    bitXor = bit.bxor
    bitAnd = bit.band
  end
end

--- Current real time, in MS, plus a secret hash
local function newSeed() return floor(realTime() * 1000) + 1003 end

local seed = newSeed()

--- The magic numbers in this, and float, are 2^13, 2^17, 2^5, 2^32
--- https://en.wikipedia.org/wiki/Xorshift
local function int()
  local x = seed
  x = bitXor(x, x * 8192)
  x = bitXor(x, x / 131072)
  x = bitXor(x, x * 32)
  seed = bitAnd(x, 0xFFFFFFFF)
  return seed
end

--- Float between [0, 1)
---@return number random floating point between 1 and 0
local function float()
  local unsigned = int()

  -- Convert to unsigned explicitly
  if unsigned < 0 then unsigned = unsigned + 4294967296 end

  return unsigned / 4294967296 -- Always in [0, 1)
end

-- Direct args only — no table path to avoid allocation in hot paths.
---@overload fun(max: integer): number
---@overload fun(max: integer, shouldRound: true): integer
---@overload fun(min: integer, max: integer): number
---@overload fun(min: integer, max: integer, shouldRound: true): integer
---@param a integer min. If b is nil, a is treated as max with min = 1.
---@param b integer|boolean? optional max. If boolean, treated as shouldRound with a as max and min = 1.
---@param c boolean? optional shouldRound when both a and b are numeric.
---@return integer|number
local function range(a, b, c)
  local min, max, shouldRound

  if type(b) == 'boolean' then
    -- range(max, true)
    min = 1
    max = a
    shouldRound = b
  elseif c then
    -- range(min, max, true)
    min = a
    max = b
    shouldRound = true
  elseif b then
    -- range(min, max)
    min = a
    max = b
    shouldRound = false
  else
    -- range(max)
    min = 1
    max = a
    shouldRound = false
  end

  if shouldRound then return floor(float() * (max - min + 1)) + min end

  return min + float() * (max - min)
end

---@class Rand
local Rand = {
  float = float,
  int = int,
  range = range,
}

return Rand
