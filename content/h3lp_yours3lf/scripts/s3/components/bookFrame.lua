---@omw-context menu|player

local ui = require 'openmw.ui'
local I = require 'openmw.interfaces'

---Build a book-like framed content layout.
---Allocates fresh layout, props, external, and content tables and uses MWUI borders read-only. It is a
---passive layout primitive; caller owns mounting and later updates.
---@param opts? {title?: string, name?: string, props?: table, titleProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.Layout[], children?: openmw.ui.Content|openmw.ui.Layout[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function bookFrame(opts)
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
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = { horizontal = false },
                content = ui.content(body),
            },
        }),
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
        template = opts.template or I.MWUI.templates.boxSolid,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        content = ui.content({
            {
                type = ui.TYPE.Flex,
                props = { horizontal = false },
                content = ui.content(content),
            },
        }),
    }
end

return bookFrame
