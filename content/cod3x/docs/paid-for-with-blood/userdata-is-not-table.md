---
title: Paid For With Blood — Userdata Is Not a Table
description: Engine wrappers can look collection-like while obeying different Lua semantics.
weight: 50
extra:
  kind: guide
---

St4sh [commit `3649154c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3649154c732e0bfaa87d781ad587fd02aaac1643) fixed CellPresence code that treated engine-provided userdata as though it were an ordinary Lua table and attempted table-oriented iteration with `next`.

The broader mistake is common: an engine object exposes indexed or collection-like behavior, so source code starts assuming every table operation is valid.

## The rule

**Use the API contract of the userdata, not the visual shape of its Lua syntax.**

Before applying table helpers, ask:

- Is this actually a table?
- Does it define `__len`, `__pairs`, or numeric indexing?
- Does iteration allocate?
- Is the returned object a view with engine lifetime?
- Can it be retained safely?

Lua's uniform syntax is convenient. The underlying representations are not uniform.

Source: S3ctors S3cret St4sh [commit `3649154c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3649154c732e0bfaa87d781ad587fd02aaac1643).
