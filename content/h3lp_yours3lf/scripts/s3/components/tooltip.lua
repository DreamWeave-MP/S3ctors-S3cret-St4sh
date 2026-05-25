---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a boxed tooltip layout.
---Allocates fresh layout, props, external, and content tables. This primitive does not position, show,
---hide, create, or destroy anything; caller owns tooltip lifecycle.
---@param opts? {text?: string, name?: string, props?: table, textProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function tooltip(opts)
    opts = opts or {}
    local textProps = {}
    for key, value in pairs(opts.textProps or {}) do
        textProps[key] = value
    end
    if opts.text ~= nil then
        textProps.text = opts.text
    end
    local children = opts.content or opts.children or {
        {
            template = I.MWUI.templates.textParagraph,
            props = textProps,
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
        template = opts.template or I.MWUI.templates.boxTransparent,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        content = ui.content({
            {
                template = I.MWUI.templates.padding,
                content = ui.content(children),
            },
        }),
    }
end

return tooltip
