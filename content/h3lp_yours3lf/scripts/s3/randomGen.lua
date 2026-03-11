local bitXor, bitAnd, floor, realTime, round

do
    local math = require 'scripts.s3.math'
    floor = math.floor
    round = math.round
end

if require 'scripts.s3.isOpenMW' then
    realTime = require 'openmw.core'.getRealTime

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
local function newSeed()
    return floor(realTime() * 1000) + 1003
end

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

-- Handle both { min=X, max=Y } and direct args
---@param a integer|RangeTable
---@param b integer|boolean? optional max. If not provided, `a` should either be a RangeTable which provides the max, or a will be interpreted as the max. If true, rounds the result to the nearest whole number.
local function range(a, b)
    local min, max = a, b

    if type(a) == 'table' then
        min, max = a.min or 1, a.max
        assert(max, 'RangeTable requires a \'max\'')
    elseif type(a) == 'number' and type(b) ~= 'number' then
        max = a
        min = 1
    end

    local result = min + float() * (max - min)
    if b == true then
        return round(result)
    else
        return result
    end
end

---@class Rand
return {
    float = float,
    int = int,
    range = range,
}
