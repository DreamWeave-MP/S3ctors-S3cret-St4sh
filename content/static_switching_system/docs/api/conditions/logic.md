+++
title = "Logic Conditions"
description = "Invert one condition while preserving SSS rule matching semantics."
page_template = "docs/page.html"
weight = 50

[extra]
api_docs = true
kind = "api"
+++

## `not`

**Shape:** `not: { ConditionName: condition-value }`

Inverts one inner condition. The inner map is intended to contain exactly one condition entry. If that entry's value is a YAML sequence, the inner condition is treated as an any-of list first; `not` succeeds only when none of those alternatives match.

```yaml
not:
  nameMatch: Guard
```

Use separate `not` entries for multiple exclusions. As with all condition entries, separate conditions are ANDed:

```yaml
conditions:
  - not: { nameMatch: Guard }
  - not: { nameMatch: Soldier }
```

An unknown inner condition raises an error. A failed inversion is an ordinary false match; `not` has no independent persistence or chance behavior. The schema describes the inner value through `conditionData`, but authoring a multi-key inner map is not supported by the handler's single-entry evaluation contract.
