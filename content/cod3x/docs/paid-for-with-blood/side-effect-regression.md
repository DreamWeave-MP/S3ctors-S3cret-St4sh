---
title: Paid For With Blood — “Nothing Changed” Still Had Work to Do
description: S3maphore skipped dependent silence state when ordinary playback kept the same playlist.
weight: 100
extra:
  kind: guide
---

Optimization and refactoring often introduce a tempting branch:

```lua
if newState == oldState then return end
```

S3maphore learned why that is not automatically safe.

Commit [`fbe9f127`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/fbe9f127c46161528b9156f9f952ca536c588f6e) fixed silence-chance handling that had stopped being applied during normal playback after an earlier change. The primary playlist state could remain unchanged while dependent playback state still required refresh.

## The rule

Before adding a “nothing changed” fast path, list every side effect attached to the transition.

State equality in one field does not prove that:

- timers are current;
- random/silence decisions are current;
- dependent caches are current;
- UI is current;
- external observers were notified;
- lifecycle bookkeeping ran.

Fast-path only the work whose preconditions you can prove.

Source: S3ctors S3cret St4sh [commit `fbe9f127`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/fbe9f127c46161528b9156f9f952ca536c588f6e).
