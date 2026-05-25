---@omw-context menu|player

---H3 UI component primitive for passive vertical Flex layouts.
---@module 'scripts.s3.components.column'

local ui = require 'openmw.ui'

---Build a vertical Flex layout.
---Allocates fresh layout, props, external, and content tables. `opts.props` is shallow-copied
---before `horizontal = false` is applied, so callers may reuse their input table safely.
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function column(opts)
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
    props.horizontal = false
    local layout = {
        type = ui.TYPE.Flex,
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

return column
