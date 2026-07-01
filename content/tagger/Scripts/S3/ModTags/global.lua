---@omw-context global

local markup = require 'openmw.markup'
local storage = require 'openmw.storage'
local vfs = require 'openmw.vfs'

local TagSection = storage.globalSection 'TaggerStorage'

---@diagnostic disable-next-line: param-type-mismatch
TagSection:setLifeTime(storage.LIFE_TIME.GameSession)

local CoCreate, CoStatus, CoResume, CoYield, pairs, print, type =
    coroutine.create, coroutine.resume, coroutine.status, coroutine.yield, pairs, print, type

---@alias ObjectTag string Identifying tag applied to any gameObject or record

---@alias ObjectTagList table<ObjectTag, boolean>

---@alias AppliedTags table<string, ObjectTagList>

---@class TagTable
---@field tags string[] A list of all tags that can be applied to a record or gameObject
---@field applied_tags AppliedTags A map of recordIds to their tags

local LogPrefix = ' [ TAGGER ]:'
local function TagLog(...)
    print(LogPrefix, ...)
end

---Process a single item entry for a given tag, adding it to the inverted index.
---@param itemId string
---@param tagName string
---@param InProgressAppliedTags AppliedTags
local function applyItemTag(itemId, tagName, InProgressAppliedTags)
    if type(itemId) ~= 'string' then
        return TagLog(itemId, 'in', tagName, 'is not a valid recordId! Skipping . . .')
    end
    itemId = itemId:lower()
    InProgressAppliedTags[itemId] = InProgressAppliedTags[itemId] or {}
    InProgressAppliedTags[itemId][tagName] = true
end

---Process a single tag and its item list from a YAML table.
---@param tagName string
---@param itemList string[]
---@param InProgressAppliedTags AppliedTags
---@param InProgressTagList ObjectTagList
local function processTag(tagName, itemList, InProgressAppliedTags, InProgressTagList)
    if type(tagName) ~= 'string' then
        return TagLog(tagName, 'is not a valid tag name! Skipping . . .')
    end
    if type(itemList) ~= 'table' then
        return TagLog(tagName, 'has a non-table item list. Skipping . . .')
    end

    tagName = tagName:lower()
    InProgressTagList[tagName] = true

    for i = 1, #itemList do
        applyItemTag(itemList[i], tagName, InProgressAppliedTags)
    end
end

--- Load all tags from a tag file into memory.
--- New flat format: { TagName = { recordId, recordId, ... }, ... }
--- Tags are derived from the top-level keys; the inverted index (item → tags)
--- is built here from the forward lists.
---@param tagTable table<string, string[]>
---@param InProgressAppliedTags AppliedTags
---@param InProgressTagList ObjectTagList
local function loadTagData(tagTable, InProgressAppliedTags, InProgressTagList)
    for tagName, itemList in pairs(tagTable) do
        processTag(tagName, itemList, InProgressAppliedTags, InProgressTagList)
    end
end

---@return thread
local function createTagLoaderCoroutine()
    return CoCreate(function()
        --- A list of all tags that can be applied to a gameObject or record
        ---@type ObjectTagList
        local InProgressTagList = {}

        --- Main table storing a map of recordIds to their tags
        ---@type AppliedTags
        local InProgressAppliedTags = {}

        local fileList = {}
        for tagFile in vfs.pathsWithPrefix("ModTags/") do
            fileList[#fileList + 1] = tagFile
        end

        if #fileList == 0 then
            return TagLog('No tag files found in ModTags/')
        end

        TagLog('Staggered loading of', #fileList, 'tag files . . .')

        for i = 1, #fileList do
            local tagFile = fileList[i]
            local tagTable = markup.loadYaml(tagFile)

            if tagTable then
                loadTagData(tagTable, InProgressAppliedTags, InProgressTagList)
            else
                TagLog(tagFile, 'is not a valid YAML file! Skipping . . .')
            end

            if i < #fileList then
                CoYield()
            end
        end

        TagSection:set('TagList', InProgressTagList)
        TagSection:set('AppliedTags', InProgressAppliedTags)


        TagLog('Tag loading complete.')
    end)
end

local loaderCo = createTagLoaderCoroutine()

local onUpdate
local function noop() end

local function resumeLoader()
    if CoStatus(loaderCo) == 'dead' then onUpdate = noop end

    local ok, err = CoResume(loaderCo)

    if not ok then TagLog('Coroutine error:', err) end

    if CoStatus(loaderCo) == 'dead' then onUpdate = noop end
end

onUpdate = resumeLoader

local TaggerInterface = require 'Scripts.S3.ModTags.interface'

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

---@param eventData table<string, string[]> flat map of tagged objects to tag lists
local function onRemoveTags(eventData)
    local applied = TagSection:get('AppliedTags')

    for taggedObject, tagList in pairs(eventData) do
        local taggedId = taggedObject:lower()

        applied[taggedId] = applied[taggedId] or {}
        local tagTable = applied[taggedId]

        for tagIdx = 1, #tagList do
            local tag = tagList[tagIdx]:lower()
            tagTable[tag] = nil
        end
    end

    TagSection:set('AppliedTags', applied)
end

return {
    interfaceName = 'TaggerG',
    interface = TaggerInterface,
    engineHandlers = {
        onUpdate = function()
            onUpdate()
        end,
    },
    eventHandlers = {
        TaggerAddTags = onAddTags,
        TaggerRemoveTags = onRemoveTags,
    },
}
