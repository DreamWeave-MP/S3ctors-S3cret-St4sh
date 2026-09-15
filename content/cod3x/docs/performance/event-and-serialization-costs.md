---
title: Events, Serialization, and Boundary Traffic
description: Message passing has semantic and representation costs; reduce crossings before micro-optimizing payload syntax.
weight: 45
extra:
  kind: guide
---

Events are not free function calls with fashionable architecture.

They cross ownership boundaries, and some boundaries require serialization or engine routing.

Performance work should therefore ask both **how often** a message crosses and **what must happen because it crossed**.

## Count crossings first

A system that emits one event for each actor every frame has an architectural frequency problem before it has a payload-allocation problem.

Count:

- events per frame/update;
- recipients per event;
- payload size/shape;
- engine conversions;
- downstream work triggered by each event.

Then decide whether the boundary is necessary at that cadence.

## Prefer direct calls inside one ownership domain

If two modules already share a script/context and one directly owns the other dependency, a normal function call is usually clearer and cheaper than routing through a global event.

Use events when the boundary is real:

- context crossing;
- target-object routing;
- intentionally decoupled fan-out;
- engine-originated lifecycle notification.

See [Event Architecture](@/cod3x/docs/practice/events.md).

For same-context fan-out, H3's [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) avoids an engine event and its boundary costs. For cross-context work, the [S3maphore event contract](@/s3maphore/docs/api/events.md) is a concrete production example of keeping the payload small and the receiver ownership explicit.

## Payload shape matters after frequency

Once the number of crossings is justified, keep payloads compact and canonical.

Do not attach a large state table because it is convenient when the receiver only needs:

```lua
{
  objectId = object.id,
  generation = transitionGeneration,
}
```

Small payloads reduce serialization/conversion work and make ownership clearer.

## Snapshot versus handle

When a boundary can carry engine objects directly, that still does not mean it should.

Ask whether the receiver needs:

- a live object handle;
- stable identity to resolve later;
- a record ID;
- a value snapshot.

Choose the smallest representation that preserves semantics.

## Batch where the semantics permit it

If ten independent updates can be represented as one batch without harming latency/ownership, batching may reduce boundary overhead substantially.

Do not batch blindly. A giant batch can create frame spikes and difficult failure semantics.

Bound the batch by a latency/budget target.

## Serializing derived state is duplicated work

Persisting or transmitting caches means you pay to:

1. construct the cache;
2. serialize it;
3. deserialize it;
4. validate whether it is still correct.

If the cache is cheap to rebuild from stable authoritative inputs, transmit the inputs instead.

## Measure both sides

A sender may look cheap while the receiver performs expensive work for every message.

When profiling an event-heavy system, instrument:

- sender frequency;
- dispatch/boundary time where observable;
- receiver count;
- receiver workload.

A micro-optimization in payload construction is irrelevant if one event triggers three raycasts and a UI rebuild downstream.
