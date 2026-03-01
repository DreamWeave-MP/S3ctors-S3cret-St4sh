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

--- Load all tags from a tag file into memory
---@param tagTable TagTable
local function loadTagData(tagTable)
    for _, tagName in ipairs(tagTable.tags or {}) do
        tagName = tagName:lower()

        if TagList[tagName] then
            TagLog(tagName, 'is already defined! Skipping . . .')
        elseif type(tagName) == 'string' then
            TagList[tagName] = true
        else
            TagLog(tagName, 'is not a valid tag! Skipping . . .')
        end
    end

    for taggedObject, tagList in pairs(tagTable.applied_tags or {}) do
        if type(taggedObject) == 'string' then
            taggedObject = taggedObject:lower()

            if not AppliedTags[taggedObject] then
                AppliedTags[taggedObject] = {}
            end

            for _, tagName in ipairs(tagList) do
                if type(tagName) == 'string' then
                    tagName = tagName:lower()
                    AppliedTags[taggedObject][tagName] = true
                else
                    TagLog(tagName, 'is not a valid tag! Skipping . . .')
                end
            end

        else
            TagLog(taggedObject, 'is not a valid recordId! Skipping . . .')
        end
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

return {
    interfaceName = 'TaggerG',
    interface = require('Scripts.S3.ModTags.interface'),
}
