---@omw-context menu|player

---H3 UI component primitive for passive Container layouts.
---@module 'scripts.s3.components.container'

local ui = require 'openmw.ui'

---Build a Container layout that wraps its children.
---Allocates fresh layout, props, external, and content wrapper tables.
---The caller owns the layout and any later Element; no element is created here.
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function container(opts)
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
    end
    local layout = {
        type = ui.TYPE.Container,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
    }
    local children = opts.content or opts.children
    if children then
        layout.content = ui.content(children)
    end
    return layout
end

return container
