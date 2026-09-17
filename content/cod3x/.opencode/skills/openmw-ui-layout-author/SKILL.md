---
name: openmw-ui-layout-author
description: "openmw.ui layout tables, Content, named children, Element:update, root layers, ownership, dynamic content, and UI layout mutation."
---

# OpenMW UI Layout Author

Use this skill when creating, reviewing, or debugging OpenMW Lua UI layout trees and live layout mutation.

## Core Invariants

- Keep one explicit owner root per logical UI surface unless multiple-root ownership is deliberately documented.
- Prefer direct named-child access from the owner that created the child. Recursive search as a default API hides ownership errors and duplicate-name ambiguity.
- Names must obey the target OpenMW `Content` contract; keep them unique within their content scope.
- Build coherent content before attaching it when later logic depends on named entries or ordering. Avoid in-place name mutation unless the target API explicitly supports it.
- Root layer choice affects visibility, stacking, and interactivity; choose it deliberately.
- Mutate the live `Element.layout` after `ui.create`, then call `element:update()` as required. Do not keep an obsolete construction table as the authoritative mutable state.
- `Element:update()` refreshes the element's current layout but does not magically rebuild separately created child `Element`s; respect the target version's documented child semantics.
- Clear or replace live element references on destroy/rebuild and guard callbacks against invalidated owners.

## Workflow

1. Identify root owner, context, layer, and create/show/hide/update/destroy paths.
2. Map direct named children and dynamic regions.
3. Build complete layout/content structures with stable names.
4. Centralize structural mutation in the owner rather than scattering it through consumers.
5. Store live elements only where live mutation is necessary.
6. Use the narrowest update/rebuild that preserves ownership semantics.
7. Validate context, layout, and runtime behavior for ordering-sensitive changes.

## Version-Sensitive Rules

Field names, Content behavior, element parenting, and destruction/update edge cases can change. Use matching OpenMW source/docs as authority. If Cod3x stubs disagree on a field name or type, treat that as a stub bug to investigate rather than silently following stale metadata.

## Anti-Patterns

- Competing roots silently controlling one surface.
- Recursive `findByName` as routine access.
- Stale construction tables mutated after `ui.create`.
- Updating a nested element and expecting the parent structure/ownership to change automatically.
- Defaulting every UI root to one layer.
- Holding destroyed element references in callbacks/state.
- Whole-tree rebuilds for tiny leaf changes without a measured reason.

## Validation

Run repository layout/context/LuaLS checks and snapshot/runtime diagnostics when available. For visual/order-sensitive work, a static pass is not enough; reproduce in the target OpenMW version.
