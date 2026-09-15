---
title: StateMachine
description: Represent named runtime states with explicit callbacks and transition timing.
weight: 25
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.statemachine' → StateMachine; StateMachine.new(options?) → machine") }}

Use StateMachine when a handful of booleans have quietly turned into a state machine anyway. Give each state a name, put its enter/exit behavior in one place, and make transitions explicit.

For the smaller design that should come before this module, see Cod3x's [NullFunction to StateMachine genealogy](@/cod3x/docs/good-designs/state-machine-genealogy.md).

{% usage_note(title="Plain Lua state · Runtime only") %}
The module has no OpenMW imports and does not register an update handler.
{% end %}

## Example

```lua
local StateMachine = require 'scripts.s3.statemachine'
local camera = require 'openmw.camera'
local machine = StateMachine.new()
local targetMode

local function requestMode(mode)
    targetMode = mode
    machine:jump('switching')
end

machine:state('idle', {})
machine:state('switching', {
    on_enter = function() camera.setMode(targetMode, false) end,
    tick = function()
        if camera.getMode() == targetMode then machine:transition('idle') end
    end,
})
machine:start('idle')

return {
    eventHandlers = {
        MyModSetCameraMode = function(mode) requestMode(mode) end,
    },
    engineHandlers = {
        onUpdate = function(dt) machine:tick(dt) end,
    },
}
```

Register states before `start()`. The function shorthand is equivalent to `{ tick = fn }`. Passing `false` to `camera.setMode` lets OpenMW delay the change, so `switching` is a real intermediate state. The machine does not choose the engine callback for you.

## Transitions

| Call | Timing |
| --- | --- |
| `machine:start(name)` | Immediate initial transition; alias for `jump`. |
| `machine:jump(name)` | Immediate `on_exit` and `on_enter`. Cancels a pending transition. |
| `machine:transition(name)` | Queues one transition for the end of the current `tick`, or the next tick when called outside `tick`. |
| `machine:tick(dt)` | Calls the current state's tick, then applies the queued transition. |

Multiple deferred requests before application are last-request-wins. Transitioning to the current state restarts it: `on_exit(name)` runs before `on_enter(name)`. A state must exist before it can be selected.

Callbacks receive `on_enter(from, error)` and `on_exit(to)`. The `error` argument is supplied only when a tick failure enters a registered `error` state.

## Validation and errors

Pass `{ validate = true }` or call `machine:validate(true)` to enforce transition rules declared with `machine:allow(from, to)`. `'*'` is a wildcard source. Validation with no rules still permits transitions; once rules exist, only declared or wildcard transitions are allowed.

If the current state's `tick` raises and an `error` state exists, the machine transitions there and passes the error to `on_enter`. Without an `error` state, the error propagates. Tick-error handling does not catch errors from `on_exit` or `on_enter`.

An `on_exit` error aborts the transition before the current state changes. An `on_enter` error propagates after the current state has changed. Re-entrant `tick()` calls raise an error.

## Queries and lifetime

| Call | Result |
| --- | --- |
| `machine:current()` | Current state name, or `nil` before `start`. |
| `machine:previous()` | Previous state name, or `nil` before the first transition. |
| `machine:is(name)` | Whether the named state is current. |

The machine retains state definitions, callbacks, and one pending transition. It is runtime state, not a persistence format. Save a separate plain state name and restore it deliberately after registering the machine's states.

For explicit state ownership, derived-state invalidation, and stale deferred work, see Cod3x's [State Ownership and Invalidation](@/cod3x/docs/practice/state.md).
