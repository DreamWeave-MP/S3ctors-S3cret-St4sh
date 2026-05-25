---@omw-context menu|player

local ui = require 'openmw.ui'

---Build an empty Widget spacer layout.
---Allocates fresh layout, props, and external tables. The
---spacer has no lifetime beyond the returned layout until a caller mounts it.
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template, grow?: number, stretch?: number}
---@return openmw.ui.Layout
local function spacer(opts)
    opts = opts or {}
    local props = {}
    for key, value in pairs(opts.props or {}) do
        props[key] = value
    end
    local external = nil
    if opts.external then
        external = {}
        for key, value in pairs(opts.external) do
            external[key] = value
        end
    elseif opts.grow or opts.stretch then
        external = {
            grow = opts.grow,
            stretch = opts.stretch,
        }
    end
    return {
        type = ui.TYPE.Widget,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
    }
end

return spacer
