---@omw-context runtime
---Returns begin, remaining, spent functions for per-frame work budgeting.
---Useful for spreading expensive work across frames without spiking frame time.
---
---Note: budget uses core.getRealTime() (wall time) rather than getRealFrameDuration()
---because it measures actual execution time within a frame, not time between
---frames. getRealFrameDuration() tells you how long the last frame took;
---getRealTime() tells you how long your code has been running right now.
---
---Usage:
---  local budget = require 'scripts.s3.budget'
---  local begin, remaining, spent = budget(1/60 * 0.5)  -- 50% of a 60hz frame
---
---  -- in onUpdate, before doing work:
---  begin()
---
---  for _, item in ipairs(workQueue) do
---      if spent() then break end
---      process(item)
---  end

local clock = require 'openmw.core'.getRealTime

---@alias BudgetBegin fun()
---@alias BudgetRemaining fun(): number
---@alias BudgetSpent fun(): boolean

---Creates per-frame work-budget helpers using wall-clock execution time.
---@param seconds number Must be > 0; raises otherwise.
---@return BudgetBegin begin Marks the start of this budget window.
---@return BudgetRemaining remaining Returns remaining seconds, clamped to zero.
---@return BudgetSpent spent Returns true after the budget has been consumed.
local function budget(seconds)
    assert(type(seconds) == 'number' and seconds > 0,
        'budget: seconds must be > 0')
    local start

    ---@return nil
    local function begin()
        start = clock()
    end

    ---@return number
    local function remaining()
        if not start then return seconds end
        local r = seconds - (clock() - start)
        return r > 0 and r or 0
    end

    ---@return boolean
    local function spent()
        if not start then return false end
        return (clock() - start) >= seconds
    end

    return begin, remaining, spent
end

return budget
