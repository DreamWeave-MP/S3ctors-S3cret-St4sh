---@omw-context runtime
---Returns a timer function that fires true on every completed interval.
---Uses real time by default, or simulation time when requested.
---Missed intervals are coalesced: one call returns at most one true, and the
---elapsed remainder is kept with modulo arithmetic. This is a "did at least one
---interval pass?" helper, not a catch-up loop.
---
---Usage:
---  local every = require 'scripts.s3.every'
---  local tick = every(1.0)
---  local tick = every(1.0, true) -- simulation time
---
---  -- in onUpdate:
---  if tick() then ... end

local core = require('openmw.core')

---@alias EveryTick fun(): boolean

---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return fun(): number clock
local function clock_for_simulation(simulation)
    assert(simulation == nil or type(simulation) == 'boolean', 'every: simulation flag must be boolean')
    if simulation then return core.getSimulationTime end
    return core.getRealTime
end

---Creates a timer function that fires true on every completed interval.
---Missed intervals are coalesced; this is not a catch-up loop.
---@param interval number Must be > 0; raises otherwise.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return EveryTick tick One call returns at most one true.
local function every(interval, simulation)
    assert(type(interval) == 'number' and interval > 0,
        'every: interval must be > 0')
    local clock = clock_for_simulation(simulation)
    local elapsed = 0
    local last = clock()
    ---@return boolean fired
    return function()
        local now = clock()
        elapsed = elapsed + now - last
        last = now
        if elapsed >= interval then
            elapsed = elapsed % interval
            return true
        end
        return false
    end
end

return every
