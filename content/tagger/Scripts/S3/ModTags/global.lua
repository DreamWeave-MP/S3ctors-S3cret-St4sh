local markup = require('openmw.markup')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local TagSection = storage.globalSection('TaggerStorage')
TagSection:setLifeTime(storage.LIFE_TIME.GameSession)

---@alias ObjectTag string Identifying tag applied to any gameObject or record

---@alias ObjectTagList table<ObjectTag, boolean>

---@alias AppliedTags table<string, ObjectTagList>

---@class TagTable
---@field tags string[] A list of all tags that can be applied to a record or gameObject
---@field applied_tags AppliedTags A map of recordIds to their tags

--- A list of all tags that can be applied to a gameObject or record
---@type ObjectTagList
local TagList = {}

--- Main table storing a map of recordIds to their tags
---@type AppliedTags
local AppliedTags = {}

local LogPrefix = ' [ TAGGER ]:'
local function TagLog(...)
    print(LogPrefix, ...)
end

---Process a single item entry for a given tag, adding it to the inverted index.
---@param itemId string
---@param tagName string
local function applyItemTag(itemId, tagName)
    if type(itemId) ~= 'string' then
        return TagLog(itemId, 'in', tagName, 'is not a valid recordId! Skipping . . .')
    end
    itemId = itemId:lower()
    AppliedTags[itemId] = AppliedTags[itemId] or {}
    AppliedTags[itemId][tagName] = true
end

---Process a single tag and its item list from a YAML table.
---@param tagName string
---@param itemList string[]
local function processTag(tagName, itemList)
    if type(tagName) ~= 'string' then
        return TagLog(tagName, 'is not a valid tag name! Skipping . . .')
    end
    if type(itemList) ~= 'table' then
        return TagLog(tagName, 'has a non-table item list. Skipping . . .')
    end

    tagName = tagName:lower()
    TagList[tagName] = true

    for i = 1, #itemList do
        applyItemTag(itemList[i], tagName)
    end
end

--- Load all tags from a tag file into memory.
--- New flat format: { TagName = { recordId, recordId, ... }, ... }
--- Tags are derived from the top-level keys; the inverted index (item → tags)
--- is built here from the forward lists.
---@param tagTable table<string, string[]>
local function loadTagData(tagTable)
    for tagName, itemList in pairs(tagTable) do
        processTag(tagName, itemList)
    end
end

local function loadTagFiles()
    TagLog('Loading tag files . . .')

    for tagFile in vfs.pathsWithPrefix("ModTags/") do
        TagLog('Loading: ', tagFile)
        local tagTable = markup.loadYaml(tagFile)

        if not tagTable then
            TagLog(tagFile, 'is not a valid YAML file! Skipping . . .')
        else
            loadTagData(tagTable)
        end
    end

    TagSection:set('TagList', TagList)
    TagSection:set('AppliedTags', AppliedTags)
  
    TagList = {}
    AppliedTags = {}

end

loadTagFiles()

local TaggerInterface = require('Scripts.S3.ModTags.interface')

---@param eventData table<string, string[]> flat map of tagged objects to tag lists
local function onAddTags(eventData)
	local applied = TagSection:get('AppliedTags')

	for taggedObject, tagList in pairs(eventData) do
		local taggedId = taggedObject:lower()

		applied[taggedId] = applied[taggedId] or {}
		local tagTable = applied[taggedId]

		for tagIdx = 1, #tagList do
			local tag = tagList[tagIdx]:lower()
			tagTable[tag] = true
		end
	end

	TagSection:set('AppliedTags', applied)
end

return {
	interfaceName = 'TaggerG',
	interface = TaggerInterface,
	eventHandlers = {
		TaggerAddTags = onAddTags,
	},
}
