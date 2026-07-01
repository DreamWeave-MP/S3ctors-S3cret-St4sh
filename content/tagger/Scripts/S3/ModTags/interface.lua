---@omw-context global | local

local async = require 'openmw.async'
local storage = require 'openmw.storage'
local util = require 'openmw.util'

local SendGlobalEvent = require 'openmw.core'.sendGlobalEvent

local TagSection = storage.globalSection 'TaggerStorage'

local AppliedTags = TagSection:get 'AppliedTags'
local TagList = TagSection:get 'TagList'

local assert, error, pcall, require, type = assert, error, pcall, require, type

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

local function getRecordId(object)
	local objectType = type(object)

	if objectType == 'string' then
		return object:lower()
	elseif objectType == 'userdata' and validObjectTypes[object.__type.name] then
		return object.recordId
	elseif objectType == 'userdata' and validCellTypes[object.__type.name] then
		return object.id
	else
		local errorTypeName = object.__type and object.__type.name or objectType
		error('Invalid object type: ' .. objectType .. ' ' .. errorTypeName)
	end
end

local function validateArguments(object, tag, isInstance)
	assert(object ~= nil, "An object must be provided to check its tags!")

	assert(tag ~= nil and type(tag) == 'string', "A tag as a string must be provided to check an object's tags!")

	if isInstance then
		assert(type(object) == 'userdata' and validObjectTypes[object.__type.name],
			'Object argument must be a valid gameObject!')
	end
end

---@param object string|openmw.Object
---@param tag string
local function addTagImpl(object, tag)
	local recordId = getRecordId(object)
	local lowerTag = tag:lower()

	AppliedTags[recordId] = AppliedTags[recordId] or {}
	AppliedTags[recordId][lowerTag] = true
end

---@param objectOrId string|openmw.Object
---@param tag string
local function removeTagImpl(objectOrId, tag)
	local recordId = getRecordId(objectOrId)
	local lowerTag = tag:lower()

	if not AppliedTags[recordId] then return end

	AppliedTags[recordId][lowerTag] = nil
end

local function addTagGlobal(object, tag)
	---@cast TagSection openmw.storage.MutableStorageSection
	validateArguments(object, tag, true)

	local tagType = type(tag)

	if tagType == 'table' then
		for i = 1, #tag do
			addTagImpl(object, tag[i])
		end
	elseif tagType == 'string' then
		addTagImpl(object, tag)
	else
		error('Invalid tag value ' .. tag .. ' !')
	end

	TagSection:set('AppliedTags', AppliedTags)
end

---@param objectOrId openmw.Object|string
---@param tagOrList string|string[]
local function removeTagGlobal(objectOrId, tagOrList)
	---@cast TagSection openmw.storage.MutableStorageSection
	validateArguments(objectOrId, tagOrList, true)

	local tagType = type(objectOrId)

	if tagType == 'table' then
		for i = 1, #objectOrId do
			removeTagImpl(objectOrId, objectOrId[i])
		end
	elseif tagType == 'string' then
		removeTagImpl(objectOrId, objectOrId)
	else
		error('Invalid tag value ' .. objectOrId .. ' !')
	end

	TagSection:set('AppliedTags', AppliedTags)
end

---@param objectOrId openmw.Object|string
---@param tagOrList string|string[]
local function addTagLocal(objectOrId, tagOrList)
	local taggedId = type(objectOrId) == 'userdata' and objectOrId.recordId or objectOrId

	if type(tagOrList) ~= 'string' then
		assert(
			tagOrList[1],
			'Must provide either string or string array to addTag event!'
		)
	else
		tagOrList = { tagOrList, }
	end

	SendGlobalEvent('TaggerAddTags', { [taggedId] = tagOrList })
end

---@param objectOrId openmw.Object|string
---@param tagOrList string|string[]
local function removeTagLocal(objectOrId, tagOrList)
	local taggedId = type(objectOrId) == 'userdata' and objectOrId.recordId or objectOrId

	if type(tagOrList) ~= 'string' then
		assert(
			tagOrList[1],
			'Must provide either string or string array to addTag event!'
		)
	else
		tagOrList = { tagOrList, }
	end

	SendGlobalEvent('TaggerAddTags', { [taggedId] = tagOrList })
end

local isGlobal = pcall(require, 'openmw.world')

local function Interface(addTagFunc, removeTagFunc)
	return {
		addTag = addTagFunc,
		tagList = function()
			if isGlobal then return TagList else return util.makeReadOnly(TagList) end
		end,
		appliedTags = function()
			if isGlobal then return AppliedTags else return util.makeReadOnly(AppliedTags) end
		end,
		objectHasTag = function(object, tag)
			validateArguments(object, tag)

			local recordId = getRecordId(object)

			return (AppliedTags[recordId] and AppliedTags[recordId][tag:lower()]) or false
		end,
		objectTags = function(object)
			assert(object ~= nil, "An object must be provided to get its tags!")

			return AppliedTags[getRecordId(object)] or {}
		end,
		removeTag = removeTagFunc,
	}
end

if isGlobal then
	return Interface(addTagGlobal, removeTagGlobal)
else
	return Interface(addTagLocal, removeTagLocal)
end
