---
title: Profile a Hot Path With Pr0f1l3r
summary: Start with counts/timing before reaching for trace IR.
description: A minimal Pr0f1l3r investigation sequence.
weight: 40
extra:
  kind: example
---

When a feature is slow, begin with a narrow question.

If Pr0f1l3r is installed, its interface exposes bounded profiling modes such as call counting, timing, allocation attribution, throughput windows, and JIT capture.

From a compatible runtime script:

```lua
local I = require 'openmw.interfaces'

I.pr0f1l3r.setScenario('combat-target-update')
I.pr0f1l3r.benchTime('scripts/s3/music/combatState.lua')
```

Reproduce the same workload during the capture window.

Then ask:

1. Is the function actually being called as often as assumed?
2. Is Lua time material?
3. Does memory attribution point at allocation churn?
4. Are engine-bound operations the real cost?
5. Only then: does JIT trace behavior matter?

For a broader window:

```lua
I.pr0f1l3r.benchWindow(300, 'combat-target-update')
```

Profiler facilities are diagnostic and can perturb the workload. Do not compare incompatible modes as though they were identical benchmarks.

See [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md) and [Measure First](@/cod3x/docs/performance/measure-first.md).
