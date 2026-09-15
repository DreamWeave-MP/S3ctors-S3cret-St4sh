---
title: Engineering Practice
description: The discipline behind maintainable, fast OpenMW Lua.
weight: 20
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
---

This section encodes the engineering discipline behind the DreamWeave OpenMW-Lua corpus.

The point is not to turn taste into law. The point is to separate engine contracts, measured behavior, derived constraints, and preferences, then explain why the preferences exist.

Start with [Contracts, Measurements, Derivations, and Preferences](@/cod3x/docs/practice/evidence.md). [Effective OpenMW Lua Foundations](@/cod3x/docs/practice/effective-openmw-lua.md) carries forward the basic discipline from Yvan/Hebi's original educational work. If you only read one opinionated page, read [Error Handling](@/cod3x/docs/practice/error-handling.md).

For stateful systems, continue with [Object Lifetime and Stable Identity](@/cod3x/docs/practice/object-lifetime.md), [State Ownership and Invalidation](@/cod3x/docs/practice/state.md), and [Save Compatibility](@/cod3x/docs/practice/save-compatibility.md). For reusable infrastructure, read [API and Interface Design](@/cod3x/docs/practice/api-design.md).
