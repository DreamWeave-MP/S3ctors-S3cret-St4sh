---
title: Paid For With Blood — Cache the Result, Not the Machinery
description: DreamScripts cached compiled chunks where callers expected loaded module values.
weight: 80
extra:
  kind: guide
---

DreamScripts' script loader originally cached an intermediate compiled chunk and executed it again when serving a cached module.

Commit [`28062542`](https://github.com/DreamWeave-MP/DreamScripts/commit/28062542ca4e8f0eecc65237264aa2b13c44e8d1) changed the cache to store the module's returned value instead.

That was necessary for correct hot-reload/module behavior.

## The rule

A cache should preserve the semantics of the operation it replaces.

If callers ask for a loaded module, cache the loaded module unless the contract explicitly says re-execution is part of lookup.

If callers ask for parsed metadata, cache parsed metadata, not a file handle that happens to be able to recreate it.

Intermediate representations are implementation details until the public contract says otherwise.

Source: DreamScripts [commit `28062542`](https://github.com/DreamWeave-MP/DreamScripts/commit/28062542ca4e8f0eecc65237264aa2b13c44e8d1).

H3 Pattern: [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md) documents the layer being cached, key identity, absence handling, and retention contract explicitly.
