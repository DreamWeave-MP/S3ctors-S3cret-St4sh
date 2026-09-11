+++
title = "Concepts"
description = "The execution model behind SSS YAML modules."
page_template = "docs/page.html"
sort_by = "weight"
weight = 40

[extra]
kind = "concepts"
+++

SSS's public authoring contract is YAML. These pages explain the execution model:

- [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md) explains why static and instance modules are separate.
- [Matching, Priority, and Action Order](@/static_switching_system/docs/concepts/order-and-matching.md) explains VFS discovery order, priority tiers, conditions, chance, and actions.
- [Ranges](@/static_switching_system/docs/concepts/ranges.md) distinguishes comparison bounds from sampled action ranges.
- [Persistence and Once Semantics](@/static_switching_system/docs/concepts/persistence.md) explains `once`, `per_cell`, replacement chains, and saves.
- [Behavioral Edge Cases](@/static_switching_system/docs/concepts/edge-cases.md) collects dispatch, ordering, target, persistence, and value traps.
- [Validation and Debugging](@/static_switching_system/docs/concepts/validation-and-debugging.md) explains schema checks, runtime warnings, and the debug log.

For field-by-field syntax, use the [Module Format](@/static_switching_system/docs/api/module-format.md) and [Schema](@/static_switching_system/docs/api/schema.md) pages.
