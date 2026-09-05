---
title: S3maphore for Modders
description: Documentation for creating S3maphore playlists and interacting with its public interfaces and events.
date: 2025-06-06

extra:
  hide_download_bar: true
---

As mentioned before, S3maphore is an open-ended system for playlist management. It is so open-ended, in fact, that you do not need to use S3maphore's built-in playlist management at all. Other playlist-related mods or plugins could easily be built on top of S3maphore's internal interface and provided events. This page describes how to make your own playlists and interact with S3maphore's public methods and mechanisms.

## Playlist Creation

S3maphore's playlists are *similar*, but not identical, to existing solutions. There are some key differences, however:

### Playlist Specification

1. S3maphore playlist files are known as `Playlist Arrays`, because that's what they are. Every playlist file can return any number of playlists inside of table it sends back out. Every playlist must have both a string `id` and a `priority` field. `id` is the name of the playlist which is used as a table key, and `priority` is a number between 1 and 1000 indicating when the playlist should override others or be overridden by others. More on playlist priority below. Optional fields include:
   1. `tracks` - `string[]` - List of VFS paths to tracks to play. If using MUSE or Dynamic Music soundbanks as a base, the paths can be copied directly.
   1. `active` - `boolean` - If false, this playlist will never be selected for playback. Defaults to true. See below for how to turn it on, if it's not actually enabled.
   1. `randomize` - `boolean` - Whether to play tracks from this playlist in the actual written order or randomly. Defaults to false.
   1. `cycleTracks` - `boolean` - Whether to continue repeating the playlist after it has finished. Defaults to true.
   1. `playOneTrack` - `boolean` - If true, the playlist will only play a single track and then deactivate itself. It must be reactivated using either the `setPlaylistActive` event or interface function in `I.S3maphore`. Defaults to false.
   1. `isValidCallback` - `function(playback: Playback): boolean` - A function which returns true/false to indicate whether or not a given playlist should run in this specific context. Only optional when using `PlaylistPriority.Never`
   1. `fadeOut` - `number` - optional duration for the fadeOut time between tracks in a playlist.
   1. `silenceBetweenTracks` - `PlaylistSilenceParams` - Parameters for determining how long, if at all, fake silence tracks are used in a playlist. See below for a more detailed description of the `PlaylistSilenceParams` type.
   1. `interruptMode` - `InterruptMode` - This field determines whether or not a playlist may be interrupted by another, based on the archetypes used by vanilla playlists. Valid values are `INTERRUPT.Me`, `INTERRUPT.Other`, `INTERRUPT.Never`, and `INTERRUPT.Override`.
   1. `fallback` - `PlaylistFallback` - Selection of fallback tracks and playlists which can be used alongside this playlist. See below for details of the `PlaylistFallback` type.
   1. `exclusions` - `S3maphorePlaylistExclusions` - Selection of tracks and sub-directories which will NOT be played by this particular list
2. S3maphore replaces OpenMW's builtin music script almost in its entirety. This means that conflicts between the two are mostly-impossible and limitations such as needing to manually set/know the duration of specific tracks is no longer necessary.
3. S3maphore playlists do *not* have strictly defined rules, instead relying on the `isValidCallback` to allow each playlist to define its own rules in a very open-ended way. Every `isValidCallback` is passed a `playback` struct, which is a table containing two more tables: `state`, and `rules`.

```lua
---@class PlaylistSilenceParams
---@field min integer minimum possible duration for this silence track
---@field max integer maximum possible duration for this silence track
---@field chance number probablility that this playlist will use silence between tracks
--- Example of how silenceparams may be used in a playlist
silenceBetweenTracks = {
    chance = 0.1,
    max = 30,
    min = 10,
},

--- Data type used to bridge one playlist into another, or to extend
---@class PlaylistFallback
---@field playlistChance number? optional float between 1 and 0 indicating the chance for a fallback playlist to be selected. If not present, the chance is always 50%
---@field playlists string[]? array of fallback playlists from which to select tracks. No default values and not required.
---@field tracks string[]? tracks to manually add to a given playlist. Used for folder-based playlists; not necessary for any others
fallback = {
    playlistChance = 0.25,
    playlists = {
        'Explore',
        'Tamriel Rebuilt - Port Telvannis',
    },
    tracks = {
        'explore/mx_explore_1.mp3',
    },
}

--- Special class for handling exterior grids.
--- Used for special circumstances in which playlists should only run in *particular* exterior cells
---@class S3maphoreCellGrid
---@field x integer
---@field y integer
grid = { x = -2, y = -2, }

---@class S3maphorePlaylistExclusions
---@field playlists string[]? list of subdirectories to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.
---@field tracks string[]? explicit list of tracks to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.
exclusions = {
    tracks = {
        'explore/nerevar_rising.mp3',
    },
    playlists = {
        'expore/subdir/
    },
}
```

### Interrupt modes

Interrupt modes control whether S3maphore may switch away from the currently playing playlist when a different playlist becomes the best valid choice:

- `INTERRUPT.Me` — the playlist may be interrupted. This is the default for Explore playlists.
- `INTERRUPT.Other` — the playlist may be interrupted by a playlist with a different interrupt mode. This is the default for Battle playlists.
- `INTERRUPT.Never` — the playlist may not be interrupted. This is the default for Special playlists.
- `INTERRUPT.Override` — the playlist always overrides the currently playing playlist when it is selected. It bypasses `INTERRUPT.Never`, the `Finish Previous Track` setting, and the normal same-mode interruption check.

`INTERRUPT.Override` only bypasses the interruption gate. The playlist must still be active, have tracks, pass its `isValidCallback`, and win normal playlist priority resolution. Once an override playlist is no longer the best valid choice, it can be replaced by the next playlist normally.

Override playlists do not receive archetypal global silence. Define `silenceBetweenTracks` on the playlist if a scripted sequence should include silence between tracks.

Use this mode for scripted moments such as quest stages, boss entrances, or one-shot musical cues. Pair it with `playOneTrack = true` when the playlist should play one track and then deactivate itself:

```lua
local QuestStages = {
    MyQuest = { min = 10, },
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'quest/my-quest-moment',
        priority = PlaylistPriority.Special,
        interruptMode = INTERRUPT.Override,
        tracks = {
            'music/quest/my-quest-moment.mp3',
        },
        playOneTrack = true,
        isValidCallback = function(playback)
            return playback.rules.journal(QuestStages)
        end,
    },
}
```

Do not use `INTERRUPT.Override` for ordinary Explore or Battle playlists unless they are intentionally meant to cut across any music currently playing. It is a forceful tool for deliberate transitions, not a replacement for choosing an appropriate priority.

Playlist files receive `INTERRUPT` from the built-in playlist environment. External scripts can access the same values through `I.S3maphore.const.INTERRUPT`.

### PlaylistState Specification

```lua
---@class PlaylistState
---@field playlistTimeOfDay TimeMap the time of day for the current playlist
---@field isInCombat boolean whether the player is in combat or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field cellId string engine-level identifier for cells. Should generally not be used in favor of cellNames as the only way to determine cell ids is to check in-engine using `cell.id`. It is made available in PlaylistState mostly for caching purposes, but may be used regardless.
---@field combatTargets FightingActors a read-only table of combat targets, where keys are actor IDs and values are booleans indicating if the actor is currently fighting
---@field staticContentFiles string[] a list of content files which placed statics in this cell. This is used in staticContentFile and objectExact rules for playlists.
---@field weather WeatherType a string indicating the current weather name. Updated by an internal mwscript in 0.49-compatible versions.
---@field nearestRegion string? The current region the player is in. This is determined by either checking the current region of the player's current cell, OR, reading all load door's target cell's regions in the current cell. The first cell which is found to have a region will match and be assigned to the PlaylistState.
---@field currentGrid S3maphoreCellGrid? The current exterior cell grid. Nil if not in an actual exterior.
```

As usual, if there are more state values you'd like the PlaylistState to offer, please do share! A generic-enough use case can and absolutely will make the cut.

`rules` is a table of functions that can have certain data passed into them to define when a S3maphore playlist should run. This is the real meat and potatoes of creating a S3maphorePlaylist. For exmaple:

WARNING:
    Take note of the fact that the `OuterRimCells` table is declared and defined in an upper scope, outside of the `isValidCallback` function. This is crucial for S3maphore's lookup caching methods to work. *Never* inline a table constructor in your `isValidCallbacks`, or you *will* lose performance for no reason and trigger a memory leak. This is unavoidable on S3maphore's part, so it is *paramount* that you use it properly. NEVER make an `isValidCallback` that looks like this:

```lua
    --- Major Dysfuckulation!
    isValidCallback = function(playback)
        return playback.rules.cellNameExact{ ['The Outer Rim'] = true, ['The Outer Rim, Freighter'] = true, }
    end
```

```lua
--- Extremely stable levels of fuckitude
local OuterRimCells = {
    ['the outer rim'] = true,
    ['the outer rim, freighter'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'
---@type S3maphorePlaylist[]
return {
    {
        id = 'Rickoff/The Outer Rim',
        priority = PlaylistPriority.CellExact,
        randomize = true,
        isValidCallback = function(playback)
            return playback.rules.cellNameExact(OuterRimCells)
        end,
    },
    {
        id = 'Rickoff/Club Arkngthand',
        priority = PlaylistPriority.CellExact,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.cellId == 'nar shaddaa, club arkngthand'
        end,
    }
}
```

TIP: If you don't want to specify track names manually, just don't! If no tracks are listed for a playlist, its `id` field is used to determine a folder name in which a playlist's tracks will be looked for. See the builtin playlists for an easy example:

```lua
{
    id = "Explore",
    priority = PlaylistPriority.Explore,
    randomize = true,

    isValidCallback = function()
        return not Playback.state.isInCombat and defaultPlaylistStates.ExploreActive
    end,
}
```

Above is S3maphore's version of Morrowind's built-in `Explore` playlist. No tracks are listed, because it just randomly picks from `Music/Explore`, since `Explore` is the playlist id.

### PlaylistRules Specification

```lua

--- Returns whether the current cell name matches a pattern rule. Checks disallowed patterns first
---
--- Example usage:
---
--- playlistRules.cellNameMatch { allowed = { 'mages', 'south wall', }, disallowed = { 'fighters', } }
---@param patterns CellMatchPatterns
function PlaylistRules.cellNameMatch(patterns)

--- Returns whether or not the current cell exists in the cellNames map
---
--- Example usage:
---
--- playlistRules.cellNameExact { 'balmora, caius cosades\'s house' = true, 'balmora, guild of mages' = true, }
---@param cellNames IDPresenceMap
---@return boolean
function PlaylistRules.cellNameExact(cellNames)

--- Returns whether the player is currently in combat with any actor out of the input set
--- the playlistState provided to each `isValidCallback` includes a `combatTargets` field which is meant to be used as the first argument
---
--- Exmple usage:
---
--- playlistRules.combatTarget { 'caius cosades' = true, }
---@param validTargets IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetExact(validTargets)

--- Finds any nearby combat target whose name matches any one string of a set
---
--- Example usage:
---
--- playlist.rules.combatTargetMatch { 'jedi', 'sith', }
---@param validTargetPatterns string[]
---@return boolean
function PlaylistRules.combatTargetMatch(validTargetPatterns)

--- Checks the current cell's static list for whether
--- an allowed static is present, or a disallowed one is present.
--- Example usage:
---
--- playlistRules.objectExact { 'furn_de_ex_bench_01' = true, 'ex_ashl_tent_01' = false, }
---@param staticRules IDPresenceMap
---@return boolean?
function PlaylistRules.objectExact(staticRules)

--- REMOVED — Replaced by tagger tag rules + music markers.
---@param patterns string[]
---@return boolean?
function PlaylistRules.staticMatch(patterns)

--- Returns whether or not a given cell contains statics matching the given content file array
--- Automatically lowercases all input content file names!
---
--- playback.rules.staticContentFile { ['starwind enhanced.esm'] = true, }
function PlaylistRules.staticContentFile(contentFiles)

--- Checks whether the current gameHour matches a certain time of day or not
---
--- Example usage:
---
--- playlistRules.timeOfDay(8, 12)
---@param minHour integer
---@param maxHour integer
---@return boolean
function PlaylistRules.timeOfDay(minHour, maxHour)

--- Return whether the current region matches a set
---
--- Example usage:
---
--- playlistRules.region { 'azura\'s coast region' = true, 'sheogorad region' = true, }
---@param regionNames IDPresenceMap
---@return boolean
function PlaylistRules.region(regionNames)


--- Rule for checking whether combat targets match a specific type. This can be for NPCs, or specific subtypes of creatures, such as undead, or daedric.
--- Valid values are listed under the TargetType enum.
--- NOTE: These are hashsets and only `true` is a valid value.
--- Inputs must always be lowercased. Yes, really.
--- 
--- Example Usage:
--- 
--- playlistRules.combatTargetType { ['npc'] = true }
--- playlistRules.combatTargetType { ['undead'] = true }
---@param targetTypeRules CombatTargetTypeMatches
---@return boolean
function PlaylistRules.combatTargetType(targetTypeRules)

--- Rule for checking if the player is fighting vampires of any type, or clan.
--- To check specific vampire clans, use the faction rule.
---@return boolean
function PlaylistRules.fightingVampires()


--- Sets a relative or absolute limit on combat target levels for triggering combat music.
---
--- levelDifference rules may be relative or absolute, eg a multplier of the player's level or the actual difference in level.
--- They may have a minimum and maximum threshold, although either is optional.
--- Negative values indicate the player is stronger, whereas positive ones indicate the target is stronger.
---
--- Example usage:
---
--- This rule plays if the target's level is equal to or up to five levels bove the player's
--- playlistRules.combatTargetLevelDifference { absolute = { min = 0, max = 5 } }
---
--- This rule is valid if the target's level is within half or twice the player's level. EG if you're level 20, and the target is level 10, this rule matches.
--- playlistRules.combatTargetLevelDifference { relative = { min = 0.5, max = 2.0 } }
---@param levelRule LevelDifferenceMap
function PlaylistRules.combatTargetLevelDifference(levelRule)

--- Checks whether or not an actor meets a specific threshold for any of the three dynamic stats - health, fatigue, or magicka.
--- Any combination of the three will work, and one may use a maximum and/or a minimum threshold
---
--- Rule is valid if an actor has MORE than 25% health
--- playlistRules.dynamicStatThreshold { health = { min = 0.25 } }
---
--- Rule is valid is an actor has LESS THAN 75% magicka.
--- playlistRules.dynamicStatThreshold { magicka = { max = 0.75 } }
---@param statThreshold StatThresholdMap decimal number encompassing how much health the target should have left in order for this playlist to be considered valid
---@return boolean
function PlaylistRules.dynamicStatThreshold(statThreshold)

--- Rule for checking the rank of a target in the specified faction.
--- Like any rule utilizing a LevelDifferenceMap, either min or max are optional, but *one* of the two is required.
---
--- Example usage:
---
--- playlistRules.combatTargetFaction { hlaalu = { min = 1 } }
---@param factionRules NumericPresenceMap
function PlaylistRules.combatTargetFaction(factionRules)

--- Playlist rule for checking a specific journal state
---
--- Example usage:
---
--- playback.rules.journal { A1_V_VivecInformants = { min = 50, max = 55, }, }
---@param journalDataMap NumericPresenceMap
---@return boolean
function PlaylistRules.journal(journalDataMap)

--- Checks whether any combat target's classes matches one of a hashset
--- ALWAYS LOWERCASE YOUR INPUTS!
--- 
--- Example Usage:
--- 
--- playlistRules.combatTargetClasses { ['guard'] = true, ['acrobat'] = true }
---@param classes IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetClass(classes)

--- Rule used to check if a nearby merchant does, or doesn't, offer a specific service.
--- Works on all nearby actors, and bails and returns true for the first actor whom matches all provided rules.
--- Works best in locations where a single merchant is present - for cells where multiple actors may potentially offer the same service, like The Abecette,
--- a cellNameMatch or cellNameExact rule may be more appropriate.
--- Only accepts a limited range of inputs as defined by the ServicesOffered type.
---
--- Example Usage:
---
--- local services = { ["Armor"] = true, ['Repair'] = true, }
--- playlistRules.localMerchantType(services)
---@param services ServicesOffered
---@return boolean
function PlaylistRules.localMerchantType(services)

--- Returns whether the current exterior cell is on a particular node of the grid
---
--- Example usage:
---
--- playlistRules.exteriorGrid { { x = -2, y = -3 } }
---@param gridRules S3maphoreCellGrid[]
function PlaylistRules.exteriorGrid(gridRules)
```

All of these functions may be chained, used, ignored, or even reimplemented by you, as long as your playlist's `isValidCallback` returns true when it's supposed to play and false|nil when it isn't.

NOTE:
    While S3maphore doesn't *require* that you use its built-in callbacks, your life will be easier if you do. S3maphore caches as many of its lookups as it possibly can, so one particular cell for example, will only *really* run the necessary code for these callbacks if it's never happened before.
    In practice, this means most of the performance hit from S3maphore occurs during cell transitions. Increased usage will also occur durng combat as a much larger segment of the total number of registered playlist is iterated.

Optimizing your playlists is important!

S3maphore works by calling every `isValidCallback`, for every playlist which is marked as `active` and has at least one track, every single frame. This is why the caching is necessary, and why it's important to keep your isValidCallbacks simple where you can.

Use S3maphore's open ended nature to your advantage, but *please* keep in mind that every playlist is running its callbacks every single frame. You are sharing not-a-lot of space with a lot of neighbors who are very much in a hurry.

If you do run into performance bottlenecks with your playlists, please let me know and I will do everything I can to help make your playlists functional. Later iterations of S3maphore are likely to rely on my helper library, [H3lp Yours3lf](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/h3lp_yours3lf/), for additional optimizations!

#### Playlist Environment Specification

Starting from version `0.54` and onward, S3maphore provides a builtin environment to playlists which can be used to simplify the creation of playlists.
For example, a playlist which used to look like this:

```lua
local function crystalCityRule(playback)
    return playback.rules.cellNameExact(CrystalCityCells)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'MOMW Patches - Secrets of the Crystal City',
        priority = PlaylistPriority.CellExact,

        tracks = {
            'music/aa22/tew_aa_3.mp3',
        },

        isValidCallback = crystalCityRule,
    },
}
```

May now be:

```lua
local function crystalCityRule()
    return Playback.rules.cellNameExact(CrystalCityCells)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'MOMW Patches - Secrets of the Crystal City',
        priority = PlaylistPriority.CellExact,

        tracks = {
            'music/aa22/tew_aa_3.mp3',
        },

        isValidCallback = crystalCityRule,
    },
}
```

The idea is to provide a bunch of built-in variables and functions to playlists so that it is no longer necessary for every playlist to `require` the same things every other one does. S3maphore's built-in event handling functions and tilesets are provided through this environment, as well as `openmw.interfaces`, and many builtin lua functions you otherwise would not have access to.

The environment is easily extensible through the core.lua which creates it, so please feel free to request new functions here.

Full playlist environment specification:

```lua
---@class S3maphorePlaylistEnv
local PlaylistEnvironment = {
    playSpecialTrack = MusicManager.playSpecialTrack,
    skipTrack = MusicManager.skipTrack,
    setPlaylistActive = MusicManager.setPlaylistActive,
    timeOfDay = MusicManager.playlistTimeOfDay,
    INTERRUPT = MusicManager.INTERRUPT,
    ---@type PlaylistPriority
    PlaylistPriority = require 'doc.playlistPriority',
    Tilesets = require 'doc.tilesets',
    Playback = Playback,
    ---@type table <string, any>
    I = I,
    require = require,
    math = math,
    string = string,
    table = table,
    ipairs = ipairs,
    pairs = pairs,
    --- Takes any number of paramaters and deep prints them, if debug logging is enabled
    ---@param ... any
    print = function(...)
        helpers.debugLog(helpers.deepToString({ ... }, 3))
    end,
}
```

## The Special Playlist

The `Special` playlist is, well, a special case - it comes with no tracks, and is the ONLY playlist which is allowed to do so intentionally. Playing a special track using either the below events or interfaces will play the specified track, once, and then fall back to whatever playback behavior is contextually appropriate. This can be useful for playing things like boss music, or the levelup sting.

## Playlist Localization

*All* S3maphore playlists natively support being localized, thanks to OpenMW's use of the l10n system. To provide localizations for a playlist, make a folder adjacent to your playlists folder, called `l10n`. Inside of that, make another folder called, `S3maphoreTracks${PLAYLIST_ID}`. For example, the builtin music playlists are in `S3maphoreTracksExplore` and `S3maphoreTracksBattle`. You'll see localized versions of track and playlist names onscreen as they change, if you have the `BannerEnabled` setting enabled.

## Events

S3maphore includes a selection of `Player` events which indicate the changing of tracks and responds to some to modify its behavior.

1. S3maphoreSkipTrack - `()` - skips the current track
1. S3maphoreToggleMusic - `(boolean)` - set whether music plays or not. Will immediately stop playback when disabling.
1. S3maphoreSetPlaylistActive - `({ playlist: string, state: boolean })` - Enables or disables a playlist
1. S3maphoreSpecialTrack - `({ trackPath: string, reason: S3maphoreStateChangeReason? })` - plays one specific track from the `special` playlist which will not be interrupted, but may be overridden by other playlists in the `Special` priority class.
1. S3maphoreTrackChanged - `(S3maphorePlaybackChangeEventData)` - Emitted whenever S3maphore accepts a normal or special track change. Normal track changes include cell and playback sequencing fields so stale deferred events can be rejected; consumers should treat those fields as read-only metadata.
1. S3maphoreMusicStopped - `({ reason: S3maphoreStateChangeReason })` - Emitted when music stops because playback was disabled or no playlist is valid for the current frame.

### S3maphorePlaybackChangeEventData Specification

```lua
---@class S3maphorePlaybackChangeEventData
---@field fadeOut number?
---@field cellId string? Cell in which a normal track change was requested.
---@field playbackEpoch integer? Internal sequencing value for normal deferred track changes.
---@field playlistId string
---@field trackName string VFS path of the track being played
---@field reason S3maphoreStateChangeReason
```

See the interface documentation immediately below for the `S3maphoreStateChangeReason` specification.

The cell-presence events used to refresh contextual state are internal synchronization events. Do not send them or depend on their payloads.

### Interface

If you need more direct control over what S3maphore is doing, it also offers an interface in `Player` scope, `I.S3maphore`. This is *especially* useful for debugging S3maphore via the console, as almost all of its important playlist-related functionality is exposed through this interface. The `S3maphoreSkipTrack`, `S3maphoreToggleMusic`, `S3maphoreSetPlaylistActive`, and `S3maphoreSpecialTrack` events are all shorthands for calling functions in this interface.

The various functions available are as follows:

```lua
---@param trackPath string VFS path of the track to play
---@param reason S3maphoreStateChangeReason
function S3maphore.playSpecialTrack(trackPath, reason)

--- Returns a string listing all the currently registered playlists, mapped to their (descending) priority.
--- Mostly intended to be used via the `luap` console.
---@return string
function S3maphore.listPlaylistsByPriority()

--- Disable or enable music playback (via a setting, which persists through boot cycles)
---@param enabled boolean?
function S3maphore.overrideMusicEnabled(enabled)

--- Whether or not S3maphore's music playback is enabled
function S3maphore.getEnabled()

--- Returns a read-only array of all recognized playlist files (files with the .lua extension under the VFS directory, Playlists/ )
---@return ReadOnlyTable playlistFiles
function S3maphore.listPlaylistFiles()

--- Returns a read-only list of read-only playlist structs for introspection. To modify playlists in any way, use other functions.
function S3maphore.getRegisteredPlaylists()

--- Returns a read-only copy of the current playlist, or nil
---@return userdata? readOnlyPlaylist
function S3maphore.getCurrentPlaylist()

--- Returns l10n-localized metadata for the current playlist and track. Returns nil, nil if nothing is playing.
---@return S3maphorePlaylistMetadata? playlistMetadata, S3maphoreTrackMetadata? trackMetadata
function S3maphore.getCurrentTrackInfo()

--- Returns the path of the currently playing track
---@return string?
function S3maphore.getCurrentTrack()

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function S3maphore.registerPlaylist(playlist)

--- Used as the `reason` argument in S3maphore Events
---@enum S3maphoreStateChangeReason
S3maphore.STATE = util.makeReadOnly {
    Died = 'DIED',
    Disabled = 'DSBL',
    NoPlaylist = 'NPLS',
    PlaylistChanged = 'PLCH',
    SpecialTrackPlaying = 'SPTR',
    TrackChanged = 'TRCH',
},

--- Meant to be used in conjunction with the output of MusicManager.playlistTimeOfDay OR PlaylistState.playlistTimeOfDay
---@enum TimeMap
S3maphore.TIME_MAP = util.makeReadOnly {
    [0] = 'night',
    [1] = 'morning',
    [2] = 'afternoon',
    [3] = 'evening',
}
```
