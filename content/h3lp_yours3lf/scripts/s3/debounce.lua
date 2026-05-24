---@omw-context runtime
---Returns tick and push functions that together fire true only after a value
---has been stable for `wait` seconds with no new pushes.
---Uses real time by default, or simulation time when requested. The quiet
---interval starts when push(value) is called. Nothing fires unless tick() is
---called after the quiet period; push() does not schedule work by itself.
---
---Usage:
---  local debounce = require 'scripts.s3.debounce'
---  local tick, push = debounce(0.3)
---  local tick, push = debounce(0.3, true) -- simulation time
---
---  -- when input changes:
---  push(newValue)
---
---  -- in onUpdate:
---  local fired, value = tick()
---  if fired then applyValue(value) end

local core = require('openmw.core')

---@alias DebounceTick fun(): boolean, any?
---@alias DebouncePush fun(value: any)

---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return fun(): number clock
local function clock_for_simulation(simulation)
    assert(simulation == nil or type(simulation) == 'boolean', 'debounce: simulation flag must be boolean')
    if simulation then return core.getSimulationTime end
    return core.getRealTime
end

---Creates paired tick/push functions for debounced value changes.
---push() only records the pending value; tick() must be called after quiet time.
---@param wait number Must be > 0; raises otherwise.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return DebounceTick tick Returns true and the last value after quiet time elapses.
---@return DebouncePush push Restarts the quiet interval with a new value.
local function debounce(wait, simulation)
    assert(type(wait) == 'number' and wait > 0,
        'debounce: wait must be > 0')
    local clock = clock_for_simulation(simulation)
    local pushed_at = nil
    local has_pending = false
    local pending = nil

    ---@return boolean fired
    ---@return any? value
    local function tick()
        if not has_pending then return false, nil end
        if clock() - pushed_at >= wait then
            local v = pending
            pushed_at = nil
            has_pending = false
            pending = nil
            return true, v
        end
        return false, nil
    end

    ---@param value any
    ---@return nil
    local function push(value)
        pushed_at = clock()
        has_pending = true
        pending = value
    end

    return tick, push
end

return debounce
