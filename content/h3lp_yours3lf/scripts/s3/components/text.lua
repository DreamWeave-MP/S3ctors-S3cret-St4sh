---@omw-context menu|player

local ui = require 'openmw.ui'

---Build a Text layout.
---Allocates fresh layout, props, and external tables. The returned layout is passive and must
---be mounted and updated by its owner if its text changes later.
---@param opts? {text?: string, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function text(opts)
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
        type = ui.TYPE.Text,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
    }
end

return text
