---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a simple MWUI text button layout.
---Allocates fresh layout, props, external, padding, text, and content tables. The button is only a
---layout; caller-owned event callbacks must be async-wrapped before use.
---@param opts? {label?: string, name?: string, props?: table, labelProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function button(opts)
    opts = opts or {}
    local labelProps = {}
    for key, value in pairs(opts.labelProps or {}) do
        labelProps[key] = value
    end
    if opts.label ~= nil then
        labelProps.text = opts.label
    end
    local children = opts.content or opts.children or {
        {
            template = I.MWUI.templates.padding,
            content = ui.content({
                {
                    template = I.MWUI.templates.textNormal,
                    props = labelProps,
                },
            }),
        },
    }
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
        content = ui.content(children),
    }
end

return button
