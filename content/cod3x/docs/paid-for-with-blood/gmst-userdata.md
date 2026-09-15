---
title: Paid For With Blood — The Number Was Userdata
description: DreamScripts tried to remove a conversion based on semantic type; runtime representation disagreed.
weight: 60
extra:
  kind: guide
---

During a DreamScripts record-loader optimization pass, a GMST value reported a numeric semantic type. It was tempting to skip an intermediate `tostring` conversion before numeric handling.

[Commit `3523eaf`](https://github.com/DreamWeave-MP/DreamScripts/commit/3523eaf7cc14eed0ffe4f3156ba23751e8f32a5f) tried exactly that.

Seconds later, [`39ba4b1`](https://github.com/DreamWeave-MP/DreamScripts/commit/39ba4b14f837e504ad9a3cbc370a4fc73c926259) reverted it.

Then [`1e3bbc4`](https://github.com/DreamWeave-MP/DreamScripts/commit/1e3bbc42ed1b806a51cd43250d0d9e202825d43f) recorded the actual finding:

> GMST values are userdata so sadly no optimization opportunities here

## The rule

**Do not infer runtime representation from semantic meaning.**

A value can represent a number while still arriving through userdata or another wrapper that requires conversion.

Before removing conversions from engine/plugin data:

1. inspect `type(value)`;
2. inspect the binding/API contract;
3. test representative values;
4. benchmark only after correctness is established.

This is one of the cleanest examples of why `CHECK:` commits are useful. The hypothesis was cheap to test, cheap to revert, and left behind a durable fact.

Implementation at the relevant revision: [recordReader.lua at `1e3bbc4`](https://github.com/DreamWeave-MP/DreamScripts/blob/1e3bbc42ed1b806a51cd43250d0d9e202825d43f/scripts/custom/recordReader.lua). The current code is the useful comparison point; the pinned file is the evidence for what the investigation actually changed.

Sources: DreamScripts commits [`3523eaf`](https://github.com/DreamWeave-MP/DreamScripts/commit/3523eaf7cc14eed0ffe4f3156ba23751e8f32a5f), [`39ba4b1`](https://github.com/DreamWeave-MP/DreamScripts/commit/39ba4b14f837e504ad9a3cbc370a4fc73c926259), and [`1e3bbc4`](https://github.com/DreamWeave-MP/DreamScripts/commit/1e3bbc42ed1b806a51cd43250d0d9e202825d43f).

### Receipts

- Experiment: [`3523eaf`](https://github.com/DreamWeave-MP/DreamScripts/commit/3523eaf7cc14eed0ffe4f3156ba23751e8f32a5f) — remove conversion from numeric GMSTs.
- Revert: [`39ba4b1`](https://github.com/DreamWeave-MP/DreamScripts/commit/39ba4b14f837e504ad9a3cbc370a4fc73c926259) — behavior breaks.
- Finding: [`1e3bbc4`](https://github.com/DreamWeave-MP/DreamScripts/commit/1e3bbc42ed1b806a51cd43250d0d9e202825d43f) — the values are userdata.
