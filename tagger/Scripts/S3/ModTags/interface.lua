local async = require 'openmw.async'
local storage = require('openmw.storage')

local TagSection = storage.globalSection('TaggerStorage')

local AppliedTags = TagSection:get('AppliedTags')
local TagList = TagSection:get('TagList')

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

return {
    tagList = function()
        return TagList
    end,
    appliedTags = function()
        return AppliedTags
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
}
