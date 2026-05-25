---@omw-context menu|player

---H3 UI component primitive for passive base Widget layouts.
---@module 'scripts.s3.components.widget'

local ui = require 'openmw.ui'

---Build a base Widget layout.
---Allocates fresh layout, props, and external tables. If `content` or `children` is provided,
---it is wrapped in a fresh `openmw.ui.Content`. The caller owns the returned layout;
---this module does not call `ui.create`, mutate layers, register anything, or persist state.
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function widget(opts)
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
        type = ui.TYPE.Widget,
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

return widget
