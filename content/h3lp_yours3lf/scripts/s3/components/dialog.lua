---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a Window-style dialog layout.
---Allocates fresh layout, props, external, and content tables. No layer is set and no window is
---created; caller owns mounting, visibility, callbacks, and destruction.
---@param opts? {title?: string, name?: string, props?: table, titleProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function dialog(opts)
    opts = opts or {}
    local body = opts.content or opts.children or {}
    local content = {}
    if opts.title ~= nil then
        local titleProps = {}
        for key, value in pairs(opts.titleProps or {}) do
            titleProps[key] = value
        end
        titleProps.text = opts.title
        content[#content + 1] = { template = I.MWUI.templates.textHeader, props = titleProps }
        content[#content + 1] = { template = I.MWUI.templates.interval }
    end
    content[#content + 1] = {
        template = I.MWUI.templates.padding,
        content = ui.content(body),
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
        type = ui.TYPE.Window,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
        content = ui.content(content),
    }
end

return dialog
