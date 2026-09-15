---
title: Protected Execution Everywhere
description: Catching failures you cannot recover from only delays the useful crash.
weight: 10
extra:
  kind: guide
---

The bad pattern looks responsible:

```lua
local ok, result = pcall(resolveEverything)
if not ok then
  print(result)
end

continueWithResult(result)
```

It is not responsible.

The resolver failed. The program now continues with an unknown partial state and less context about the original bug.

## Why people do it

`pcall` feels defensive because it prevents an immediate traceback from escaping.

That is useful only when **you can establish a valid post-failure state**.

If not, the call has merely moved the failure.

## Typical damage

Indiscriminate protected execution can:

- suppress programmer errors;
- break invariant assumptions downstream;
- replace precise tracebacks with vague log messages;
- make required dependencies appear optional;
- convert deterministic failures into intermittent state bugs;
- make tests pass while behavior silently degrades.

## The valid pattern has an explicit boundary

A better protected boundary looks like:

```lua
local results = table.pack(xpcall(runPlugin, debug.traceback))

cleanupPluginBoundary()

if not results[1] then
  error(results[2], 0)
end
```

Here the protected call exists so the host can restore an invariant and then preserve the failure.

That is categorically different from “try everything and keep going.”

## Host code versus application code

DreamScripts was a server-side script host. It had legitimate reasons to catch failures from third-party loaded chunks and turn them into controlled server shutdown/logging.

Your ordinary OpenMW feature is probably not a plugin host.

Do not import host-level fault isolation into every internal function.

## The rule

`pcall` requires a concrete, documented recovery, translation, probing, or cleanup requirement.

If you cannot name it, remove the `pcall`.

For a practical demonstration of an architecture in which protected execution is applied without meaningful discrimination, see PCallManager.
