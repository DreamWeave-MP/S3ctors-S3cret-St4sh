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

---@class RangeTable
---@field min integer? defaults to 1 if not present
---@field max integer

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
---@field cellNameMatches string[] list of cell names which will be fuzzy-matched for a given module
---@field meshMap ReplacementMap
---@field gridIndices table<SzudzikCoord, true>
---@field logString string? prefix displayed when
---@field ignoreRecords table<string, true> list of records which this module will explicitly ignore during replacement

--- A Static Switching System module as it exists in yaml format.
--- Most fields are NOT optional, and a corresponding JsonSchema exists for them as well.
---@class SSSModuleRaw
---@field log_name string?

---@class SSSModuleInstances: SSSModuleRaw
---@field instances table<string, table> Set of gameobjectt record ids or refNums to muck with

---@class SSSModuleStatic: SSSModuleRaw
---@field replace_names string[] array of cell names to match replacements for
---@field exterior_cells ExteriorGrid[] array of grid indices in which a particular module will replace objects
---@field replace_meshes table<string, string> map of old meshes to new ones
---@field ignore_records string[] records to ignore when replacing with this module. Typically used for scripted objects, but maybe not.
