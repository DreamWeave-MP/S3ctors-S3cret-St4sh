---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a bordered item slot layout with optional icon and count label.
---Allocates fresh layout, props, external, and content tables. Pass a prebuilt texture `resource`; this
---primitive does not register textures, query game state, or own any Element.
---@param opts? {resource?: openmw.ui.TextureResource, count?: string|number, name?: string, props?: table, iconProps?: table, countProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function itemSlot(opts)
    opts = opts or {}
    local iconProps = {}
    for key, value in pairs(opts.iconProps or {}) do
        iconProps[key] = value
    end
    if opts.resource ~= nil then
        iconProps.resource = opts.resource
    end
    local content = {
        {
            type = ui.TYPE.Image,
            props = iconProps,
        },
    }
    if opts.count ~= nil then
        local countProps = {}
        for key, value in pairs(opts.countProps or {}) do
            countProps[key] = value
        end
        countProps.text = tostring(opts.count)
        content[#content + 1] = {
            template = I.MWUI.templates.textNormal,
            props = countProps,
        }
    end
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
    return {
        template = opts.template or I.MWUI.templates.box,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        content = ui.content(content),
    }
end

return itemSlot
