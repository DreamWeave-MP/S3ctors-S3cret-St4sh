# UI Content Contracts

OpenMW UI content tables are retained objects with engine-managed ownership. Treat them as mutable UI state, not disposable plain Lua data.

## Ownership And Naming

- Keep ownership clear: the code that creates retained content should also define when it is updated, detached, or discarded.
- Avoid content keys that collide with method names such as `insert`, `remove`, `update`, or `destroy`.
- Prefer explicit names like `rows`, `slots`, `labelText`, or `actions` over generic `content` children when a table also has methods.

## `content:insert` Caution

Use `content:insert(...)` only when the value being inserted is the intended retained UI child and the receiver is known to be a content object. Avoid calling `insert` through ambiguous names that could resolve to a field instead of a method.

## `userData`

Use `userData` for compact ownership metadata such as widget id, generation, source module, or stable content role. Do not store large game objects, protected tables, storage handles, or long-lived mutable state there.

## Lifecycle And Generation Guards

Retained UI callbacks can outlive the generation of data that created them. Guard callbacks and delayed updates with a local generation, owner id, or disposed flag before mutating UI content.

Suggested local comment shape:

```lua
-- UI contract: owner=<module> content=<name> generation=<var> userData=<keys> dispose=<condition>
```

Example:

```lua
-- UI contract: owner=settings content=rows generation=uiGeneration userData=id,role dispose=generation-mismatch
```

## Validation Tools

Use these for OpenMW UI changes:

- `openmw-context-check` for menu/player context boundaries.
- `openmw-interface-check` when UI uses `openmw.interfaces`, `Settings`, `MWUI`, or provided interfaces.
- `openmw-settings-l10n-check` for Settings UI and localization coherence.
- `lua-hotpath-budget-check` or `luajit-bytecode-inspect` when retained UI rendering runs in a hot path.
