---@omw-context runtime
---Returns a function that produces a smoothly cycling 0..1 value.
---Uses real time by default, or simulation time when requested.
---
---The phase is based on selected-clock elapsed time since this oscillator was
---created: calling pulse() reads the selected absolute clock, subtracts the
---captured start time, and maps that elapsed time onto the requested period.
---
---Neither mode uses frame duration APIs. Calling pulse() more or less often
---does not advance the phase; only the selected clock does. Real mode is useful
---for presentation-only effects. Simulation mode follows pause and time scale.
---
---Do not treat oscillator phase as savegame-significant state unless the caller
---owns reconstruction from persisted inputs.
---
---Usage:
---  local oscillator = require 'scripts.s3.oscillator'
---  local pulse = oscillator(2.0)   -- 2-second period
---  local pulse = oscillator(2.0, true) -- simulation time
---
---  -- in onUpdate:
---  local smooth, linear = pulse()
---  setAlpha(smooth)   -- sine-curved 0..1, smooth for fades
---                     -- linear is raw 0..1 phase (sawtooth)

local core = require('openmw.core')
local sin, pi = math.sin, math.pi
local TAU = 2 * pi

---@alias OscillatorTick fun(): number, number

---Creates a smooth oscillator over the selected absolute clock.
---@param period number Must be > 0; raises otherwise.
---@param simulation? boolean Omit or false for real time; true for simulation time.
---@return OscillatorTick pulse Returns smooth sine value and raw sawtooth phase.
local function oscillator(period, simulation)
    assert(type(period) == 'number' and period > 0,
        'oscillator: period must be > 0')

    assert(simulation == nil or type(simulation) == 'boolean', 'oscillator: simulation flag must be boolean')
    local clock = simulation and core.getSimulationTime or core.getRealTime
    local start = clock()

    ---@return number smooth
    ---@return number phase
    return function()
        local phase = ((clock() - start) / period) % 1
        local smooth = (sin(phase * TAU - pi * 0.5) + 1) * 0.5
        return smooth, phase
    end
end

return oscillator
