local core = require 'openmw.core'
local util = require 'openmw.util'

local scriptContext = require 'scripts.s3.scriptContext'

local TwoPow5, TwoPow13, TwoPow17, TwoPow32 = math.pow(2, 5), math.pow(2, 13), math.pow(2, 17), math.pow(2, 32)

--- Current real time, in MS, plus a secret hash
local function newSeed()
    return math.floor(core.getRealTime() * 1000) + 1003
end

---@class Rand
local Random = {
    seed = newSeed()
}

function Random:int()
    local x = self.seed
    x = util.bitXor(x, x * TwoPow13)
    x = util.bitXor(x, x / TwoPow17)
    x = util.bitXor(x, x * TwoPow5)
    self.seed = util.bitAnd(x, 0xFFFFFFFF)
    return self.seed
end

--- Float between [0, 1)
---@return number random floating point between 1 and 0
function Random:float()
    local unsigned = self:int()
    -- Convert to unsigned explicitly
    if unsigned < 0 then unsigned = unsigned + TwoPow32 end
    return unsigned / TwoPow32 -- Always in [0, 1)
end

-- Handle both { min=X, max=Y } and direct args
---@param a integer|RangeTable
---@param b integer|true? optional max. If not provided, a should either be a RangeTable which provides the max, or a will be interpreted as the max. If true, rounds the result to the nearest whole number.
function Random:range(a, b)
    local min, max = a, b

    if type(a) == "table" then
        min, max = a.min or 1, a.max
        assert(max, "RangeTable requires a 'max'")
    elseif type(a) == 'number' and type(b) ~= 'number' then
        max = a
        min = 1
    end

    local result = min + self:float() * (max - min)
    if b == true then
        return util.round(result)
    else
        return result
    end
end

if scriptContext.get() ~= scriptContext.Types.Global then
    return {
        interfaceName = 'RandomGen',
        interface = {
            new = function()
                local copy = {}

                for k, v in pairs(Random) do
                    copy[k] = v
                end

                copy.seed = newSeed()

                return copy
            end,
            float = function()
                return Random:float()
            end,
            int = function()
                return Random:int()
            end,
            range = function(a, b)
                return Random:range(a, b)
            end
        },
    }
else
    return Random
end
