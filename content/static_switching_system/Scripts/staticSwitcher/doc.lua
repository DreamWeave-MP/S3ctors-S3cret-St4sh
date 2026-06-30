---@meta

---@alias MeshToSourceMap table<string, SourceMapData> Maps a new mesh to the source file which defined this replacement.
---@alias OriginalModel RecordId
---@alias ReplacedRecordId RecordId
---@alias ReplacementMap table < OriginalModel, ReplacedRecordId >
---@alias RecordId string
---@alias SzudzikCoord integer
---@alias SSSConditionHandler fun(object: openmw.GObject, matchData: any): boolean

--- Represents the uppermost bits to strip off of an object ID in order to determine its local reference number
--- math.pow(2, 24)
---@alias ContentFileBits
---| 16777216

---@alias SSSNumericRange number|RangeTable

---@class RangeTable
---@field min number? lower bound for random range; caller supplies its own default when absent
---@field max number required upper bound for random range

---@class ObjectDeleteData
---@field object openmw.GObject
---@field ticks integer number of frames before this object will be deleted
---@field removeOrDisable boolean whether or not the object will be permanently removed or just disabled. When replacing, the original objects are disabled, but when uninstalling a module the replacements are removed and the originals restored.

---@class SSSDeleteManager
---@field queue ObjectDeleteData[]
---@field addObjectToDeleteQueue fun(self: SSSDeleteManager, object: openmw.GObject, removeOrDisable: boolean)
---@field removeObjectFromDeleteQueue fun(self: SSSDeleteManager, targetObject: openmw.GObject, removeOrDisable?: boolean)
---@field processDeleteQueue fun(self: SSSDeleteManager)
---@field queueIsEmpty fun(self: SSSDeleteManager): boolean

---@class ReplacedObjectData
---@field originalObject openmw.GObject
---@field sourceFile string

---@class SourceMapData
---@field logString string log prefix associated with this specific mesh replacement
---@field sourceFile string module source path which defined this replacement

---@class ExteriorGrid
---@field x integer X coordinate of an exterior cell in which to replace objects
---@field y integer Y coordinate of an exterior cell in which to replace objects

---@class SSSModule
---@field cellNameMatches string[]? list of cell names which will be fuzzy-matched for a given module
---@field meshMap ReplacementMap? normalized old mesh path to normalized replacement mesh path
---@field gridIndices table<SzudzikCoord, true>? exterior cell indices handled by this module
---@field regionMatches table<string, true>? lowercase cell region names/ids handled by this module
---@field logString string? prefix displayed when
---@field ignoreRecords table<RecordId, true>? list of records which this module will explicitly ignore during replacement

--- A Static Switching System module as it exists in YAML format.
--- Most fields are NOT optional, and a corresponding JSON Schema exists for them as well.
---@class SSSModuleRaw
---@field log_name string?

---@class SSSModuleInstances: SSSModuleRaw
---@field instances SSSInstanceRule[] set of game object rules to muck with

---@class SSSModuleStatic: SSSModuleRaw
---@field replace_names string[]? array of cell names to match replacements for; omit with exterior_cells and replace_regions to apply replace_meshes in every cell
---@field exterior_cells ExteriorGrid[]? array of grid indices in which a particular module will replace objects; omit with replace_names and replace_regions to apply replace_meshes in every cell
---@field replace_regions string[]? array of exact, case-insensitive cell region IDs/names to match replacements for; ORed with replace_names and exterior_cells
---@field replace_meshes table<string, string> map of old meshes to new ones
---@field ignore_records RecordId[]? records to ignore when replacing with this module. Typically used for scripted objects, but maybe not.

---@alias Axis
---| 'x'
---| 'y'
---| 'z'

---@alias SSSTransformType
---| 'relative'
---| 'absolute'

---@class SSSVector3Range
---@field x SSSNumericRange?
---@field y SSSNumericRange?
---@field z SSSNumericRange?

---@class SSSTransformAction
---@field transform_type SSSTransformType?
---@field scale SSSNumericRange?
---@field rotate SSSVector3Range?
---@field position SSSVector3Range?

---@alias SSSReplaceAction table<RecordId, number>
---@alias SSSChanceRange number|SSSChanceRangeTable

---@class SSSChanceRangeTable
---@field min number? lower bound for a random chance; defaults to 0 when absent
---@field max number required upper bound for a random chance

---@class SSSItemActionDetails
---@field count integer? item count; defaults to 1 when absent
---@field chance SSSChanceRange? fixed or random chance to apply this item entry

---@alias SSSItemAction RecordId|RecordId[]|table<RecordId, integer|SSSItemActionDetails>

--- Instance action tables may combine fields, for example replace + delete.
--- Combined actions run in priority order: replace, transform, add, remove, equip, unequip, disable, delete.
--- Same-table delete paired with replace queues removal only when replacement succeeds;
--- use a separate delete action entry when source removal must be unconditional.
---@class SSSInstanceAction
---@field replace SSSReplaceAction?
---@field transform SSSTransformAction?
---@field add SSSItemAction? queues item(s) into the current action target when it is an Actor or Container
---@field remove SSSItemAction? removes item(s) from the current action target when it is an Actor or Container and enough items are available
---@field equip SSSItemAction? queues forced OpenMW UseItem for item(s) on Actor targets, creating the requested count first only when missing; usable non-equipment may be consumed/used
---@field unequip SSSItemAction? queues forced OpenMW UseItem for currently equipped item(s) on Actor targets; requested count must already be equipped
---@field disable true|{chance: number?}? disables the final action target; with replace, disables the replacement; chance field rolls independently
--- NOTE: Disabled objects do NOT trigger onObjectActive on subsequent cell loads. The engine
--- filters out disabled objects during scene insertion (scene.cpp:248), so there is no engine
--- event path for the SSS to re-enable a disabled object across cell visits. Objects disabled
--- here stay disabled permanently from the SSS's perspective. Use once=true with disable when
--- you want a one-time effect, or avoid disable entirely for objects you want to toggle.
---@field delete true? queues removal of the original matched source object through DeleteManager

---@class SSSConditionData
---@field carrying string|table<RecordId, integer>?
---@field cell string?
---@field cell_match string? substring match against object.cell.name or object.cell.id, case-insensitive
---@field coords ExteriorGrid?
---@field content_file string?
---@field exterior boolean?
---@field quasi_exterior boolean?
---@field has_journal table? Quest journal index: `{quest: string, index?: integer, min?: integer, max?: integer}`. `index` is shorthand for `min`. Returns true when `stage >= min and stage <= max`.
---@field has_name boolean?
---@field mesh string?
---@field nameMatch string?
---@field not table? Inverts a single inner condition, e.g. `{nameMatch = "Guard"}`.
---@field object_type string? Exact OpenMW type name, e.g. Container, Creature, LevelledCreature, Weapon, Armor, NPC, Static, Door, Activator
---@field record_id string? Lua pattern match against the object's record ID; use ^/$ for start/end anchoring
---@field content_file_target table<string, number[]>?
---@field generated boolean?
---@field region string?
---@field scale SSSNumericRange?
---@field worldspace string?

---@class SSSInstanceRule
---@field conditions SSSConditionData[]?
---@field actions SSSInstanceAction[]
---@field actionHash string hash of the table. Provided *after* being parsed from YAML data.
---@field once boolean?

---@class SSSInstanceModification
---@field moduleName string canonical module id that provided this modification rule
---@field actionHash string stable hash of the parsed rule data
---@field once boolean? whether this rule should only apply once to a saved object
---@field actions SSSInstanceAction[]

---@alias SSSObjectModificationStore table<string, SSSInstanceRule[]>
---@alias SSSInstanceModificationList SSSInstanceModification[]
---@alias SSSOverrideRecords table<string, ReplacementMap>
---@alias SSSReplacedObjectSet table<string, table<openmw.GObject, openmw.GObject>>
---@alias SSSReplacementStepBySource table<string, openmw.GObject> runtime-only source object id to replacement object map

---@class SSSReplacementChainStep
---@field moduleName string canonical module id that produced this chain step
---@field source openmw.GObject source object for this replacement edge
---@field replacement openmw.GObject replacement object created by this edge

---@class SSSReplacementChain
---@field root openmw.GObject first source object in this chain
---@field current openmw.GObject latest valid replacement object in this chain
---@field steps SSSReplacementChainStep[] ordered replacement edges
---@field appliedModules table<string, true> canonical module ids already applied to this chain lineage

---@class SSSReplacementChains
---@field entries SSSReplacementChain[] serialized chain list containing remappable object handles
---@field byObjectId table<string, SSSReplacementChain> runtime-only object-id to chain index rebuilt from entries

---@class SSSReplacementChainSavedEntry
---@field root openmw.GObject first source object in this chain
---@field steps SSSReplacementChainStep[] ordered replacement edges

---@class SSSReplacementChainsSaved
---@field entries SSSReplacementChainSavedEntry[] serialized chain list containing remappable object handles

---@class SSSOnceCacheEntry
---@field object openmw.GObject remappable saved object handle used to rebuild the runtime object-id index
---@field modules table<string, table<string, true>> canonical module id to action hash set

---@class SSSOnceCache
---@field entries SSSOnceCacheEntry[] serialized entry list containing remappable object handles
---@field byObjectId table<string, SSSOnceCacheEntry> runtime-only cache rebuilt from remapped object handles

---@class SSSOnceCacheSaved
---@field schemaVersion integer once-cache schema version
---@field entries SSSOnceCacheEntry[] serialized entry list containing remappable object handles

---@class SSSModuleCatalog
---@field moduleNames string[] alias for moduleIds
---@field moduleIds string[] loaded canonical module ids
---@field staticModuleIds string[] loaded canonical module ids that define static replacements and can be uninstalled by the current static-chain uninstall flow
---@field modules table<string, SSSModuleIdentity> canonical module id to identity metadata
---@field moduleLabels table<string, string> canonical module id to display label
---@field legacyIdsByBasename table<string, string[]> legacy basename to candidate canonical module ids
---@field numModules number number of loaded canonical module ids
---@field resolveModuleId fun(moduleKey: string): string? resolves canonical ids and unambiguous legacy basenames
---@field ObjectModificationStore SSSObjectModificationStore canonical module-id keyed instance modification rules

---@class SSSStaticReplacements
---@field ComposedReplacements table<string, SSSModule> canonical module-id keyed static replacement data
---@field loadReplacementChains fun(savedChains?: SSSReplacementChainsSaved)
---@field ReplacementChains SSSReplacementChains saved chain state plus runtime indexes
---@field OverrideRecords SSSOverrideRecords canonical module-id keyed generated replacement record IDs
---@field migrateOverrideRecords fun() migrates unambiguous legacy basename override-record keys to canonical module ids
---@field rebuildReplacementStepBySource fun() rebuilds runtime source-object replacement guard from saved replacement objects
---@field ReplacedObjectSet SSSReplacedObjectSet canonical module-id keyed replacement object to original object map
---@field saveReplacementChains fun(): SSSReplacementChainsSaved
---@field uninstallModule fun(moduleName: string): string? removes the target module and later chain steps, restoring the source before the removed suffix
---@field setModuleResolver fun(moduleResolver: fun(moduleKey: string): string?) sets the canonical module-id resolver for save migration and settings compatibility
---@field tryReplaceObject fun(object: openmw.GObject)

---@class SSSInstanceModifiers
---@field getMatchingInstanceModules fun(object: openmw.GObject): SSSInstanceModificationList?
---@field loadOnceCache fun(savedOnceCache?: SSSOnceCacheSaved)
---@field saveOnceCache fun(): SSSOnceCacheSaved
---@field tryModifyObject fun(object: openmw.GObject, instanceModificationList: SSSInstanceModificationList)

---@class SSSSavedState
---@field overrideRecords SSSOverrideRecords?
---@field objectDeleteQueue ObjectDeleteData[]?
---@field instanceModifiers SSSOnceCacheSaved?
---@field replacementChains SSSReplacementChainsSaved?
---@field replacedObjectSet SSSReplacedObjectSet?

---@class openmw.interfaces.StaticSwitcher_G
---@field getRefNum fun(object: openmw.GObject): boolean, number Returns whether the object is generated and its local/generated reference number.
---@field objectModificationStore fun(): SSSObjectModificationStore Returns the loaded instance-modification rule store.
---@field overrideRecords fun(): SSSOverrideRecords Returns generated override record IDs keyed by canonical module id.
---@field replacedObjectSet fun(): SSSReplacedObjectSet Returns replacement objects keyed by canonical module id for uninstall bookkeeping.
---@field uninstallModule fun(moduleName: string) Queues uninstall/removal for a loaded replacement module.
---@field version integer Static Switching System interface version.

---@class openmw.interfaces
---@field StaticSwitcher_G openmw.interfaces.StaticSwitcher_G

---@class RotationParamInput
---@field isRelative boolean
---@field currentTransform openmw.util.Transform
---@field rotateActionDetails SSSVector3Range map of axes to rotations as degrees

---@class SSSLogger
---@field debug fun(formatString: string, ...: any) Fine-grained trace; format is deferred past the debug-setting guard
---@field info fun(formatString: string, ...: any) General operation info; same deferred-format behavior
---@field warn fun(message: string) Non-critical issues; always prints
---@field error fun(message: string) Critical errors; always prints
---@field isDebugEnabled fun(): boolean Check whether debug logging is active without printing
