---@alias MeshToSourceMap table<string, SourceMapData> Maps a new mesh to the source file which defined this replacement.
---@alias OriginalModel RecordId
---@alias ReplacedRecordId RecordId
---@alias ReplacementMap table < OriginalModel, ReplacedRecordId >
---@alias RecordId string
---@alias SzudzikCoord integer

---@class ObjectDeleteData
---@field object GameObject
---@field ticks integer number of frames before this object will be deleted
---@field removeOrDisable boolean whether or not the object will be permanently removed or just disabled. When replacing, the original objects are disabled, but when uninstalling a module the replacements are removed and the originals restored.

---@class ReplacedObjectData
---@field originalObject GameObject
---@field sourceFile string

---@class SourceMapData
---@field logString string log prefix associated with this specific mesh replacement
---@field sourceFile string the basename of the yaml file which defined this replacement

---@class ExteriorGrid
---@field x integer X coordinate of an exterior cell in which to replace objects
---@field y integer Y coordinate of an exterior cell in which to replace objects

---@class ReplacementFileData
---@field log_name string? prefix to use when logging messages for a specific module
---@field replace_names string[]? array of cell names in which to replace objects
---@field exterior_cells ExteriorGrid[]? array of exterior grids in which to replace objects
---@field replace_meshes table<string, string>? table of original mesh paths to the desired new ones. These paths may or may not contain the `meshes/` prefix as the script will prepend it automatically if not present.

---@class ActivatorRecord
---@field name string? human-readable name displayed for this objecdt
---@field mwscript string? recordId of the mwscript running on this object
---@field id RecordId
---@field model string? mesh displayed for the object in game. If not present (usually a light), then the record is completely ignored.

---@class GameCell
---@field name string?
---@field gridX integer exterior X coordinate of the cell. Be warned this is present even for interiors and fake exteriors.
---@field gridY integer exterior Y coordinate of the cell. Be warned this is present even for interiors and fake exteriors.

---@class GameObject
---@field recordId RecordId
---@field type table<string, any>
---@field scale integer Object scale
---@field enabled boolean
---@field count integer
---@field cell GameCell
---@field isValid fun(): boolean whether or not the object is currently valid, eg teleporting or similar
---@field remove fun(self: GameObject, count: integer?) destroy the object completely
---@field position util.vector3
---@field getBoundingBox fun(): userdata
---@field teleport fun(cell: GameCell, position: util.vector3, options: table)
---@field sendEvent fun(eventName: string, eventData: any)
---@field id string The unique identifier for the object.
---@field rotation integer Totally not an integer and totally not updating these docs lol
