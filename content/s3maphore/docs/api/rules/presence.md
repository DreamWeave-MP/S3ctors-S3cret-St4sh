+++
title = "Presence and Content Rules"
description = "Rules for objects, types, content files, and FlexTag content."
weight = 30

[extra]
api_docs = true
kind = "PlaylistRules"
+++

Presence rules read the maps produced by [CellPresence](@/s3maphore/docs/api/cell-presence.md) and projected into [PlaylistState](@/s3maphore/docs/api/playlist-state.md). Object maps cover the current interior or exterior 3×3 scan.

## `objectExact`

{{ api_signature(value="Playback.rules.objectExact(objectRules) -> boolean") }}

Checks record IDs in `objectsByRecord`. `true` entries require a matching record; `false` entries forbid one. A matching forbidden entry always wins, so the result is deterministic when several listed records are present.

```lua
local ShrineObjects = {
    ['furn_de_ex_bench_01'] = true,
    ['ex_ashl_tent_01'] = false,
}

isValidCallback = function()
    return Playback.rules.objectExact(ShrineObjects)
end
```

`objectExact` replaces `staticExact` and has the broader name because it reads all object records, not just statics.

## `staticExact` (deprecated)

{{ api_signature(value="Playback.rules.staticExact(staticRules) -> boolean") }}

Compatibility wrapper for `objectExact`. Existing playlists can keep using it, but new playlists should use `objectExact`.

## `staticContentFile`

{{ api_signature(value="Playback.rules.staticContentFile(contentFiles) -> boolean") }}

Returns `true` when a static object in the current scan came from any content file present as a key in `contentFiles`. Content-file names are normalized to lowercase by the collector, so use lowercase keys.

```lua
local ExpansionStatics = {
    ['tamriel rebuilt.esm'] = true,
    ['project cyrodiil mainland.esm'] = true,
}

isValidCallback = function()
    return Playback.rules.staticContentFile(ExpansionStatics)
end
```

Unlike `objectsByContentFile`, this rule considers only the files that contributed statics.

## `typeCount`

{{ api_signature(value="Playback.rules.typeCount(typeRule) -> boolean") }}

Checks the number of objects of one OpenMW type. `type` is required; `min` and `max` are optional inclusive bounds.

```lua
local ThreeContainers = {
    type = 'Container',
    min = 3,
    max = 10,
}

isValidCallback = function()
    return Playback.rules.typeCount(ThreeContainers)
end
```

The type names come from OpenMW's object types, such as `Static`, `Container`, `NPC`, and `Creature`.

## `cellHasTag`

{{ api_signature(value="Playback.rules.cellHasTag(tagTable) -> boolean") }}

Returns `true` when the current cell has any supplied FlexTag. Requires FlexTag; otherwise it logs a diagnostic and returns `false`.

```lua
local AshlandTags = { 'ashlands', 'blight' }

isValidCallback = function()
    return Playback.rules.cellHasTag(AshlandTags)
end
```

## `cellContainsTagged`

{{ api_signature(value="Playback.rules.cellContainsTagged(tagTable) -> boolean") }}

Returns `true` when any record ID in the current cell or grid has any supplied FlexTag.

```lua
local DwemerTags = { 'WeaponDwemer', 'ArmorDwemer' }

isValidCallback = function()
    return Playback.rules.cellContainsTagged(DwemerTags)
end
```

This checks object record IDs, not the cell name and not the content file.

## `contentTag`

{{ api_signature(value="Playback.rules.contentTag(tagTable) -> boolean") }}

Returns `true` when any content file contributing an object in the current scan has any supplied FlexTag. Requires FlexTag.

```lua
local ExpansionTags = { 'tamriel-rebuilt', 'project-cyrodiil' }

isValidCallback = function()
    return Playback.rules.contentTag(ExpansionTags)
end
```

This checks every content file in `objectsByContentFile`, not only static contributors.

## `staticMatch` (removed)

{{ api_signature(value="Playback.rules.staticMatch(patterns)") }}

This rule has been removed and throws an error when called. Migrate to FlexTag rules, `objectExact`, or `staticContentFile` depending on what the playlist needs to identify.
