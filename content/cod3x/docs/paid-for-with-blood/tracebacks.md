---
title: Paid For With Blood — If You Catch It, Keep the Traceback
description: Protected execution that destroys the diagnostic turns one bug into two.
weight: 65
extra:
  kind: guide
---

## Paid For With Blood

DreamScripts contains multiple commits correcting essentially the same embarrassment:

- [`c8737a3`](https://github.com/DreamWeave-MP/DreamScripts/commit/c8737a31b9af36d70320bec8dc38ea0c906bfba6) — `FIX: Oops! Have to print tracebacks`
- [`0e7eb8d`](https://github.com/DreamWeave-MP/DreamScripts/commit/0e7eb8d3906af34abaa628fa338672ebc8deb75a) — `FIX: I guess we should probably actually print the traceback`

The wording is funny because the lesson is painfully ordinary.

## What went wrong

Protected execution was being used at a real host/plugin boundary, but the useful diagnostic information was not consistently reaching the developer.

Catching an error is not enough.

If the boundary is legitimate, it becomes responsible for preserving the evidence that the uncontrolled error path would have given you for free.

## The rule

When a protected boundary fails, preserve:

- the original error;
- traceback where available;
- boundary identity;
- relevant script/event/path/object identity;
- whether the operation was aborted, retried, rolled back, or fatal.

Do not turn:

```text
scripts/foo.lua:83: attempt to index field 'bar' (a nil value)
<stack>
```

into:

```text
script failed
```

That is not cleaner error handling. It is evidence destruction.

See [Error Handling](@/cod3x/docs/practice/error-handling.md).
