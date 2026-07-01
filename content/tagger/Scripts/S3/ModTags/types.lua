---@meta

---An identifying tag applied to a gameObject or record.
---@alias Tagger.ObjectTag string

---A set of tags, keyed by tag name.
---@alias Tagger.ObjectTagList table<Tagger.ObjectTag, boolean>

---A map of record IDs to their applied tag sets.
---@alias Tagger.AppliedTags table<string, Tagger.ObjectTagList>

---Any game object that can carry tags: a string recordId, an OpenMW game object, or a cell.
---@alias Tagger.Taggable string | openmw.GObject | openmw.LObject | openmw.SelfObject | openmw.core.GCell | openmw.core.LCell

---A single tag or an array of tags.
---@alias Tagger.TagArg string | Tagger.ObjectTag[]

---The public Tagger interface. Exposed as TaggerG (global scripts) and TaggerL (local/player/menu scripts).
---@class Tagger.Interface
---@field addTag fun(object: Tagger.Taggable, tag: Tagger.TagArg)
---@field removeTag fun(object: Tagger.Taggable, tag: Tagger.TagArg)
---@field objectHasTag fun(object: Tagger.Taggable, tag: Tagger.ObjectTag | Tagger.ObjectTag[]): true??
---@field objectTags fun(object: Tagger.Taggable): Tagger.ObjectTagList?
---@field tagList fun(): Tagger.ObjectTagList
---@field appliedTags fun(): Tagger.AppliedTags
---@field getRecordsWithTag fun(tag: Tagger.ObjectTag): string[]
---@field ingestTag fun(recordId: string, tagName: Tagger.ObjectTag) @private
---@field removeTagFromMemory fun(recordId: string, tagName: Tagger.ObjectTag) @private
---@field _isLoadingComplete fun(): boolean @private
---@field markLoadingComplete fun() @private
---@field syncToStorage fun() @private
