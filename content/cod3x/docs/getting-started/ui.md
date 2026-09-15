---
title: UI — From Nothing to Something
description: Start with one visible element, then earn the architecture.
weight: 60
extra:
  kind: guide
---

OpenMW UI is easier to learn when the first example is not a framework.

## Put a black rectangle on the screen

A player or menu script can create a root element directly:

```lua
---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local white = ui.texture { path = 'white' }

local element = ui.create {
  type = ui.TYPE.Image,
  layer = 'Windows',
  props = {
    resource = white,
    position = util.vector2(40, 40),
    size = util.vector2(200, 100),
    color = util.color.rgb(0, 0, 0),
  },
}
```

That is the conceptual starting point: layout table in, element out.

If the exact widget/property surface changes in the OpenMW version you target, use Cod3x's current annotations as the contract. The important mental model is stable: layouts describe UI; `ui.create` mounts a root; `Element:update()` refreshes it after layout changes; `Element:destroy()` removes it.

## Then make something that looks like Morrowind

Morrowind-style windows are not “a rectangle with a border.” They are a composition of background, border/header textures, text region, controls, and often lock/pin behavior.

H3UI exists to package those repeated compositions without pretending OpenMW's low-level UI primitives are something they are not.

For a new mod, prefer a high-level H3UI recipe or component when it matches the surface you need. Learn the low-level API anyway, because ownership, update behavior, events, and performance remain OpenMW concepts underneath it.

H3 Pattern: start with a [Window](@/h3lp_yours3lf/docs/api/components/window.md), [Dialog](@/h3lp_yours3lf/docs/api/components/dialog.md), [Grid](@/h3lp_yours3lf/docs/api/components/grid.md), [Tabs](@/h3lp_yours3lf/docs/api/components/tabs.md), or [ItemSlot](@/h3lp_yours3lf/docs/api/components/item-slot.md) when one matches. For higher-level composition, read [H3UI and Styling](@/h3lp_yours3lf/docs/concepts/h3ui.md) and the [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md).

## Keep state outside the layout when practical

Treat the layout as a projection of application state.

```lua
local enabled = true
local element

local function buildLayout()
  return {
    type = ui.TYPE.Container,
    layer = 'Windows',
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          text = enabled and 'Enabled' or 'Disabled',
        },
      },
    },
  }
end

element = ui.create(buildLayout())
```

When state changes, update the owned layout/element deliberately rather than scattering mutations across unrelated callbacks.

## Do not call `ui.updateAll()` casually

Cod3x annotates `ui.updateAll()` with a warning for a reason: it updates every existing UI element and can be extremely slow.

If you own one element, update one element.

If a component can refresh a narrow subtree, prefer that narrow operation.

Broad invalidation should be the exceptional path.

## UI events are still error boundaries

Callbacks run later, against state that may have changed since the element was created.

Do not assume:

- the element still exists;
- the object handle captured by a closure is still valid;
- a page is still the active page;
- a delayed callback still belongs to the same logical generation.

The same stale-work rules used elsewhere apply to UI.

## UI architecture should grow with need

A useful progression is:

1. one root layout;
2. small local builder functions;
3. reusable components;
4. a theme/recipe layer when multiple mods repeat the same compositions.

Do not begin a three-button panel by inventing a declarative framework.

H3UI is justified because the corpus contains many mods repeating the same hard OpenMW/Morrowind UI problems. That is the level of evidence an abstraction should earn.

### From the St4sh

[S3maphore's playlist editor documentation](@/s3maphore/docs/examples/interface-control.md) is a production example of a larger OpenMW UI. H3's [H3UI documentation](@/h3lp_yours3lf/docs/concepts/h3ui.md) and [window component source](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/components/window.lua) show the reusable layer without hiding the underlying `ui.create`/`Element:update` lifecycle.
