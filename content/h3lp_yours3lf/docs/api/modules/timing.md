---
title: Timing Helpers
description: Choose periodic checks, cooldowns, one-shot delays, or elapsed-time measurement.
weight: 45
extra:
  kind: api
---

These helpers read OpenMW clocks; they do not install callbacks. Choose based on what missed time should mean, not merely whether you want to wait.

| Need | Module / constructor | Result |
| --- | --- | --- |
| Periodic check | `every(interval, simulation?)` | `tick()` returns whether at least one interval elapsed. |
| Rate-limit an attempted action | `cooldown(interval, simulation?)` | `canRun()` starts ready, then permits at most one success per interval. |
| One delayed action | `once(delay, simulation?)` | `tick()` returns true once after the delay. |
| Measure elapsed time | `stopwatch(simulation?)` | `start, stop, reset, elapsed, lap` functions. |
| Wait for changes to settle | [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md) | `tick, push` pair. |

Require each module as `scripts.s3.every`, `scripts.s3.cooldown`, `scripts.s3.once`, or `scripts.s3.stopwatch`.

{% usage_note(title="Clock selection is not callback scheduling") %}
The optional flag must be boolean: absent/false selects real time, true selects simulation time. Simulation time follows the engine's pause/time-scale behavior. Real time can pass while your handler is not running; work still waits for your next call. These closures are runtime state, not a built-in save system.
{% end %}

## Periodic checks

```lua
local every = require 'scripts.s3.every'
local tick = every(1, true)

return {
    engineHandlers = {
        onUpdate = function()
            if tick() then print('At least one interval elapsed') end
        end,
    },
}
```

`interval` must be greater than zero. Every starts waiting. Missed intervals coalesce into a single true result and the fractional remainder is preserved. A 3.5-second gap with interval 1 does not run your action three times; it reports once and keeps 0.5 seconds toward the next interval.

## Cooldowns and one-shot delays

```lua
local cooldown = require 'scripts.s3.cooldown'
local once = require 'scripts.s3.once'

local allowed = cooldown(0.5, true)
assert(allowed())
local firstTick = once(0, true)
assert(firstTick())
assert(not firstTick())
```

Cooldown requires a positive interval and starts ready. Each successful call discards accumulated excess time, unlike Every's preserved remainder. Call it when an action is attempted; if you poll it continuously you consume readiness continuously.

Once permits a nonnegative delay. Zero means the first tick succeeds, not that construction executes an action. Once it fires, later calls return false. Construct a new closure to start a new one-shot delay.

## Stopwatch

```lua
local stopwatch = require 'scripts.s3.stopwatch'
local start, stop, reset, elapsed, lap = stopwatch()
start()
print(elapsed())
stop()
print(lap())
reset()
assert(elapsed() == 0)
```

The stopwatch starts stopped. `start()` and `stop()` are idempotent in their respective states. Elapsed time includes completed running intervals plus the current running interval. `lap()` reports the accumulated lap duration and resets its boundary; while stopped it returns that accumulator once, then zero. `reset()` clears both accumulators and stops the watch. Reading elapsed time does not advance it; the selected clock does.

Use the [bootstrap](@/h3lp_yours3lf/docs/getting-started/overview.md) to register the periodic example and [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md) when each new input should restart the wait.
