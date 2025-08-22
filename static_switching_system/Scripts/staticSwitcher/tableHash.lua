local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2 ^ 32
    end
    return string.format("%08x", hash)
end

local function sortTableValue(a, b)
    local ta, tb = type(a), type(b)
    if ta == tb then
        return tostring(a) < tostring(b)
    end
    return ta < tb
end

local function tableToHash(t, visited)
    local content = {}
    local keys = {}

    for k in pairs(t) do
        table.insert(keys, k)
    end

    table.sort(keys, sortTableValue)

    for _, key in ipairs(keys) do
        local value = t[key]
        local valueRep
        local valueType = type(value)

        if type(value) == "table" then
            valueRep = tableToHash(value, visited)
        elseif type(value) == "number" then
            valueRep = string.format("num:%.15g", value)
        elseif valueType == 'userdata' then
            if value.__type and value.__type.name then
                valueRep = value.__type.name
            else
                error('Userdata value does not have a type name: ' .. tostring(value))
            end
        else
            valueRep = tostring(value)
        end

        table.insert(content, tostring(key) .. "=" .. valueRep)
    end

    return simpleHash(table.concat(content, ";"))
end

return tableToHash
