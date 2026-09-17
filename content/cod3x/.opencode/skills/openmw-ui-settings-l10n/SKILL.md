---
name: openmw-ui-settings-l10n
description: "openmw.ui, Settings interfaces/renderers, localization, menu/player UI, settings definitions, and user-facing UI documentation."
---

# OpenMW UI, Settings, And Localization

Use this skill for OpenMW Lua settings definitions, renderer contracts, localization files, menu/player settings UI, or documentation that describes them.

## Before Editing

- Verify the OpenMW version/API revision and script context involved.
- Keep menu and player responsibilities separate unless an interface contract explicitly bridges them.
- Inspect user-facing docs/indexes when behavior, setting IDs, UI structure, or localization changes.

## Settings And Localization

- Keep setting IDs, group/page IDs, renderer names, and localization keys exactly aligned across Lua/data/docs.
- Prefer localization for visible user-facing strings when the project supports it.
- Provide defensive defaults so missing first-run state or localization does not make rendering fail.
- Validate localization file syntax and Lua syntax after edits when tooling exists.
- Do not silently rename persisted setting IDs without a compatibility/migration plan.

## UI And Renderers

- Check creation, replacement, update, callback, and teardown paths.
- Check scaling/resolution behavior, anchors, relative sizing, alignment, wrapping, and scrolling as relevant.
- Ensure settings/language/state transitions refresh visible UI correctly.
- Preserve documented renderer input/output/ownership/update contracts.
- Compare custom renderer behavior with built-in renderers from the matching OpenMW revision.
- Avoid shared mutable state across menu/player contexts unless ownership is explicit.

## Finish

Recheck ID/key alignment, user-facing strings, compatibility of persisted settings, and any generated docs. Report validation that could not be performed in the target runtime.
