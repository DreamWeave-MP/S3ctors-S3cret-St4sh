---
title: Settings Renderers
description: Add H3's menu-only custom controls for screen positions, string lists, and H3UI appearance settings.
weight: 82
extra:
  kind: api
---

{{ api_signature(value="H3 plugin → Settings renderers: ScreenPosition, List, H3UIColor, H3UITheme, H3UIReset") }}

`renderers.lua` is a menu-context provider script installed by the H3 plugin. It registers custom `interfaces.Settings` renderers when the plugin loads; consumers do not call a constructor or require a returned API.

{% usage_note(title="Menu provider · No public module return value") %}
The script returns an empty table after registration. Settings definitions select these renderers by type name, and the Settings system supplies the current value, setter, and optional argument. The renderer owns its temporary popup element and destroys it when replaced or closed.
{% end %}

## ScreenPosition

The `ScreenPosition` renderer edits a normalized `openmw.util.Vector2` position. It shows a preview marker, opens a larger picker on click, and clamps the draft to `[0, 1]`. While dragging, a primary-button release commits the current draft through the Settings setter; if the release is inside the picker, the release offset is applied once more before the commit.

Apply closes the picker. Cancel restores the original value when the draft changed, then closes the picker.

The optional argument can provide a plain `title`, or an l10n group and `name` pair for a localized title. The renderer's `z`-less position is UI data: it is not a world position and does not perform camera projection.

## List

The `List` renderer edits an array of strings. It provides a text input used by an Add action and a Remove action for each current entry. Newly added strings retain the casing entered by the user. The renderer copies the incoming array before editing and calls the supplied Settings setter with the edited array.

These controls are registered by [H3's menu renderer provider](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fh3lp_yours3lf%2Fscripts%2Fs3%2Frenderers.lua). The provider owns the H3 localization keys such as `button_add`, `button_remove`, `button_apply`, and `button_cancel`. Settings authors only need to provide their own localization group when using the `{ l10n, name }` title argument for `ScreenPosition`.

## H3UI appearance renderers

`H3UIColor` displays a color swatch and accepts a six-digit hexadecimal value. A valid edit writes the color to the H3UI player settings and selects `Custom`. `H3UITheme` lists the built-in and registered H3UI presets; choosing a preset copies its canonical colors into the player settings. `H3UIReset` restores the canonical Morrowind palette.
