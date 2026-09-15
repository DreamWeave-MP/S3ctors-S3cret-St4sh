---
title: 'Design Genealogy: ProtectedTable'
description: How composing storage-backed settings, transient state, and methods became a reusable manager interface.
weight: 90
extra:
  kind: guide
---

## The composition

OpenMW managers kept accumulating three neighboring namespaces: storage-backed settings, transient runtime fields, and methods. ProtectedTable makes them one thing.

Each source keeps its own ownership and lifetime:

| Manager member | Actual source | Role |
| --- | --- | --- |
| `manager.Enabled` | OpenMW storage section | Settings that can be read, cached, synchronized, and sometimes written. |
| `manager.state.lastUpdate` | Script-owned Lua table | Transient runtime state. |
| `manager.reset` | Methods table attached to the manager | Behavior that operates on the composed view. |

The important part is that the state namespace is transparent when reading. The setup writes through `.state`, while consumers can read the value from the manager itself:

```lua
local I = require 'openmw.interfaces'

local manager = I.S3ProtectedTable.new {
    inputGroupName = 'SettingsGlobalMyMod',
    managerName = 'MyMod',
}

manager.state.lastUpdate = 0

function manager.reset()
    manager.state.lastUpdate = 0
end

local enabled = manager.Enabled
local lastUpdate = manager.lastUpdate
if enabled and lastUpdate == 0 then
    manager.reset()
end
```

`manager.Enabled` comes from the OpenMW storage section. `manager.lastUpdate` falls through to the script-owned state table. `manager.reset` comes from the manager's method table. The three things look like one object without pretending they have the same persistence or mutation rules.

The [ProtectedTable API](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) documents the current contract. The history explains why this composition was worth keeping.

## The origin story

ProtectedTable did not begin as a general manager framework. It first had to answer small, concrete questions about what callers were allowed to put in the table and how failures should be explained:

- [`7a2580ca`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/7a2580ca2268869e8b0246135894d5ee0bbd65a8) added checks for inserting new values;
- [`94f60f76`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/94f60f766ec7f1c9ea769b9568bd1b63032f4b87) improved diagnostics and made failed inputs produce an expected value in `tostring` output;
- [`e6b7f1a2`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e6b7f1a25722bd620cf8557bb0e534fbedefcabb) made settings transparently indexable through ProtectedTable.

That third change is the real origin story. `actor.lua`, `fatigueManager.lua`, and `hitChanceManager.lua` no longer had to keep duplicate settings, or synchronize their copies with the storage section. A consumer could ask the manager for the setting and let the boundary own the lookup and cached value.

Then [`4d78a2d5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/4d78a2d594fc7e43c64a8d176111044b9452702e) hardened the metatable so its protection could not be replaced accidentally. Only after that sequence did the shape become a broadly reusable boundary, promoted as an installed interface in [`5cbc5ed6`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5cbc5ed6e2003a18c9fcc30c6e86e47403e0014a).

The path was not “specific settings guardrail, then framework.” It was composition first: remove synchronization plumbing, make the composed view safe, then give the proven boundary a stable name.

## Protection and synchronization came afterward

Composition is useful only if the sources cannot silently corrupt one another. ProtectedTable therefore accumulated rules around the composed view:

- [`36ef9e14`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/36ef9e14d2ba180befdb99a4a3e99f4d0ad41bbb) made `.state` directly readable and writable;
- [`e0122c97`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e0122c973a0f075918ee12cfddaee0d5caab62cf) allowed an existing storage section to be supplied;
- [`5d2ece29`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5d2ece2920c86ae24c8851bd94859eb1c29f5f23) allowed writes to storage groups owned by the manager when the group was writable;
- [`27c5eb07`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/27c5eb07642d64a33532b4f7e1b3e21f57741999) restored an explicit `subscribeHandler = false` option for consumers that own synchronization themselves.

The constructor also probes whether the supplied storage section is writable. That is a legitimate protected call: the attempted write is expected to fail for read-only sections, and that failure communicates the capability being queried. See [Error Handling](@/cod3x/docs/practice/error-handling.md) for the narrower rule.

The default subscription is dependency management, not decoration. [`9d5c7c2d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/9d5c7c2dbb4c566b1b52549d2d0e177758683f38) fixed cached-setting invalidation and stopped the default handler from walking an entire storage group for every individual change. The manager maintains a local view of external state, so invalidation is part of the correctness contract.

## The abstraction was right. The implementation was expensive.

Once ProtectedTable became convenient enough to sit in many paths, its contract was useful but its machinery became measurable overhead. [Pr0f1l3r](@/pr0f1l3r/index.md) showed the hot lookup path hammering LuaJIT VM operations. The answer was not to throw away the composed interface; it was to reduce the cost underneath it.

The optimization sequence attacked different parts of that cost:

- [`5f051eee`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5f051eee76be9bc7e682d9436412645ce513ec12) unrolled the `__index` loop and removed table allocations;
- [`2499548e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/2499548e7429102d837dcf8444ee28256a55c9fc) optimized ProtectedTable's lookup paths more aggressively;
- [`e6a18a18`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e6a18a181612ba7e63b2d1197a5e3d803ef3231a) completed another optimization and annotation pass.

That is the useful lesson. Do not discard an abstraction because its implementation is expensive. First establish whether the contract is wrong or merely the machinery underneath it. Keep the settings/state/method composition, then make `__index`, allocation, and lookup behavior earn their place on the hot path.

## Recognizing the earned abstraction

ProtectedTable is a good example of recognizing a reusable abstraction after the fact:

1. settings and runtime state accumulate beside one another;
2. duplicate synchronization makes the composition painful;
3. transparent lookup removes that plumbing;
4. protection and invalidation make the composition safe;
5. the stable interface names the boundary;
6. measured optimization reduces its cost without changing the boundary.

That is different from starting with `Manager:new()` and hoping a universal settings framework will emerge around it.

## What to steal

When settings, transient state, and behavior repeatedly travel together, make their sources explicit before adding a manager. Then ask whether one boundary can own the lookup, mutation rules, and invalidation without lying about the different lifetimes underneath.

See [Storage and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md), the [ProtectedTable API](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md), and the [shadow-cache invalidation scar](@/cod3x/docs/paid-for-with-blood/shadow-cache-invalidation.md).

## When not to use this

Use a plain storage section when there is no neighboring transient state, method surface, protection rule, or synchronization boundary to compose. Do not wrap a small table in a manager merely to make the code look architectural. The composition earns its existence when it removes real duplication and enforces real ownership.
