---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a TextEdit layout using `I.MWUI.templates.textEditLine` by default.
---Allocates fresh layout, props, and external tables. Event callbacks, if supplied, are passed
---through unchanged; callers must wrap OpenMW UI callbacks with `async:callback`.
---@param opts? {text?: string, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function textInput(opts)
    opts = opts or {}
    local props = {}
    for key, value in pairs(opts.props or {}) do
        props[key] = value
    end
    if opts.text ~= nil then
        props.text = opts.text
    end
    local external = nil
    if opts.external then
        external = {}
        for key, value in pairs(opts.external) do
            external[key] = value
        end
    end
    return {
        type = ui.TYPE.TextEdit,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template or I.MWUI.templates.textEditLine,
    }
end

return textInput
