---
title: UI Recipes
weight: 10
description: Copyable H3UI application patterns built through the public constructor facade.
extra:
  kind: example
---

These examples use the same path H3's application-grade component fixtures use: one `I.H3UI` facade, caller-owned state, and ordinary OpenMW mounting.

{% usage_note(title="Reference code, not a second framework") %}
The component test suite contains the executable versions of these patterns. Its application fixtures are intentionally written as real mod code: attractive enough to screenshot, concise enough to copy, and complicated enough to pressure-test H3UI. Small synthetic fixtures remain only where they isolate a specific engine invariant better.
{% end %}

## The normal setup

```lua
local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local element

local ui = I.H3UI.scope {
    element = function() return element end,
}
```

The scoped object is your constructor catalog. You normally should not need separate component `require`s. H3 redraws its own semantic mutations through the element resolver. Use `ui.setChildren()` for localized structural changes; rebuild the root only when caller-owned state changes the larger application structure.

## Morrowind-style Magic menu

A useful reference surface should exercise real interface problems. The bundled Magic-menu fixture combines window chrome, an icon strip, semantic sections, aligned secondary values, filtering, destructive actions, hover/pressed styling, and enough real text to expose spacing problems.

The important part is not reproducing Morrowind's data model. It is how little scaffolding the layout needs:

```lua
local function spellRow(spell)
    return ui.listItem {
        label = spell.name,
        secondary = spell.costChance,
        selected = selectedSpell == spell,
        onActivate = function()
            selectedSpell = spell
            rebuild()
            return true
        end,
    }
end

local function spellSection(title, secondary, spells)
    local children = {}

    for index = 1, #spells do
        children[#children + 1] = spellRow(spells[index])
    end

    return ui.section {
        title = title,
        secondary = secondary,
        gap = 1,
        children = children,
    }
end

local layout = ui.window {
    title = selectedSpell and selectedSpell.name or 'None',
    size = util.vector2(620, 440),
    pinnable = true,

    ui.column {
        gap = 6,

        ui.box {
            props = { size = util.vector2(584, 30) },
            ui.row {
                gap = 2,
                -- Distinct active-effect icons...
            },
        },

        ui.box {
            props = { size = util.vector2(584, 326) },
            ui.column {
                gap = 4,
                spellSection('Powers', nil, filteredPowers),
                spellSection('Spells', 'Cost/Chance', filteredSpells),
                spellSection('Magic Items', 'Charge', filteredItems),
            },
        },

        ui.row {
            gap = 4,
            ui.textInput {
                text = filter,
                onChange = function(value)
                    filter = value
                    rebuild()
                end,
            },
            ui.button {
                label = 'Delete',
                tone = 'negative',
                onActivate = deleteSelectedSpell,
            },
        },
    },
}
```

Notice what is *not* present: no row/column/text/button import pile, no raw `mouseClick` callback, no `args` wrapper, and no knowledge that the individual constructors resolve through different internal component adapters.

The executable fixture lives at `scripts/h3/componentTests/magicMenu.lua`.

## Tabbed mod configuration

`settings` and `tabbedWindow` are higher-level recipes, but they are called exactly like the primitive constructors around them:

```lua
local generalPage = ui.settings {
    title = 'General',
    gap = 8,
    fieldGap = 12,
    fields = {
        {
            label = 'Enabled',
            kind = 'toggle',
            value = enabled,
            onChange = function(value)
                enabled = value
                refresh()
            end,
        },
        {
            label = 'Mode',
            kind = 'selector',
            items = modes,
            selected = selectedMode,
            onSelect = function(index)
                selectedMode = index
                refresh()
            end,
        },
        {
            label = 'Intensity',
            kind = 'slider',
            value = intensity,
            min = 0,
            max = 100,
            step = 5,
            onChange = function(value)
                intensity = value
                refresh()
            end,
        },
    },
}

local advancedPage = ui.column {
    gap = 8,
    ui.text { text = 'Advanced', role = 'title' },
    ui.collapsible {
        title = 'Experimental behavior',
        expanded = showExperimental,
        onToggle = function(value)
            showExperimental = value
            refresh()
        end,
        children = {
            ui.text 'Put genuinely advanced controls here.',
        },
    },
}

local layout = ui.tabbedWindow {
    title = 'My Mod',
    size = util.vector2(560, 360),
    selected = selectedPage,
    tabs = {
        { label = 'General', content = generalPage },
        { label = 'Advanced', content = advancedPage },
    },
    onSelect = function(index)
        selectedPage = index
        rebuild()
    end,
}
```

`tabbedWindow` renders only the selected page. The `selectedPage` variable is yours: update it in `onSelect` and rebuild the caller-owned surface. The component-test harness deliberately distinguishes cheap `element:update()` invalidation from a full fixture rebuild so these examples exercise the same controlled-state model expected from real mods.

The executable fixture lives at `scripts/h3/componentTests/applicationForm.lua`.

## Inventory and item-grid surface

`itemGrid` removes repeated grid/item-slot assembly without pretending to own inventory data:

```lua
local itemLayouts = {}
for index = 1, #items do
    local item = items[index]
    itemLayouts[index] = {
        resource = { path = item.icon },
        count = item.count,
        selected = selectedItem == item,
        onActivate = function()
            selectedItem = item
            rebuild()
            return true
        end,
    }
end

local layout = ui.window {
    title = 'Inventory',

    ui.row {
        gap = 8,

        ui.box {
            ui.itemGrid {
                columns = 4,
                columnGap = 4,
                rowGap = 4,
                items = itemLayouts,
            },
        },

        ui.column {
            gap = 8,
            ui.text { text = selectedItem.name, role = 'title' },
            ui.divider(),
            ui.text(('Weight %s    Value %s'):format(
                selectedItem.weight,
                selectedItem.value
            )),
            ui.text 'Condition',
            ui.meter {
                value = selectedItem.condition,
                max = selectedItem.maxCondition,
            },
            ui.spacer { grow = 1 },
            ui.row {
                gap = 6,
                ui.button {
                    label = equipped[selectedItem] and 'Unequip' or 'Equip',
                    onActivate = toggleEquipSelected,
                },
                ui.button {
                    label = 'Drop',
                    tone = 'negative',
                    onActivate = dropSelected,
                },
            },
        },
    },
}
```

The executable fixture lives at `scripts/h3/componentTests/inventoryPanel.lua`.

The fixture also performs real construction-time category/search filtering, selection highlighting, equip/unequip state, count reduction on Drop, and carry-weight recalculation. The data is mock inventory data; the interaction pattern is intentionally application-realistic.

## Confirm dialog

A complete confirmation flow should not require rebuilding the same frame/message/action structure in every mod:

```lua
local dialog = ui.confirmDialog {
    title = 'Delete preset?',
    body = 'This cannot be undone.',
    confirmLabel = 'Delete',
    confirmTone = 'negative',
    onCancel = closeDialog,
    onConfirm = deletePreset,
}
```

For custom action sets:

```lua
ui.confirmDialog {
    title = 'Unsaved changes',
    body = 'What should happen to your edits?',
    actions = {
        { role = 'cancel', label = 'Keep editing', onActivate = closePrompt },
        { role = 'discard', label = 'Discard', tone = 'negative', onActivate = discard },
        { role = 'confirm', label = 'Save', tone = 'positive', onActivate = save },
    },
}
```

## Searchable list

The recipe owns the recurring visual structure and performs simple construction-time matching, not your query state or search algorithm:

```lua
local function buildResults()
    return ui.searchableList {
        query = query,
        items = allNames,
        text = function(item)
            return item
        end,
        onQueryChange = function(value)
            query = value
            rebuildResults()
        end,
    }
end
```

If the application needs pagination, selection models, database search, or async indexing, keep those in application code. A recipe should remove repeated interface assembly, not become a data framework.

## When *not* to add a recipe

The constructor API intentionally makes ordinary composition cheap:

```lua
ui.row {
    gap = 6,
    ui.button { label = 'Cancel', onActivate = cancel },
    ui.button { label = 'Apply', tone = 'positive', onActivate = apply },
}
```

A `buttonRow` recipe would not improve that. New recipes should earn their existence by encoding recognizable semantic structure, removing substantial repetitive plumbing, or exposing stable roles/slots that themes need.

The reference fixtures are where H3 pressures that rule. If several serious layouts keep writing the same awkward structure, that is evidence for the next reusable primitive or recipe.
