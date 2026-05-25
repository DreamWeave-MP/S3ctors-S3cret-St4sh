---@omw-context menu|player

local ui = require 'openmw.ui'

---Build a vertical list Flex layout.
---Allocates fresh layout, props, external, and content tables. Items are passed through as
---child layouts; callers own item identity, events, and later Element updates.
---@param opts? {items?: openmw.ui.Layout[], name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function list(opts)
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
    local children = opts.content or opts.children or opts.items or {}
    return {
        type = ui.TYPE.Flex,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
        content = ui.content(children),
    }
end

return list
