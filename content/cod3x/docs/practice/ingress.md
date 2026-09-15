---
title: Validate and Normalize at Ingress
description: Turn flexible external data into strict internal data once, before it reaches hot or stateful code.
weight: 45
extra:
  kind: guide
---

Configuration, metadata, storage, external module registrations, and game records are **inputs**.

Do not make every consumer repeatedly rediscover what those inputs mean.

The preferred pipeline is:

{{ schematic(data_path="data/schematics/ingress-pipeline.json") }}

## Flexible outside, strict inside

A public configuration format may intentionally accept aliases, optional fields, case-insensitive names, or multiple shorthand forms.

That flexibility belongs at ingress.

Once the data enters the runtime, turn it into the representation the hot path actually wants.

Examples from the St4sh history include condition systems that moved string normalization such as lowercasing out of repeated evaluation and into registration/loading.

The gain is not merely speed. It means runtime code can rely on a smaller set of invariants.

## Fail near the bad input

If a registration says an enum is invalid, report that during registration.

Do not let the value travel through three tables and finally fail when an actor enters combat.

A useful validation error includes the input identity and field:

```text
MyRule: invalid condition `weather = purple`
```

not:

```text
attempt to index nil
```

## Canonical data makes hot paths boring

Suppose a user-facing configuration accepts:

```text
Interior
INTERIOR
interior
```

Normalize that once.

Do not call `string.lower()` every time the condition is evaluated for every active object.

The same principle applies to:

- record IDs;
- event names;
- enum-like strings;
- paths;
- optional defaults;
- precomputed lookup tables;
- resolved function references.

## Validation is not recovery

Rejecting malformed external input is not the same as wrapping the entire loader in `pcall` and continuing with whatever happened to load.

If a partially loaded registry has no meaningful semantics, loading should fail.

If individual entries are explicitly independent and the contract permits partial success, document that contract and report each rejected entry clearly.

## Schema changes are lifecycle changes

Persisted or shared configuration can outlive one version of a mod.

When the canonical representation changes, decide whether old input will be:

- migrated;
- accepted and normalized into the new shape;
- invalidated and rebuilt;
- explicitly rejected.

Do not silently reinterpret old state.

## Keep raw input when provenance matters

Canonical runtime data need not erase the original source.

For diagnostics, it can be useful to retain:

- source file/path;
- registration owner;
- original key/name;
- line/index when available.

That lets strict internals produce errors a human can actually act on.
