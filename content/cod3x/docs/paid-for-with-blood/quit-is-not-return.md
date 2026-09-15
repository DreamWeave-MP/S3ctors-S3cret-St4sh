---
title: Paid For With Blood — Quitting Is Not Returning
description: Requesting OpenMW shutdown does not terminate the current Lua control flow immediately.
weight: 30
extra:
  kind: guide
---

`core.quit()` does not mean the next Lua statement cannot execute.

That distinction produced [commit `e3e21b64`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3e21b642728d07de2b0ae7565b7aa4a3e2766d9):

> We need to early-return when quitting since it's not immediate

## The rule

If your local control flow must stop, stop it.

```lua
if fatalState then
  core.quit()
  return
end
```

Do not assume that an engine request has the same semantics as `error`, `return`, or process termination.

This generalizes beyond quitting: engine state changes may be scheduled or become visible on a later frame. Read the contract rather than inferring synchronous behavior from the verb.

Source: S3ctors S3cret St4sh [commit `e3e21b64`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3e21b642728d07de2b0ae7565b7aa4a3e2766d9).
