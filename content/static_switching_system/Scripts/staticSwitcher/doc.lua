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

---@class ReplacedObjectData
---@field originalObject openmw.GObject
---@field sourceFile string

---@class SourceMapData
---@field logString string log prefix associated with this specific mesh replacement
---@field sourceFile string the basename of the yaml file which defined this replacement

---@class ExteriorGrid
---@field x integer X coordinate of an exterior cell in which to replace objects
---@field y integer Y coordinate of an exterior cell in which to replace objects

---@class SSSModule
---@field cellNameMatches string[]? list of cell names which will be fuzzy-matched for a given module
---@field meshMap ReplacementMap? normalized old mesh path to normalized replacement mesh path
---@field gridIndices table<SzudzikCoord, true>? exterior cell indices handled by this module
---@field logString string? prefix displayed when
---@field ignoreRecords table<RecordId, true>? list of records which this module will explicitly ignore during replacement

--- A Static Switching System module as it exists in YAML format.
--- Most fields are NOT optional, and a corresponding JSON Schema exists for them as well.
---@class SSSModuleRaw
---@field log_name string?

---@class SSSModuleInstances: SSSModuleRaw
---@field instances SSSInstanceRule[] set of game object rules to muck with

---@class SSSModuleStatic: SSSModuleRaw
---@field replace_names string[]? array of cell names to match replacements for
---@field exterior_cells ExteriorGrid[]? array of grid indices in which a particular module will replace objects
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

---@class SSSInstanceAction
---@field replace SSSReplaceAction?
---@field transform SSSTransformAction?

---@class SSSConditionData
---@field carrying string|table<RecordId, integer>?
---@field cell string?
---@field coords ExteriorGrid?
---@field content_file string?
---@field name string?
---@field object_type string?
---@field record_id string?
---@field ref_num number?

---@class SSSInstanceRule
---@field conditions SSSConditionData[]?
---@field actions SSSInstanceAction[]
---@field actionHash string hash of the table. Provided *after* being parsed from YAML data.
---@field once boolean?

---@class SSSInstanceModification
---@field moduleName string module that provided this modification rule
---@field actionHash string stable hash of the parsed rule data
---@field once boolean? whether this rule should only apply once to a saved object
---@field actions SSSInstanceAction[]

---@alias SSSObjectModificationStore table<string, SSSInstanceRule[]>
---@alias SSSInstanceModificationList SSSInstanceModification[]
---@alias SSSOverrideRecords table<string, ReplacementMap>
---@alias SSSReplacedObjectSet table<string, table<openmw.GObject, openmw.GObject>>

---@class SSSOnceCacheEntry
---@field object openmw.GObject remappable saved object handle used to rebuild the runtime object-id index
---@field modules table<string, table<string, true>> module name to action hash set

---@class SSSOnceCache
---@field entries SSSOnceCacheEntry[] serialized entry list containing remappable object handles
---@field byObjectId table<string, SSSOnceCacheEntry> runtime-only cache rebuilt from remapped object handles

---@class SSSOnceCacheSaved
---@field schemaVersion integer once-cache schema version
---@field entries SSSOnceCacheEntry[] serialized entry list containing remappable object handles

---@class SSSModuleCatalog
---@field moduleNames string[] loaded module base names
---@field numModules number number of loaded module base names
---@field ObjectModificationStore SSSObjectModificationStore module-name keyed instance modification rules

---@class SSSStaticReplacements
---@field ComposedReplacements table<string, SSSModule> module-name keyed static replacement data
---@field OverrideRecords SSSOverrideRecords module-name keyed generated replacement record IDs
---@field ReplacedObjectSet SSSReplacedObjectSet module-name keyed replacement object to original object map
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
---@field replacedObjectSet SSSReplacedObjectSet?

---@class openmw.interfaces.StaticSwitcher_G
---@field getRefNum fun(object: openmw.GObject): boolean, number Returns whether the object is generated and its local/generated reference number.
---@field objectModificationStore fun(): SSSObjectModificationStore Returns the loaded instance-modification rule store.
---@field overrideRecords fun(): SSSOverrideRecords Returns generated override record IDs keyed by module name.
---@field replacedObjectSet fun(): SSSReplacedObjectSet Returns replacement objects keyed by module name for uninstall bookkeeping.
---@field uninstallModule fun(moduleName: string) Queues uninstall/removal for a loaded replacement module.
---@field version integer Static Switching System interface version.

---@class openmw.interfaces
---@field StaticSwitcher_G openmw.interfaces.StaticSwitcher_G

---@class RotationParamInput
---@field isRelative boolean
---@field currentTransform openmw.util.Transform
---@field rotateActionDetails SSSVector3Range map of axes to rotations as degrees
