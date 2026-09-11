+++
title = "Compatibility and Troubleshooting"
description = "Keep SSS modules, saves, VFS paths, and optional integrations predictable."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 20

[extra]
api_docs = true
kind = "guide"
+++

SSS is a VFS-discovered OpenMW Lua framework. Most failures are a boundary problem: the YAML is outside the discovery path, a resource is not visible through the active VFS, a condition depends on an optional integration, or an existing save already contains an instance change.

- [FlexTag compatibility](@/static_switching_system/docs/compatibility/flextag.md) — `has_tag`, `cell_tag`, `add_tag`, and `remove_tag`.
- [Real-world compatibility patches](@/static_switching_system/docs/compatibility/real-world-patches.md) — published MOMW and alvazir fixes translated into optional SSS modules.
- [MOMW translation index](@/static_switching_system/Examples/Compatibility/MOMW/index.md) — source attribution and direct links for the translated MOMW modules.
- [alvazir translation index](@/static_switching_system/Examples/Compatibility/Alvazir/index.md) — source attribution and direct links for the translated alvazir modules.
- [What SSS cannot replace](@/static_switching_system/docs/compatibility/what-sss-cannot-replace.md) — the boundary between runtime object patching and plugin surgery.
- [Save updates and persistence](@/static_switching_system/docs/compatibility/save-updates-and-persistence.md) — what persists when modules or rules change.
- [VFS and package boundaries](@/static_switching_system/docs/compatibility/vfs-package-boundaries.md) — data directories, discovery, resource paths, and case.
- [Troubleshooting](@/static_switching_system/docs/compatibility/troubleshooting.md) — a log-first diagnostic path.
