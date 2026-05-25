---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build an MWUI button with an icon and optional label.
---Allocates fresh layout, props, external, and content tables. Pass a prebuilt texture `resource`; this
---primitive does not register textures or own element lifetime.
---@param opts? {resource?: openmw.ui.TextureResource, label?: string, name?: string, props?: table, iconProps?: table, labelProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function iconButton(opts)
    opts = opts or {}
    local iconProps = {}
    for key, value in pairs(opts.iconProps or {}) do
        iconProps[key] = value
    end
    if opts.resource ~= nil then
        iconProps.resource = opts.resource
    end
    local rowContent = {
        {
            type = ui.TYPE.Image,
            props = iconProps,
        },
    }
    if opts.label ~= nil then
        local labelProps = {}
        for key, value in pairs(opts.labelProps or {}) do
            labelProps[key] = value
        end
        labelProps.text = opts.label
        rowContent[#rowContent + 1] = { template = I.MWUI.templates.interval }
        rowContent[#rowContent + 1] = {
            template = I.MWUI.templates.textNormal,
            props = labelProps,
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
        content = ui.content({
            {
                template = I.MWUI.templates.padding,
                content = ui.content({
                    {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
                        content = ui.content(rowContent),
                    },
                }),
            },
        }),
    }
end

return iconButton
