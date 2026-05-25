---@omw-context menu|player

local ui = require 'openmw.ui'

---Build an Image layout.
---Allocates fresh layout, props, and external tables. Pass a prebuilt `resource` or set
---`props.resource`; this primitive intentionally does not call `ui.texture`.
---@param opts? {resource?: openmw.ui.TextureResource, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function image(opts)
    opts = opts or {}
    local props = {}
    for key, value in pairs(opts.props or {}) do
        props[key] = value
    end
    if opts.resource ~= nil then
        props.resource = opts.resource
    end
    local external = nil
    if opts.external then
        external = {}
        for key, value in pairs(opts.external) do
            external[key] = value
        end
    end
    return {
        type = ui.TYPE.Image,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
    }
end

return image
