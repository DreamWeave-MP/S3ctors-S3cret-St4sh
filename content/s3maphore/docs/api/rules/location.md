+++
title = "Location and Time Rules"
description = "Rules for cells, regions, exterior grids, weather, and time of day."
weight = 10

[extra]
api_docs = true
kind = "PlaylistRules"
+++

All location identifiers are compared against S3maphore's normalized lowercase values. Define lookup tables once, outside `isValidCallback`, so S3maphore can reuse cached results.

## `cellNameExact`

{{ api_signature(value="Playback.rules.cellNameExact(cellNames) -> boolean") }}

Returns `true` when the current `PlaylistState.cellName` is a key with value `true` in `cellNames`. This is exact matching, not substring matching.

```lua
local Cells = {
    ['balmora'] = true,
    ['balmora, caius cosades\'s house'] = true,
}

isValidCallback = function()
    return Playback.rules.cellNameExact(Cells)
end
```

Keys must be lowercase. A missing key or a key with a false value does not match.

## `cellNameMatch`

{{ api_signature(value="Playback.rules.cellNameMatch(patterns) -> boolean") }}

Performs case-sensitive plain substring matching against the already-lowercased cell name. `disallowed` patterns are checked first; if any matches, the rule returns `false`. Otherwise, any `allowed` match returns `true`.

```lua
local AshlandsCells = {
    allowed = { 'ashlands', 'red mountain' },
    disallowed = { 'telvanni tower' },
}

isValidCallback = function()
    return Playback.rules.cellNameMatch(AshlandsCells)
end
```

Both arrays are optional. An empty or non-matching `allowed` list returns `false`.

## `region`

{{ api_signature(value="Playback.rules.region(regionNames) -> boolean") }}

Matches `PlaylistState.nearestRegion` against an `IDPresenceMap`. An interior may get its nearest region from a teleport door when the cell itself has no region.

```lua
local CoastalRegions = {
    ['azura\'s coast region'] = true,
    ['bitter coast region'] = true,
}

isValidCallback = function()
    return Playback.rules.region(CoastalRegions)
end
```

The rule returns `false` when no region is known.

## `weatherType`

{{ api_signature(value="Playback.rules.weatherType(weatherNames) -> boolean") }}

Matches the current weather record ID against an `IDPresenceMap`.

```lua
local StormWeather = {
    rain = true,
    thunder = true,
}

isValidCallback = function()
    return Playback.rules.weatherType(StormWeather)
end
```

Use the weather record IDs supplied by the active game content. The rule returns `false` when no current weather matches.

## `timeOfDay`

{{ api_signature(value="Playback.rules.timeOfDay(minHour, maxHour) -> boolean") }}

Matches the current game hour in the half-open interval `[minHour, maxHour)`: the lower bound is included and the upper bound is excluded.

```lua
isValidCallback = function()
    return Playback.rules.timeOfDay(8, 18)
end
```

This example matches 08:00 through 17:59. For a range that crosses midnight, split it into two rules in the callback.

## `exteriorGrid`

{{ api_signature(value="Playback.rules.exteriorGrid(gridRules) -> boolean") }}

Matches the current actual exterior grid coordinate against an array of `{ x, y }` tables. It returns `false` indoors and in quasi-exterior cells because `PlaylistState.currentGrid` is `nil` there.

```lua
local SacredGridCells = {
    { x = -2, y = -3 },
    { x = -1, y = -3 },
}

isValidCallback = function()
    return Playback.rules.exteriorGrid(SacredGridCells)
end
```

The coordinates are world exterior grid coordinates, not local coordinates relative to the player.
