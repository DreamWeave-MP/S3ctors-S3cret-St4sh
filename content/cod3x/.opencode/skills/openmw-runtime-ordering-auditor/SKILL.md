---
name: openmw-runtime-ordering-auditor
description: "OpenMW Lua event delivery, delayed actions, timers, inventory/UI mutation timing, save/load ordering, object lifetime, and cross-context runtime contracts."
---

# OpenMW Runtime Ordering Auditor

Use this skill when correctness depends on *when* OpenMW delivers events, applies mutations, runs timers/delayed actions, or makes state visible across contexts.

## Use For

- Local/global/player/menu event delivery order.
- Request/acknowledgement flows across contexts.
- Delayed actions, timers, deferred callbacks, and next-frame-style work.
- Inventory/equipment transfer timing and dependent UI redraws.
- Save/load/migration ordering.
- Object handles crossing event, timer, ownership, cell, or save/load boundaries.
- Bugs that are statically legal Lua but fail under runtime sequencing.

## Critical Rule

Runtime ordering is version- and scenario-sensitive. Do not promote an observation from one mod or OpenMW release into a universal contract unless matching engine source documents it. When correctness depends on ordering, prove it with source or a narrow runtime trace.

## Safe Design Pattern

Prefer explicit state contracts over assumed synchronous delivery:

1. Sender emits a request with a stable request ID and minimal serializable data.
2. Receiver revalidates identity, object validity, authority/ownership, and current state.
3. Receiver performs or schedules the mutation.
4. Receiver acknowledges only after the mutation is known to be applied, when an acknowledgement model exists.
5. Dependent logic redraws/recomputes from current state after the confirmed boundary.
6. Missing acknowledgement/cancellation is non-completion, not success.

Prefer stable IDs/record IDs/counts/slots/request IDs over live object references across context or delayed boundaries.

## Do Not Assume

- Sending an event means the receiving handler finished before the sender continues.
- Two handlers run in source order merely because they were triggered in source order.
- A delayed action, inventory mutation, or equipment change is immediately visible to UI.
- A live engine object remains valid across event hops, timers, save/load, cell changes, ownership transfers, or deletion.
- The requester still owns mutation authority when the receiver executes.
- Existing saves initialize state identically to new games.
- Static syntax/type validity proves sequencing safety.

## Trace Convention

When source is insufficient, use compact grep-friendly lines such as:

```text
OMWTRACE seq=12 context=player phase=request event=inventory_rebuild generation=4
OMWTRACE seq=13 context=global phase=mutate event=inventory_rebuild generation=4
OMWTRACE seq=14 context=player phase=redraw event=inventory_rebuild generation=4
```

Trace only enough fields to prove the disputed boundary. Remove instrumentation afterward unless the project intentionally keeps diagnostic logging.

## Timer Guidance

- Unsavable timers may use ordinary functions but disappear across save/load; use them only where losing the pending callback is safe.
- Reliable timers require registered callbacks and serializable arguments according to the target API.
- A zero-delay timer is not a magical universal "next frame" guarantee. If it is used as a defer barrier, verify the actual ordering required by the scenario.

## Verification

Use the repository's runtime/log assertions, lifecycle checks, event graph tools, or smoke fixtures when available. Otherwise produce the smallest manual trace plan that can prove or disprove the ordering claim.
