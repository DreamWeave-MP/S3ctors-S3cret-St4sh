---@omw-context runtime
---Returns a timer function that fires true exactly once after a delay.
---A zero delay fires on the first tick call, not during construction.
---Uses real time by default, or simulation time when requested.
---
---Usage:
---  local once = require 'scripts.s3.once'
---  local intro = once(3.0)
---  local intro = once(3.0, true) -- simulation time
---
---  -- in onUpdate:
---  if intro() then playIntroSound() end

local core = require('openmw.core')

---@alias OnceTick fun(): boolean

---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return fun(): number clock
local function clock_for_simulation(simulation)
    assert(simulation == nil or type(simulation) == 'boolean', 'once: simulation flag must be boolean')
    if simulation then return core.getSimulationTime end
    return core.getRealTime
end

---Creates a timer function that fires true exactly once after a delay.
---A delay of 0 fires on the first tick call, not during construction.
---@param delay number Must be >= 0; raises otherwise.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return OnceTick tick Returns true once, then false forever.
local function once(delay, simulation)
    assert(type(delay) == 'number' and delay >= 0,
        'once: delay must be >= 0')
    local clock = clock_for_simulation(simulation)
    local start = clock()
    local fired = false
    ---@return boolean fired
    return function()
        if fired then return false end
        if clock() - start >= delay then
            fired = true
            return true
        end
        return false
    end
end

return once
