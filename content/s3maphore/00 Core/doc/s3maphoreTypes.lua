---@meta

tes3 = tes3

---@class ReadOnlyTable: table A table, but, one which may not be written to or have its metatable changed
---@class StrictReadOnlyTable: table A table, but, one which may not be written to or have its metatable changed. This version will throw if one indexes the table with a key which doesn't exist.
---@class UpdatingSettingTable: table<any, any> A table which is constructed with an explicit association with a player storage section. Values inside this table automatically update according to changes in the storage group.

---@class CellMatchPatterns
---@field disallowed string[]
---@field allowed string[]

---@class CombatTargetChangedData
---@field actor openmw.LObject? Don't think this should ever be nil, but the `actor` field represents whomever has entered or exited combat
---@field targets openmw.LObject[] List of targets whom this actor is in combat with. If the array is empty, the target has left combat for one or another reason.

---@alias CombatTargetTypeMatches table<TargetType, true>

---@alias TimeOfDay
---| 'night'
---| 'morning'
---| 'afternoon'
---| 'evening'

--- Alias for defining S3maphore rules for object record ids allowing or disallowing playlist selection
---@alias IDPresenceMap table<string, boolean>

--- Describes either the relative or absolute level difference between the player and a given target.
--- Both fields are technically optional, but one of the two must exist.
--- Negative level differences indicate the player is a higher level than the target,
--- whereas a positive one indicates the target is a higher level than the player
---@class LevelDifferenceMap
---@field absolute NumericPresenceMapData?
---@field relative NumericPresenceMapData?

---@alias NumericPresenceMap table<string, NumericPresenceMapData>

---@class NumericPresenceMapData
---@field min integer? if omitted, uses 0.0
---@field max integer? If omitted, then math.huge is used

--- Data type used to bridge one playlist into another, or to extend
---@class PlaylistFallback
---@field playlistChance number? optional float between 1 and 0 indicating the chance for a fallback playlist to be selected. If not present, the chance is always 50%
---@field playlists string[]? array of fallback playlists from which to select tracks. No default values and not required.
---@field tracks string[]? tracks to manually add to a given playlist. Used for folder-based playlists; not necessary for any others

---@class PlaylistSilenceParams
---@field min integer minimum possible duration for this silence track
---@field max integer maximum possible duration for this silence track
---@field chance number probablility that this playlist will use silence between tracks

---@class QueuedEvent
---@field name string? the name of the event to send. If nil, no event will be sent.
---@field data any the data to send with the event

--- Player cell name/id mapped to the memory address of the table being looked up. Only used in the most expensive rulesets
---@alias S3maphoreCacheKey string

--- Special class for handling exterior grids.
--- Used for special circumstances in which playlists should only run in *particular* exterior cells
---@class S3maphoreCellGrid
---@field x integer
---@field y integer

---@class S3maphorePlaybackParamsTable
---@field fadeOut number

--- Lookup table for storing the results of location-based matches
---@alias S3maphoreMatchCache table<string, boolean>

---@alias S3maphoreMovementMode
---| 'standing'
---| 'walking'
---| 'running'
---| 'sneaking'
---| 'swimming'
---| 'flying'

--- Bitsum of state flags indicating what changed, sent directly as the data argument
--- of the `S3maphoreStateChanged` event. Test individual flags with
--- `util.bitAnd(flags, MusicManager.STATE_FLAGS.TOD) ~= 0`.
---@alias S3maphoreStateChangedFlag integer

---@class S3maphorePlaylist
---@field id string name of the playlist
---@field priority number priority of the playlist, lower value means higher priority
---@field tracks string[]? list of tracks in the playlist. If not provided, tracks will be loaded from the music/ subdirectory with the same name as the playlist ID.
---@field randomize boolean? if true, tracks will be played in random order. Defaults to false.
---@field active boolean? if true, the playlist is active and will be played. Defaults to false
---@field cycleTracks boolean? if true, the playlist will cycle through tracks. Defaults to true
---@field playOneTrack boolean? if true, the playlist will play only one track and then deactivate. Defaults to false
---@field registrationOrder number? the order in which the playlist was registered, used for sorting playlists by priority. Do not provide in the playlist definition, it will be assigned automatically.
---@field deactivateAfterEnd boolean? if true, the playlist will be deactivated after the current track ends. Defaults to false.
---@field interruptMode InterruptMode? whether a given playlist may be interrupted by another. `INTERRUPT.Override` always overrides the current playlist when selected, including a current playlist using `INTERRUPT.Never` or when Finish Previous Track is enabled.
---@field isValidCallback ValidPlaylistCallback? The function used to determine whether or not a playlist should execute on this particular frame. NOTE: This field is only optional in the event that the playlist's priority is NOT `PlaylistPriority.Never`
---@field fallback PlaylistFallback?
---@field fadeOut number? Optional duration supplied by a playlist which indicates how long the fadeout between tracks should be. If not present then the global fadeOut setting is used.
---@field silenceBetweenTracks PlaylistSilenceParams?
---@field exclusions S3maphorePlaylistExclusions?

---@class S3maphorePlaylistExclusions
---@field playlists string[]? list of subdirectories to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.
---@field tracks string[]? explicit list of tracks to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.

---@class S3maphorePlaybackChangeEventData
---@field fadeOut number?
---@field cellId string? Cell in which a normal track change was requested.
---@field playbackEpoch integer? Playback generation for rejecting stale deferred track changes.
---@field playlistId string
---@field reason S3maphoreStateChangeReason
---@field trackName string VFS path of the track being played

---@class S3maphorePlayback
---@field rules PlaylistRules
---@field state PlaylistState

---@class CombatState
---@field actorIsInCombat fun(actorId: string): boolean Whether S3maphore currently tracks the given actor as a combat target.
---@field batchPoll fun(dt: number) Batch per-frame combat target polling across nearby actors.
---@field getCombatTargets fun(): ReadOnlyTable Live read-only array of current combat targets.
---@field isInCombat fun(): boolean Whether the player is in combat, independent of music settings. Raw combat-target check; does not consider BattleEnabled.
---@field onHit fun(): boolean Handle a hit event; returns whether combat state changed as a result.
---@field onTargetsChanged fun(actor: openmw.LObject, targets: openmw.LObject[]) Handle target list changes.
---@field recomputeState fun() Recompute the internal combat state and update PlaylistState accordingly.
---@field resetPollCycle fun() Reset actor polling to start from the beginning (call on cell transitions).

---@alias ServicesOffered table<ServiceType, boolean>

---@alias ServiceType
---| 'Apparatus'
---| 'Armor'
---| 'Barter'
---| 'Books'
---| 'Clothing'
---| 'Enchanting'
---| 'Ingredients'
---| 'Lights'
---| 'Misc'
---| 'MagicItems'
---| 'Repair'
---| 'RepairItem'
---| 'Spellmaking'
---| 'Spells'
---| 'Training'
---| 'Travel'
---| 'Picks'
---| 'Potions'
---| 'Probes'
---| 'Weapon'

---@class StatThresholdMap
---@field health NumericPresenceMapData?
---@field magicka NumericPresenceMapData?
---@field fatigue NumericPresenceMapData?

---@alias TargetType
---| 'npc'
---| 'humanoid'
---| 'undead'
---| 'daedra'
---| 'creatures'

---@alias ValidPlaylistCallback fun(playback: S3maphorePlayback?): boolean? a function that returns true if the playlist is valid for the current context. If not provided, the playlist will always be valid.

---@alias VampireType
---| 'quarra'
---| 'aundae'
---| 'berne'

---@alias VampireTypes VampireType[]

---@class CellPresence
---@field byRecord table<string, number>
---@field byType table<string, number>
---@field byContentFile table<string, number>
---@field staticContentFiles string[]
---@field nearestRegion string?
---@field cellHasHostileActors boolean
---@field areaHasHostileActors boolean
---@field cellId string?
---@field generation integer?

---@class S3maphoreMusicMetadataBase
---@field title string Human-readable title
---@field artist string?
---@field album string?
---@field year integer?
---@field genre string?
---@field description string?
---@field source string?
---@field composer string?
---@field license string?

---@class S3maphoreTrackMetadata: S3maphoreMusicMetadataBase

---@class S3maphorePlaylistMetadata: S3maphoreMusicMetadataBase

---@class S3maphoreMusicMetadataRegistry
---@field getPlaylistDisplayName fun(id: string): string
---@field getPlaylistMetadata fun(id: string): S3maphorePlaylistMetadata?
---@field getTrackMetadata fun(trackPath: string): S3maphoreTrackMetadata?
---@field loadYamlFile fun(path: string)
---@field iterPlaylists fun(): fun(state: table<string, S3maphorePlaylistMetadata>, key: string?): string, S3maphorePlaylistMetadata
---@field iterTracks fun(): fun(state: table<string, S3maphoreTrackMetadata>, key: string?): string, S3maphoreTrackMetadata

---@class openmw.interfaces
---@field S3maphore? openmw.interfaces.S3maphore

---@alias TrackChangedHandler fun(eventData: S3maphorePlaybackChangeEventData): boolean?

---S3maphore music manager interface.
---
---Registered in Player context. Available from any context after the player script has initialized.
---
---Example usage:
---
---```lua
---local I = require('openmw.interfaces')
---
---- Skip the current track
---I.S3maphore.skipTrack()
---
---- Query current combat state
---local inCombat = I.S3maphore.state.isInCombat
---
---- Check what the player is fighting
---local undead = I.S3maphore.rules.combatTargetType { undead = true }
---
---- Register a custom playlist with region rules
---I.S3maphore.registerPlaylist {
---    id = 'MyRegionMusic',
---    priority = 900,
---    tracks = { 'music/my/ashlands.mp3', 'music/my/bittercoast.mp3' },
---    isValidCallback = function(playback)
---        return playback.rules.region { ['ashlands region'] = true }
---    end,
---}
---
---- Listen for track changes
---I.S3maphore.addTrackChangedHandler(function(eventData)
---    print(('Now playing: %s from %s'):format(eventData.trackName, eventData.playlistId))
---end)
---```
---@class openmw.interfaces.S3maphore
---@field skipTrack fun() Skip the currently playing track. The state machine naturally picks the next track or playlist.
---@field playSpecialTrack fun(trackPath: string, reason: S3maphoreStateChangeReason?) Play a one-off track, overriding normal playback until the track ends.
---@field overrideMusicEnabled fun(enabled: boolean?) Toggle music playback. Without an argument, inverts the current state.
---@field getEnabled fun(): boolean Whether music playback is currently enabled.
---@field setPlaylistActive fun(id: string, state: boolean) Enable or disable a registered playlist by ID.
---@field getCurrentTrack fun(): string? VFS path of the currently playing track, or nil if nothing is playing.
---@field getCurrentTrackInfo fun(): S3maphorePlaylistMetadata?, S3maphoreTrackMetadata? Display metadata for the current playlist and track. Returns nil, nil if nothing is playing.
---@field getCurrentPlaylist fun(): ReadOnlyTable? Read-only snapshot of the currently active playlist, or nil.
---@field getRegisteredPlaylists fun(): ReadOnlyTable Read-only map of all registered playlists (id → playlist).
---@field listPlaylistFiles fun(): ReadOnlyTable Read-only array of recognized playlist file paths under the Playlists/ VFS directory.
---@field listPlaylistsByPriority fun(): string Formatted string of registered playlists sorted by priority (lowest first), intended for `luap` console inspection.
---@field getState fun(): ReadOnlyTable Read-only snapshot of the current PlaylistState. Prefer the `state` field for live read-only access.
---@field silenceTime fun(): number Current silence duration from the active playlist's silenceBetweenTracks params.
---@field registerPlaylist fun(playlist: S3maphorePlaylist) Register a playlist, auto-assigning tracks from folders, setting track order, and persisting activation state.
---@field addTrackChangedHandler fun(handler: TrackChangedHandler) Register a callback invoked on every track change.
---@field getDeathTrack fun(): string The current death track VFS path. Defaults to `music/special/mw_death.mp3`.
---@field setDeathTrack fun(path: string) Set the death track VFS path. Silently no-ops if the file does not exist.
---@field resetDeathTrack fun() Restore the death track to the default `music/special/mw_death.mp3`.
---@field playlistTimeOfDay fun(): TimeOfDay Current time-of-day bucket (night/morning/afternoon/evening), determined by the game clock.
---@field playlistMetadata S3maphoreMusicMetadataRegistry Metadata registry for playlist display names, track info, and YAML loading.
---@field const { STATE: StateChangeReasons, TIME_MAP: TimeMap, INTERRUPT: InterruptModes, STATE_FLAGS: StateChangedFlags } Constant enums for playback reasons, time-of-day buckets, interrupt modes, and state-change flag bitmasks.
---@field state PlaylistState Live read-only proxy over the current S3maphore runtime state. All fields forward to the real PlaylistState; writes throw.
---@field rules PlaylistRules All playlist rule functions for environment queries. Uses the same cached lookups as playlist isValidCallbacks.
---@field actorIsInCombat fun(actorId: string): boolean Whether S3maphore currently tracks the given actor as a combat target.
---@field getCombatTargets fun(): ReadOnlyTable Live read-only array of current combat targets.
---@field isInCombat fun(): boolean Whether the player is in combat, independent of music settings. See also `state.isInCombat` (settings-adjusted).
