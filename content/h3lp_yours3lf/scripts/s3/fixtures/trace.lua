---@omw-context none

---Shared trace formatter for opt-in H3lp Yours3lf OpenMW-Lua fixture probes.
---This module has no OpenMW imports, performs no registration, and has no side
---effects unless `emit` is called by an explicitly attached fixture script.
---Trace lines use `S3TRACE|fixture=...|ctx=...|seq=...|event=...|phase=...`
---followed by remaining fields sorted by key for compact log comparison.

local PRIORITY = { 'fixture', 'ctx', 'seq', 'event', 'phase' }

local function valueToString(value)
    if value == nil then
        return 'nil'
    end
    return tostring(value):gsub('[|\n\r]', ' ')
end

local function hasPriority(key)
    for i = 1, #PRIORITY do
        if PRIORITY[i] == key then
            return true
        end
    end
    return false
end

---Format fixture trace fields into one compact, stable line.
---@param fields table<string, any>
---@return string
local function format(fields)
    local out = { 'S3TRACE' }

    for i = 1, #PRIORITY do
        local key = PRIORITY[i]
        if fields[key] ~= nil then
            out[#out + 1] = key .. '=' .. valueToString(fields[key])
        end
    end

    local extras = {}
    for key in pairs(fields) do
        if not hasPriority(key) then
            extras[#extras + 1] = key
        end
    end
    table.sort(extras)

    for i = 1, #extras do
        local key = extras[i]
        out[#out + 1] = key .. '=' .. valueToString(fields[key])
    end

    return table.concat(out, '|')
end

---Print one formatted trace line.
---@param fields table<string, any>
---@return string line The exact line printed.
local function emit(fields)
    local line = format(fields)
    print(line)
    return line
end

return {
    format = format,
    emit = emit,
}
