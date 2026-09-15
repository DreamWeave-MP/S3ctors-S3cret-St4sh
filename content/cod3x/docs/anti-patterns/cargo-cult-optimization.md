---
title: Cargo-Cult Optimization
description: A fast-looking source transformation is not evidence that the workload got faster.
weight: 50
extra:
  kind: guide
---

Performance folklore spreads because the advice is often locally true.

The failure is applying it without the mechanism.

## “Locals are faster”

Often true enough in hot Lua code.

Not a reason to alias every standard function in initialization code.

If the path spends 99% of its time in an engine query, localizing `math.max` will not save it.

## “Numeric loops are faster”

Often a good hot-path choice for dense arrays under LuaJIT.

Not a reason to replace clear iteration over non-hot collections or to pretend sparse tables are sequences.

## “Cache it”

Correct when the underlying call is expensive and the value has a clear semantic lifetime.

Wrong when the cache never invalidates, retains userdata indefinitely, or stores the wrong abstraction.

## “Avoid tostring/boxing/conversion”

DreamScripts tried to skip a conversion for GMST values that were semantically numeric.

Runtime inspection showed the values were userdata and the conversion was required.

Source-level meaning did not match representation.

## “FFI will make strings cheaper”

DreamScripts experimented with FFI string construction/intering behavior, reverted it, investigated, and later revisited the technique after isolating a different bug in the attempted implementation.

The lesson is not that FFI strings are good or bad.

The lesson is that **the first failed experiment did not prove the hypothesis wrong, and the initial hypothesis did not prove the implementation right.**

## “Lower-level must be faster”

Rubic0n reverted userdata cache experiments after testing.

Runtime allocation caches add metadata, branches, retention, locality effects, and interaction with GC/finalization. The optimization has a workload, not a moral direction.

## Make the hypothesis falsifiable

A useful optimization commit can say:

> This avoids X operation in Y hot path. Under workload Z, metric M should improve without changing N.

Then measure it.

If it loses, revert it and keep the lesson.
