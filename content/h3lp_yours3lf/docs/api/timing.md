---
title: Timing Helpers
description: Choose periodic checks, cooldowns, one-shot delays, or elapsed-time measurement.
weight: 45
extra:
  kind: api
---

These helpers are for code you already call from an OpenMW handler. They poll a clock; they do not schedule callbacks. Use `openmw.async` or `openmw_aux.time` when the engine should call a function later.

| Situation | Use | Result |
| --- | --- | --- |
| You already have `onUpdate`, but this check only needs to run four times a second. | `every(interval, simulation?)` | Poll `tick()`; missed periods coalesce. |
| A function may be attempted constantly, but should only succeed every 500 ms. | `cooldown(interval, simulation?)` | Poll `canRun()` when the attempt happens; it starts ready. |
| You are already polling state and need one delayed transition. | `once(delay, simulation?)` | Poll `tick()`; it becomes true once. |
| You need to measure a duration spanning several callbacks. | `stopwatch(simulation?)` | Keep `start`, `stop`, `reset`, `elapsed`, and `lap`. |
| Wait for changes to settle | [Debounce](@/h3lp_yours3lf/docs/api/packages/debounce.md) | `tick, push` pair. |

Require each module as `scripts.s3.every`, `scripts.s3.cooldown`, `scripts.s3.once`, or `scripts.s3.stopwatch`.

{% usage_note(title="Clock selection is not callback scheduling") %}
The optional flag must be boolean: absent/false selects real time, true selects simulation time. Simulation time follows pause and time scale; real time can pass while your handler is not running. These closures are runtime state, not save data.
{% end %}

## Every: poll an existing update loop

```lua
local every = require 'scripts.s3.every'
local nearby = require 'openmw.nearby'
local refresh = every(0.25, true)

return {
    engineHandlers = {
        onUpdate = function()
            if not refresh() then return end
            updateTargetMarkers(nearby.actors)
        end,
    },
}
```

`interval` must be greater than zero. Every starts waiting. Missed intervals coalesce into a single true result and the fractional remainder is preserved. A 3.5-second gap with interval 1 does not run your action three times; it reports once and keeps 0.5 seconds toward the next interval.

## Cooldown: guard an attempted action

```lua
local cooldown = require 'scripts.s3.cooldown'
local self = require 'openmw.self'

local canSend = cooldown(0.5, true)

return {
    eventHandlers = {
        MyModAttempt = function()
            if not canSend() then return end
            self:sendEvent('MyModAccepted')
        end,
    },
}
```

Cooldown requires a positive interval and starts ready. A successful call resets elapsed time and discards excess, unlike Every's preserved remainder. Call it when the action is attempted; polling it continuously makes it periodic.

## Once: a delayed boolean inside polling code

```lua
local once = require 'scripts.s3.once'
local transitionReady = once(1, true)

return {
    engineHandlers = {
        onUpdate = function()
            if transitionReady() then print('Transition is ready') end
        end,
    },
}
```

Once permits a nonnegative delay. Zero succeeds on the first tick, not at construction; after firing, later calls return false.

Once is a niche helper for code that already polls. No downstream consumer currently uses it in this repository; use `async:newUnsavableSimulationTimer()` or `openmw_aux.time.newSimulationTimer()` when a native timer makes the control flow clearer.

## Stopwatch: measure across callbacks

```lua
local stopwatch = require 'scripts.s3.stopwatch'
local start, stop, reset, elapsed = stopwatch(true)

return {
    eventHandlers = {
        MyModChargePressed = function()
            reset()
            start()
        end,
        MyModChargeReleased = function()
            stop()
            print('Charge duration:', elapsed())
        end,
    },
}
```

The stopwatch starts stopped. `start()` and `stop()` are idempotent; `reset()` clears both accumulators and stops the watch. Reading does not advance it; the selected clock does.
