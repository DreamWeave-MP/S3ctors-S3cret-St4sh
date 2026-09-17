---
name: openmw-lua-context-guard
description: "OpenMW Lua script contexts, context annotations, openmw.* imports, global/local/player/menu/load boundaries, and context-aware LuaLS review."
---

# OpenMW Lua Context Guard

Use this skill when changing OpenMW Lua scripts, importing `openmw.*` modules/interfaces, moving code between script types, or reviewing context diagnostics.

## Context Rules

- Annotate each script/module with the narrowest correct context supported by its callers.
- Do not broaden to an `any`-style context merely to silence diagnostics.
- Multiple allowed contexts are an intersection for shared behavior: every exported operation must be valid for every context that can call it.
- Shared modules should separate context-neutral logic from context-specific engine access when necessary.

## API Availability

Check each OpenMW package/interface against the target revision and script context before importing or using it. Context availability evolves; do not infer it from a different script type or older release.

## Require Boundaries

- A shared module must not hide context-specific imports from callers that cannot legally use them.
- Prefer small context-owned adapter modules over one broadly annotated module with runtime landmines.
- When behavior genuinely varies by context, make the boundary explicit rather than weakening annotations.

## Source Of Truth

Use this order:

1. Matching OpenMW source/API revision.
2. Official generated OpenMW docs.
3. Cod3x stubs/context diagnostics.
4. Local project usage/tests.

Cod3x should diagnose runtime reality; stale stubs are bugs to fix, not authority over the engine.

## Validation

Run LuaLS/context diagnostics when available, then manually review changed imports/exports for cross-context leakage. Record any version/context assumption that could not be verified.
