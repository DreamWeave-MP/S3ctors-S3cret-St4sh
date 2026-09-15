---
title: Measure First
description: Find the layer, establish a baseline, and make one claim at a time.
weight: 10
extra:
  kind: guide
---

Optimization begins by refusing to guess.

## Ask a narrower question

Bad question:

> Why is my mod slow?

Better questions:

- Which handler consumes the most wall time?
- Is the frame spike Lua time or an engine call?
- Is memory growth retained state or allocation churn?
- How many ray casts happen per second?
- Is this function interpreted or traced?
- Is the cache reducing C++ calls or merely adding tables?
- Is the expensive path even hot in representative gameplay?

A narrow question can produce evidence.

## Establish a baseline

Before changing code, record:

- OpenMW build/version;
- runtime build;
- mod configuration;
- save/location/workload;
- frame/sample window;
- profiler mode;
- whether JIT is enabled;
- whether instrumentation itself changes behavior.

Without a baseline, “faster” becomes a feeling.

## Identify the layer

A useful triage order is:

1. **Architecture** — are you doing unnecessary work at all?
2. **Engine calls** — are expensive C++ operations repeated?
3. **Allocation/data shape** — are you creating avoidable transient values?
4. **Lua dispatch/lookup** — is hot Lua repeatedly resolving the same functions/properties?
5. **JIT behavior** — is the relevant code tracing, aborting, or side-exiting?
6. **Runtime internals** — is the bottleneck below anything mod code can reasonably fix?

Do not spend two hours shaving a local lookup from a loop that performs a ray cast every iteration.

## Remove work before making work faster

The highest-value performance commits in the St4sh frequently remove or bound work:

- lock-on logic reduced raycasts and runtime operations;
- S3maphore spreads combat polling across frames rather than checking every actor every tick;
- SSS caches repeated C++ queries for one activation batch;
- conditions are normalized once at registration/load rather than repeatedly in hot evaluation;
- bounding boxes are queried once and reused where the geometry is stable for the operation.

That usually beats micro-optimizing the Lua syntax around the same unnecessary call.

## Change one mechanism

Performance archaeology becomes useless when one commit rewrites the algorithm, changes data layout, changes runtime flags, and changes the benchmark simultaneously.

DreamScripts' history contains many `CHECK:` commits and quick reverts. That is good experimental hygiene when the commit isolates a hypothesis.

A failed experiment that can be reverted cleanly is cheaper than an optimization whose result cannot be attributed.

## Measure both isolated and real workloads

A microbenchmark answers a deliberately small question.

An in-game benchmark answers whether the result matters inside OpenMW.

You often need both.

Rubic0n's [`bench/openmw_userdata` harness](https://github.com/DreamWeave-MP/Rubic0n/tree/master/bench/openmw_userdata) explicitly isolates Sol-bound vector userdata allocation and reclamation. Its README also explicitly says that the harness does **not** reproduce OpenMW's incremental per-frame GC pacing.

That caveat is part of the benchmark, not an embarrassment.

See [Benchmarking Without Lying to Yourself](@/cod3x/docs/performance/benchmarking.md).

## Profiler overhead is part of the model

Debug hooks, trace dumpers, allocation telemetry, and logging can perturb the system being measured.

Pr0f1l3r deliberately labels which modes are valid for throughput and which are not. Its allocation-attribution mode uses a debug hook and therefore should not be treated as a clean throughput measurement.

Instrumentation that changes the workload is still useful if you know what question it can answer.

## Stop when the layer changes

Once a profile shows that the dominant cost is an engine call, further pure-Lua micro-optimization around that call has diminishing returns.

At that point either:

- call it less often;
- batch/cache the result with a correct lifetime;
- move work to a better context;
- change the engine/binding/runtime;
- accept the cost because it is necessary.

Knowing when the problem is no longer in Lua is a performance skill.
