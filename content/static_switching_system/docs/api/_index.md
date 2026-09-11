+++
title = "API Reference"
description = "The Static Switching System YAML and advanced OpenMW-Lua integration contract."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 100

[extra]
api_docs = true
kind = "api"
+++

Here's the deal: SSS is authored in YAML. That is the public contract. Lua is implementation detail unless this reference says otherwise.

- [Module Format](@/static_switching_system/docs/api/module-format.md) — root fields, static modules, instance rules, conditions, actions, and action order.
- [Schema and Editor Validation](@/static_switching_system/docs/api/schema.md) — schema location, valid ranges, mutual exclusion, and validation limits.
- [Validation and Debugging](@/static_switching_system/docs/concepts/validation-and-debugging.md) — schema checks, debug logging, and runtime diagnosis.
- [Interface](@/static_switching_system/docs/api/interface.md) — advanced global `StaticSwitcher_G` inspection.
- [Loading, Processing, and Persistence](@/static_switching_system/docs/api/lifecycle.md) — discovery, activation batches, delayed work, and save/load.
- [Conditions](@/static_switching_system/docs/api/conditions/_index.md) — location, identity, object, actor, player, and world-state predicates.
- [Actions](@/static_switching_system/docs/api/actions/_index.md) — replacement, transformation, inventory, world-state, scripting, and sound effects.
