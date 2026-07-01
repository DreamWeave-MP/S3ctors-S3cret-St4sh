---@omw-context global | local

local async = require 'openmw.async'
local storage = require 'openmw.storage'
local util = require 'openmw.util'

local SendGlobalEvent = require 'openmw.core'.sendGlobalEvent

local TagSection = storage.globalSection 'TaggerStorage'

local AppliedTags = {}
local TagList = {}
local TagRefCounts = {}

local syncToStorage

local assert, error, pcall, require, tostring, type = assert, error, pcall, require, tostring, type

TagSection:subscribe(async:callback(
	function(_, key)
		if key == 'AppliedTags' then
			AppliedTags = TagSection:get(key)
		elseif key == 'TagList' then
			TagList = TagSection:get(key)
		end
	end
))

local validObjectTypes = {
	['MWLua::GObject'] = true,
	['MWLua::LObject'] = true,
	['MWLua::SelfObject'] = true,
}

local validCellTypes = {
	['MWLua::GCell'] = true,
	['MWLua::LCell'] = true,
}

---@param object Tagger.Taggable
---@return string
local function getRecordId(object)
	local objectType = type(object)

	if objectType == 'string' then
		return object:lower()
		---@diagnostic disable-next-line: undefined-field
	elseif objectType == 'userdata' and validObjectTypes[object.__type.name] then
		return object.recordId
		---@diagnostic disable-next-line: undefined-field
	elseif objectType == 'userdata' and validCellTypes[object.__type.name] then
		return object.id
	else
		---@diagnostic disable-next-line: undefined-field
		local errorTypeName = object.__type and object.__type.name or objectType
		error('Invalid object type: ' .. objectType .. ' ' .. errorTypeName)
	end
end

---Memory-only tag ingestion. Updates AppliedTags but does NOT write to storage.
---Used by the YAML loader coroutine during staggered startup.
---@param recordId string
---@param tagName Tagger.ObjectTag
local function ingestTag(recordId, tagName)
	recordId = recordId:lower()
	tagName = tagName:lower()

	AppliedTags[recordId] = AppliedTags[recordId] or {}
	if not AppliedTags[recordId][tagName] then
		TagRefCounts[tagName] = (TagRefCounts[tagName] or 0) + 1
	end
	AppliedTags[recordId][tagName] = true
	TagList[tagName] = true
end

local function removeTagFromMemory(recordId, tagName)
	recordId = recordId:lower()

	local tagTable = AppliedTags[recordId]
	if not tagTable then return end

	tagName = tagName:lower()
	if not tagTable[tagName] then return end

	tagTable[tagName] = nil
	TagRefCounts[tagName] = TagRefCounts[tagName] - 1
	if TagRefCounts[tagName] <= 0 then
		TagRefCounts[tagName] = nil
		TagList[tagName] = nil
	end
end

---@param object string
---@param tag Tagger.ObjectTag
local function addTagImpl(object, tag)
	local recordId = getRecordId(object)
	local lowerTag = tag:lower()

	AppliedTags[recordId] = AppliedTags[recordId] or {}
	if not AppliedTags[recordId][lowerTag] then
		TagRefCounts[lowerTag] = (TagRefCounts[lowerTag] or 0) + 1
	end
	AppliedTags[recordId][lowerTag] = true
	TagList[lowerTag] = true
end

---@param objectOrId Tagger.Taggable
---@param tag Tagger.ObjectTag
local function removeTagImpl(objectOrId, tag)
	local recordId = getRecordId(objectOrId)

	local tagTable = AppliedTags[recordId]
	if not tagTable then return end

	local lowerTag = tag:lower()
	if not tagTable[lowerTag] then return end

	tagTable[lowerTag] = nil
	TagRefCounts[lowerTag] = TagRefCounts[lowerTag] - 1
	if TagRefCounts[lowerTag] <= 0 then
		TagRefCounts[lowerTag] = nil
		TagList[lowerTag] = nil
	end
end

local loadingComplete = false

---@param object Tagger.Taggable
---@param tag Tagger.TagArg
local function addTagGlobal(object, tag)
	---@cast TagSection openmw.storage.MutableStorageSection
	local tagType = type(tag)
	local id = getRecordId(object)

	if tagType == 'table' then
		for i = 1, #tag do
			addTagImpl(id, tag[i])
		end
	elseif tagType == 'string' then
		addTagImpl(id, tag)
	else
		error('Invalid tag value ' .. tostring(tag) .. ' !')
	end

	if loadingComplete then
		syncToStorage()
	end
end

---@param objectOrId Tagger.Taggable
---@param tagOrList Tagger.TagArg
local function removeTagGlobal(objectOrId, tagOrList)
	---@cast TagSection openmw.storage.MutableStorageSection
	local tagType = type(tagOrList)

	if tagType == 'table' then
		for i = 1, #tagOrList do
			removeTagImpl(objectOrId, tagOrList[i])
		end
	elseif tagType == 'string' then
		removeTagImpl(objectOrId, tagOrList)
	else
		error('Invalid tag value ' .. tostring(tagOrList) .. ' !')
	end

	if loadingComplete then
		syncToStorage()
	end
end

---@param objectOrId Tagger.Taggable
---@param tagOrList Tagger.TagArg
local function addTagLocal(objectOrId, tagOrList)
	local taggedId = getRecordId(objectOrId)

	if type(tagOrList) == 'string' then
		tagOrList = { tagOrList }
	end

	assert(
		type(tagOrList) == 'table' and #tagOrList > 0,
		'Must provide a non-empty string array to addTag event!'
	)

	SendGlobalEvent('TaggerAddTags', { [taggedId] = tagOrList })
end

---@param objectOrId Tagger.Taggable
---@param tagOrList Tagger.TagArg
local function removeTagLocal(objectOrId, tagOrList)
	local taggedId = getRecordId(objectOrId)

	if type(tagOrList) == 'string' then
		tagOrList = { tagOrList }
	end

	assert(
		type(tagOrList) == 'table' and #tagOrList > 0,
		'Must provide a non-empty string array to removeTag event!'
	)

	SendGlobalEvent('TaggerRemoveTags', { [taggedId] = tagOrList })
end

---Called by the global script once all YAML files have been loaded.
---Writes the accumulated tags to storage and unlocks deferred writes.
local function markLoadingComplete()
	---@cast TagSection openmw.storage.MutableStorageSection
	TagSection:set('TagList', TagList)
	TagSection:set('AppliedTags', AppliedTags)
	loadingComplete = true
end

local isGlobal = pcall(require, 'openmw.world')

---@param addTagFunc fun(object: Tagger.Taggable, tag: Tagger.TagArg)
---@param removeTagFunc fun(object: Tagger.Taggable, tag: Tagger.TagArg)
---@return Tagger.Interface
local function Interface(addTagFunc, removeTagFunc)
	return {
		addTag = addTagFunc,
		removeTag = removeTagFunc,
		objectHasTag = function(object, tag)
			local recordId = getRecordId(object)
			local tags = AppliedTags[recordId]

			if not tags then return end

			return tags[tag:lower()]
		end,
		objectTags = function(object)
			local tags = AppliedTags[getRecordId(object)]

			if not tags then return end

			return util.makeReadOnly(tags)
		end,
		tagList = function()
			return util.makeReadOnly(TagList)
		end,
		appliedTags = function()
			return util.makeReadOnly(AppliedTags)
		end,
		ingestTag = ingestTag,
		removeTagFromMemory = removeTagFromMemory,
		_isLoadingComplete = function() return loadingComplete end,
		markLoadingComplete = markLoadingComplete,
		syncToStorage = syncToStorage,
	}
end

if isGlobal then
	syncToStorage = function()
		---@cast TagSection openmw.storage.MutableStorageSection
		TagSection:set('AppliedTags', AppliedTags)
		TagSection:set('TagList', TagList)
	end

	return Interface(addTagGlobal, removeTagGlobal)
else
	return Interface(addTagLocal, removeTagLocal)
end
