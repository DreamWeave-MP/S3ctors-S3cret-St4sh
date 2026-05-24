---@omw-context runtime
---Returns start, stop, reset, elapsed, lap functions over one stopwatch state.
---Uses real time by default, or simulation time when requested.
---
---Real mode measures wall-clock elapsed seconds with core.getRealTime(); it is
---not game-time scaled. Simulation mode follows engine simulation time with
---core.getSimulationTime(), including pause and time-scale behavior.
---
---Neither mode uses frame duration APIs. Calling elapsed() or lap() more or
---less often does not advance the stopwatch; only the selected clock does.
---No tick function is required.
---
---Usage:
---  local stopwatch = require 'scripts.s3.stopwatch'
---  local start, stop, reset, elapsed, lap = stopwatch()
---  local start, stop, reset, elapsed, lap = stopwatch(true) -- simulation time
---
---  start()
---  elapsed()   -- total seconds, including current running interval
---  lap()       -- seconds since previous lap/reset/start boundary
---  stop()
---  lap()       -- stopped lap accumulator; returns once, then resets to 0
---  reset()     -- zeroes everything and stops

local core = require('openmw.core')

---@alias StopwatchStart fun()
---@alias StopwatchStop fun()
---@alias StopwatchReset fun()
---@alias StopwatchElapsed fun(): number
---@alias StopwatchLap fun(): number

---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return fun(): number clock
local function clock_for_simulation(simulation)
    assert(simulation == nil or type(simulation) == 'boolean', 'stopwatch: simulation flag must be boolean')
    if simulation then return core.getSimulationTime end
    return core.getRealTime
end

---Creates a stopwatch over the selected absolute clock.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return StopwatchStart start Starts if stopped; no-op if already running.
---@return StopwatchStop stop Stops if running; no-op if already stopped.
---@return StopwatchReset reset Zeroes accumulated state and stops.
---@return StopwatchElapsed elapsed Returns total elapsed seconds.
---@return StopwatchLap lap Returns time since previous lap/reset/start boundary.
local function stopwatch(simulation)
    local clock = clock_for_simulation(simulation)
    local elapsed_before_start = 0
    local lap_before_start = 0
    ---@type number?
    local started_at
    ---@type number?
    local lap_started_at

    ---@return nil
    local function start()
        if started_at then return end
        local now = clock()
        started_at = now
        lap_started_at = now
    end

    ---@return nil
    local function stop()
        if not started_at then return end
        local now = clock()
        elapsed_before_start = elapsed_before_start + now - started_at
        lap_before_start = lap_before_start + now - lap_started_at
        started_at = nil
        lap_started_at = nil
    end

    ---@return nil
    local function reset()
        elapsed_before_start = 0
        lap_before_start = 0
        started_at = nil
        lap_started_at = nil
    end

    ---@return number
    local function elapsed()
        if not started_at then return elapsed_before_start end
        return elapsed_before_start + clock() - started_at
    end

    ---While running, returns time since the previous lap/reset/start boundary
    ---and moves that boundary to now. While stopped, returns the stopped lap
    ---accumulator once, then clears it.
    ---@return number
    local function lap()
        if started_at then
            local now = clock()
            local lap_time = lap_before_start + now - lap_started_at
            lap_before_start = 0
            lap_started_at = now
            return lap_time
        end

        local lap_time = lap_before_start
        lap_before_start = 0
        return lap_time
    end

    return start, stop, reset, elapsed, lap
end

return stopwatch
