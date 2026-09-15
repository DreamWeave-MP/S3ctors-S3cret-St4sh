---
title: Paid For With Blood — The Userdata Cache Was Not Free
description: Rubic0n added allocator/finalizer userdata caches, then removed the experiment wholesale.
weight: 90
extra:
  kind: guide
---

Rubic0n went below Lua source and experimented with caching exact-size userdata allocations and userdata finalizer lookup during sweep.

The work was nontrivial. It added runtime fields, GC integration, tests, and hundreds of lines of cache-specific behavior.

Then [commit `edb8fe9c`](https://github.com/DreamWeave-MP/Rubic0n/commit/edb8fe9cda93fa242b891efdad5fda92ca9b4254) removed the experiment.

The revert deleted more than five hundred lines across the runtime and test suite.

## The rule

**Lower-level is not synonymous with faster.**

An allocator/runtime cache changes:

- metadata cost;
- branch behavior;
- memory retention;
- locality;
- fragmentation;
- GC interaction;
- finalizer behavior;
- worst-case paths.

You do not get to infer the result from the source diff.

Benchmark the intended workload. Keep the revert cheap. Delete a clever optimization when it does not earn its complexity.

Source: Rubic0n [commit `edb8fe9c`](https://github.com/DreamWeave-MP/Rubic0n/commit/edb8fe9cda93fa242b891efdad5fda92ca9b4254).
