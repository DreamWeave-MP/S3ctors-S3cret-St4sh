---
title: API and Interface Design
description: Small explicit contracts, stable ownership, typed payloads, and no accidental export of implementation state.
weight: 65
extra:
  kind: guide
---

Reusable OpenMW Lua code becomes infrastructure when other scripts can depend on it without depending on its internals.

That requires deliberate API design.

The positive version of this discipline is collected in [Good Designs](@/cod3x/docs/good-designs/_index.md). [S3maphore Playlist Eligibility](@/cod3x/docs/good-designs/s3maphore-playlist-eligibility.md) and [I.s3.lf](@/cod3x/docs/good-designs/s3lf-semantic-boundary.md) show what a small contract can protect when the underlying problem is not small.

## Export the contract, not the manager table

Do not expose a giant mutable implementation table merely because it already contains the functions consumers need.

Prefer a narrow interface:

```lua
return {
  interfaceName = 'MyFeature',
  interface = {
    getTarget = getTarget,
    setEnabled = setEnabled,
  },
}
```

Keep caches, mutable implementation state, helper functions, and engine handles private unless consumers genuinely need them.

## Required means required

If another interface/module is required for correct behavior, assert it and fail near initialization.

Repeated optional checks for a dependency that must exist make every call site more complicated while letting broken installation state limp farther into runtime.

DreamScripts evolved in this direction: once core interfaces were guaranteed after initialization, code stopped repeatedly pretending they might be absent.

## Optional dependencies need an explicit degraded contract

Optionality is legitimate when behavior without the dependency remains coherent.

Document:

- what feature is unavailable;
- when capability is detected;
- whether the decision can change during runtime/reload;
- whether callers need to branch.

Do not use `pcall(require)` everywhere to make required dependencies look optional.

## Version public interfaces deliberately

If an interface changes incompatibly, give consumers a way to detect the contract they received.

Common approaches include:

- explicit `version` fields;
- compatibility wrappers/deprecations;
- additive evolution until a major break is justified.

H3 and T4rg3t5 histories contain explicit interface versioning because consumers exist outside the defining file.

Compare the [H3 interface reference](@/h3lp_yours3lf/docs/api/interfaces/_index.md) and [T4rg3t5 interface documentation](@/t4rg3t5/docs/api/interface.md) when designing a provider. They show the useful distinction between a public capability and the implementation modules behind it.

## Payloads deserve types

An event/interface table with a dozen undocumented fields is not self-documenting because Lua accepts it.

Give public payloads names in Cod3x/LuaLS annotations and document optionality precisely.

Prefer:

```lua
---@class TargetChangedEvent
---@field previousId string?
---@field currentId string?
```

over comments scattered across senders and receivers.

## Copy when ownership crosses the boundary

Do not accidentally export internal mutable tables when consumers are only supposed to inspect a snapshot.

Depending on the contract, use:

- read-only views;
- copies;
- immutable DTOs;
- accessor functions.

S3maphore history includes cases where making exported structures read-only affected nested structures in surprising ways. The right abstraction depends on whether consumers need a live view or a safe snapshot.

## Do not hide expensive work behind innocent accessors without reason

An API named `getFoo()` may perform an engine query, scan, or allocation. That can be fine, but consumers need enough contract to place it intelligently.

For expensive operations, document:

- whether results are cached;
- cache lifetime;
- whether calling in a frame loop is expected;
- whether the result is a live view or newly allocated object.

## Deprecation is cheaper than surprise

When a public name or behavior must change:

1. introduce the replacement;
2. keep a thin old wrapper where practical;
3. mark/document deprecation;
4. migrate internal consumers;
5. remove only when the compatibility window is intentionally over.

Infrastructure earns trust by making breakage predictable.
