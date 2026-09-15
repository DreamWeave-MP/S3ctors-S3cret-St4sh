---
title: Paid For With Blood — A Shadow Cache Needs the Same Invalidation as Its Source
description: Overriding a subscription handler accidentally bypassed the cache invalidation that made the proxy truthful.
weight: 38
extra:
  kind: guide
---

## Paid For With Blood

Starwind Builder's historical `protectedTable` abstraction kept a local `shadowSettings` cache over a storage-backed settings group.

It also allowed the normal subscription handler to be replaced.

That flexibility created a hole: when the handler was overridden entirely, the normal path that refreshed the shadow cache no longer ran.

Commit [`25c3661`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/25c366122db8c0d96a861104b18eb47e9ebec460) added an alternate subscription whose sole job was clearing `shadowSettings` when the underlying group changed.

H3 Pattern: [ProtectedTable](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) makes the settings/runtime split visible, but a custom subscription still owns invalidation. The abstraction does not remove the dependency graph.

## What went wrong

The abstraction made two behaviors look independent:

1. what happens when storage changes;
2. how the local cache remains coherent.

They were not independent.

The cache's correctness depended on lifecycle behavior hidden inside the default subscription path.

Replace the handler, and you replaced part of the cache protocol too.

## The rule

A cache is not complete until its invalidation contract is explicit.

Ask:

- What makes this value stale?
- Who observes that event?
- Does every customization path preserve invalidation?
- Does `nil` mean absent, uncached, or intentionally cached absence?
- Can consumers tell whether the value is authoritative or derived?

If those answers live only in a metatable's fallback behavior, the abstraction is carrying too much hidden state.

See [State Ownership and Invalidation](@/cod3x/docs/practice/state.md) and [Clever Proxies and Magic Tables](@/cod3x/docs/anti-patterns/clever-proxies.md).
