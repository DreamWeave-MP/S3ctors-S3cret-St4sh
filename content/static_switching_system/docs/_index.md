+++
title = "Static Switching System Documentation"
description = "Public documentation for declarative OpenMW world patching with YAML."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"

[extra]
api_docs = true
docs_root = true
docs_project_name = "Static Switching System"
docs_short_title = "SSS Docs"
docs_project_path = "@/static_switching_system/index.md"
docs_sidebar_label = "Documentation"
kind = "guide"
+++

**Static Switching System (SSS)** is a declarative world-patching framework for OpenMW. It replaces static meshes or matches active objects and applies object, inventory, actor, world-state, and scripting actions from YAML.

SSS has two module types: static and instance. Pick one. They are separate pipelines and do not compose. Start with [Getting Started](@/static_switching_system/docs/getting-started/_index.md), then use [Concepts](@/static_switching_system/docs/concepts/_index.md) for dispatch, ordering, ranges, and persistence.

## Documentation map

- [Getting Started](@/static_switching_system/docs/getting-started/_index.md) — install SSS, place modules where the VFS can discover them, and make a first change.
- [Concepts](@/static_switching_system/docs/concepts/_index.md) — the two pipelines, matching and priority, persistence, edge cases, and diagnostics.
- [API Reference](@/static_switching_system/docs/api/_index.md) — the YAML format, schema, settings, lifecycle, and the advanced `StaticSwitcher_G` interface.
- [Recipes](@/static_switching_system/docs/recipes/_index.md) — copyable patterns built from the shipped examples, plus lessons from released static modules.
- [Experiments and Oddities](@/static_switching_system/docs/experiments/_index.md) — executable documentation for combinations that are useful, cursed, or both.
- [Compatibility and Troubleshooting](@/static_switching_system/docs/compatibility/_index.md) — VFS, optional dependencies, save updates, and runtime diagnosis.

The shipped YAML examples are **source fixtures**. They document real module shapes and are intended to be copied or adapted into the discovered VFS data directory; the examples directory itself is not scanned as a module directory.
