---
title: uiSnapshot
description: Capture deterministic, bounded text snapshots of OpenMW UI layouts.
weight: 60
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.uiSnapshot' → uiSnapshot") }}

Use `uiSnapshot` when a UI bug needs evidence rather than another guess at the layout. It turns a layout or UI element into deterministic text or fresh plain Lua data.

{% usage_note(title="Plain Lua inspection · Diagnostics, not rendering") %}
The module does not import `openmw.ui` or create, update, or destroy elements. It safely reads `element.layout`, including destroyed-element failures, but capture allocates tables, strings, and line arrays.
{% end %}

## Capture a layout

```lua
local ui = require 'openmw.ui'
local uiSnapshot = require 'scripts.s3.uiSnapshot'
local util = require 'openmw.util'

local element = ui.create {
  type = ui.TYPE.Text,
  layer = 'HUD',
  props = {
    text = 'Loading...',
    relativeSize = util.vector2(0.4, 0.05),
  },
}

print(uiSnapshot.format(element))
```

## Options

```lua
local snapshot = uiSnapshot.capture(element, {
  maxDepth = 6,
  maxChildren = 32,
  maxString = 80,
  includeEvents = false,
  includeUserData = true,
  vectorMode = 'placeholder',
})
```

| Option | Behavior |
| --- | --- |
| `maxDepth` | Maximum nested table/layout depth; default `8`. |
| `maxChildren` | Maximum numeric `content` children; default `128`. |
| `maxString` | Maximum string length before a truncation marker; default `160`. |
| `includeFunctions` | Include stable `{ __type = 'function' }` placeholders; default false. |
| `includeEvents` | Include event tables and callback placeholders; default false. |
| `includeUserData` | Include `userData`; default false. |
| `vectorMode` | `'fields'` records vector/color components; `'placeholder'` records only their type. |
| `sortKeys` | Sort non-layout keys for stable output; default true. |

Depth, child, and string limits produce truncation markers. Cycles and repeated references are reported instead of recursed into; unsupported userdata becomes a type marker.

## Output forms

| Call | Result |
| --- | --- |
| `fromLayout(layout, options?)` | Fresh plain table snapshot. |
| `fromElement(element, options?)` | Snapshot or `{ __snapshot = 'invalidElement', reason = ... }`. |
| `capture(value, options?)` | Element snapshot when readable; otherwise value/layout snapshot. |
| `lines(value, options?)` | Fresh deterministic text-line array. |
| `format(value, options?)` | Newline-separated deterministic text. |

`fromElement` does not raise when a destroyed or invalid element rejects a layout read. Use `lines` for custom prefixes and table forms for field assertions. Capture on demand, not from a high-frequency callback; returned values are snapshots and do not update with later UI mutations.
