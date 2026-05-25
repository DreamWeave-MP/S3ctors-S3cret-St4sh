---@omw-context menu|player

---H3 UI component primitive for passive MWUI box layouts.
---@module 'scripts.s3.components.box'

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build an MWUI boxed container layout.
---Allocates fresh layout, props, external, and content wrapper tables. Uses shared MWUI templates
---read-only; callers own mounting and any later layout mutation.
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function box(opts)
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
        template = opts.template or I.MWUI.templates.box,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
    }
    local children = opts.content or opts.children
    if children then
        layout.content = ui.content(children)
    end
    return layout
end

return box
