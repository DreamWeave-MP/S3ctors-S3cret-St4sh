---@omw-context runtime
---Returns a timer function that returns true at most once per interval.
---Uses real time by default, or simulation time when requested.
---
---Call the returned function when you want to attempt the action. Calling it
---every frame turns it into a periodic timer. Starts ready so the first call
---always fires.
---
---Usage:
---  local cooldown = require 'scripts.s3.cooldown'
---  local canAttack = cooldown(0.5)
---  local canAttack = cooldown(0.5, true) -- simulation time
---
---  -- when the player attempts the action:
---  if canAttack() then doAttack() end

local core = require('openmw.core')

---@alias CooldownTick fun(): boolean

---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return fun(): number clock
local function clock_for_simulation(simulation)
    assert(simulation == nil or type(simulation) == 'boolean', 'cooldown: simulation flag must be boolean')
    if simulation then return core.getSimulationTime end
    return core.getRealTime
end

---Creates a timer function that returns true at most once per interval.
---@param interval number Must be > 0; raises otherwise.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return CooldownTick can_run Starts ready; one call returns at most one true.
local function cooldown(interval, simulation)
    assert(type(interval) == 'number' and interval > 0,
        'cooldown: interval must be > 0')
    local clock = clock_for_simulation(simulation)
    local elapsed = interval -- start ready
    local last = clock()
    ---@return boolean ready
    return function()
        local now = clock()
        elapsed = elapsed + now - last
        last = now
        if elapsed >= interval then
            elapsed = 0
            return true
        end
        return false
    end
end

return cooldown
