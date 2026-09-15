---
title: Clever Proxies and Magic Tables
description: Metatables can unify APIs; they can also hide every important ownership decision.
weight: 40
extra:
  kind: guide
---

Lua metatables make it easy to build an object that appears to be one table while values actually come from storage, caches, methods, generated state, or engine lookups.

Sometimes that is exactly the right abstraction.

Sometimes you have built a haunted filing cabinet.

## Historical example: Starwind `protectedTable`

The early Starwind helper presented one manager-like table whose indexing could resolve:

- cached storage values;
- fresh storage reads;
- debug/message settings;
- injected methods;
- arbitrary manager state.

Subscriptions updated or invalidated a shadow cache. `__newindex` enforced a semi-read-only contract. `__pairs` proxied storage. `__tostring` generated diagnostics.

The implementation solved several concrete problems in one place.

The cost was that `manager.foo` no longer told the reader what kind of operation `foo` represented.

## Magic hides cost

A normal field access looks cheap.

A proxy field might:

- call storage;
- allocate;
- run a metamethod;
- populate a cache;
- execute fallback logic.

That makes hot paths harder to reason about and profiler results harder to map back to source intent.

## Magic hides ownership

If arbitrary methods, mutable state, persisted settings, and derived cache entries all share one table, consumers can no longer tell which values survive reload, which are authoritative, and which may invalidate.

A little verbosity can be architectural information:

```lua
settings:get('DebugEnable')
state.currentTarget
cache:getRecord(recordId)
```

Those accesses tell you which subsystem owns the value.

## Use metatables for a narrow contract

Good uses include:

- read-only proxy/snapshot semantics;
- a small value type;
- a collection abstraction with one clear invariant;
- API compatibility where callers benefit from ordinary indexing.

Avoid piling unrelated subsystem behavior into the same metamethod surface.

## Cleverness has a carrying cost

The question is not whether you can explain the abstraction today.

The question is whether somebody can modify it safely after six months, one engine API change, and three new use cases.
