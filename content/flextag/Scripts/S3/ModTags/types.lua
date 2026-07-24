---@meta

---An identifying tag applied to a gameObject or record.
---@alias FlexTag.ObjectTag string

---A set of tags, keyed by tag name.
---@alias FlexTag.ObjectTagList table<FlexTag.ObjectTag, boolean>

---A map of record IDs to their applied tag sets.
---@alias FlexTag.AppliedTags table<string, FlexTag.ObjectTagList>

---Any game object that can carry tags: a string recordId, an OpenMW game object, or a cell.
---@alias FlexTag.Taggable string | openmw.GObject | openmw.LObject | openmw.SelfObject | openmw.core.GCell | openmw.core.LCell

---A single tag or an array of tags.
---@alias FlexTag.TagArg string | FlexTag.ObjectTag[]

---The public FlexTag interface. Exposed as FlexTagG (global scripts) and FlexTagL (all other contexts).
---@class FlexTag.Interface
---@field addTag fun(object: FlexTag.Taggable, tag: FlexTag.TagArg)
---@field removeTag fun(object: FlexTag.Taggable, tag: FlexTag.TagArg)
---@field objectHasTag fun(object: FlexTag.Taggable, tag: FlexTag.ObjectTag | FlexTag.ObjectTag[]): true??
---@field objectTags fun(object: FlexTag.Taggable): FlexTag.ObjectTagList?
---@field tagList fun(): FlexTag.ObjectTagList
---@field appliedTags fun(): FlexTag.AppliedTags
---@field getRecordsWithTag fun(tag: FlexTag.ObjectTag): string[]
---@field ingestTag fun(recordId: string, tagName: FlexTag.ObjectTag) @private
---@field removeTagFromMemory fun(recordId: string, tagName: FlexTag.ObjectTag) @private
---@field _isLoadingComplete fun(): boolean @private
---@field markLoadingComplete fun() @private
---@field syncToStorage fun() @private

---@class openmw.interfaces
---@field FlexTagG FlexTag.Interface
---@field FlexTagL FlexTag.Interface
