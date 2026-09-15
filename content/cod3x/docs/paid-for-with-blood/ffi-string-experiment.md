---
title: Paid For With Blood — The FFI String Was Not the Bug
description: Revert the experiment, isolate the failure, then reapply only what the evidence supports.
weight: 70
extra:
  kind: guide
---

DreamScripts' record-reader performance work experimented with using FFI strings in record-loading paths.

The sequence is more useful than the final technique:

- [`1db40db`](https://github.com/DreamWeave-MP/DreamScripts/commit/1db40dbe9c9670ecd9723aa07ff578f368f65640) tried FFI strings;
- follow-up commits expanded the experiment;
- [`b575991`](https://github.com/DreamWeave-MP/DreamScripts/commit/b5759916ca9b8813f6b83594d454d37e8299d7d0), [`7ef025c`](https://github.com/DreamWeave-MP/DreamScripts/commit/7ef025c1a3dcf386fbece91fad26b222d21db88f), and [`d171ef4`](https://github.com/DreamWeave-MP/DreamScripts/commit/d171ef4b4652a79ffa1e149a438eaf00483f2feb) reverted the group;
- [`ad910b8`](https://github.com/DreamWeave-MP/DreamScripts/commit/ad910b8b13620cf1437bb7457581a252b4a82a41) and related commits reapplied it;
- [`9f569d0`](https://github.com/DreamWeave-MP/DreamScripts/commit/9f569d0848b191b8a101b6c884f6cc57e5166e23) identified that the FFI strings themselves were not the problem — an incorrect second argument was.

## Why this matters

It is easy to tell the wrong story after a failed optimization:

> We tried FFI. It broke. FFI is bad.

The history supported a narrower conclusion:

> This implementation broke. Revert it. Isolate the failure. The original mechanism may or may not be guilty.

## The rule

**A failed implementation does not falsify every underlying hypothesis, and a plausible hypothesis does not excuse a broken implementation.**

Use small commits, reverts, instrumentation, and reproduction to separate them.

The commit history should preserve the uncertainty while the investigation is active. Do not rewrite the story afterward as though the answer was obvious.

Read the [initial record reader](https://github.com/DreamWeave-MP/DreamScripts/blob/1db40dbe9c9670ecd9723aa07ff578f368f65640/scripts/custom/recordReader.lua) and the [reapplied implementation](https://github.com/DreamWeave-MP/DreamScripts/blob/ad910b8b13620cf1437bb7457581a252b4a82a41/scripts/custom/recordReader.lua) alongside the [full evolution compare](https://github.com/DreamWeave-MP/DreamScripts/compare/1db40dbe9c9670ecd9723aa07ff578f368f65640...ad910b8b13620cf1437bb7457581a252b4a82a41).

Sources: DreamScripts commits [`1db40db`](https://github.com/DreamWeave-MP/DreamScripts/commit/1db40dbe9c9670ecd9723aa07ff578f368f65640), [`b575991`](https://github.com/DreamWeave-MP/DreamScripts/commit/b5759916ca9b8813f6b83594d454d37e8299d7d0), [`7ef025c`](https://github.com/DreamWeave-MP/DreamScripts/commit/7ef025c1a3dcf386fbece91fad26b222d21db88f), [`d171ef4`](https://github.com/DreamWeave-MP/DreamScripts/commit/d171ef4b4652a79ffa1e149a438eaf00483f2feb), [`ad910b8`](https://github.com/DreamWeave-MP/DreamScripts/commit/ad910b8b13620cf1437bb7457581a252b4a82a41), and [`9f569d0`](https://github.com/DreamWeave-MP/DreamScripts/commit/9f569d0848b191b8a101b6c884f6cc57e5166e23).

### Provenance chain

Experiment → breakage → revert → investigation → actual cause → reapplication. Read the commits in that order; the point is not that the first optimization was foolish, but that it was reapplied only after the real failure was isolated.
