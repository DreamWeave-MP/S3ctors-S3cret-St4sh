---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local I = require 'openmw.interfaces'

---Build a simple horizontal meter layout.
---Allocates fresh layout, props, external, and content tables. The fill is represented by a child Widget
---with relative width; callers may supply engine-supported color/size props.
---@param opts? {value?: number, max?: number, name?: string, props?: table, fillProps?: table, emptyProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function meter(opts)
    opts = opts or {}
    local value = opts.value or 0
    local max = opts.max or 1
    local ratio = 0
    if max > 0 then
        ratio = util.clamp(value / max, 0, 1)
    end
    local fillProps = {}
    for key, propValue in pairs(opts.fillProps or {}) do
        fillProps[key] = propValue
    end
    fillProps.relativeSize = fillProps.relativeSize or util.vector2(ratio, 1)
    local emptyProps = {}
    for key, propValue in pairs(opts.emptyProps or {}) do
        emptyProps[key] = propValue
    end
    emptyProps.relativeSize = emptyProps.relativeSize or util.vector2(1 - ratio, 1)
    local props = {}
    for key, propValue in pairs(opts.props or {}) do
        props[key] = propValue
    end
    local external = nil
    if opts.external then
        external = {}
        for key, propValue in pairs(opts.external) do
            external[key] = propValue
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
                type = ui.TYPE.Flex,
                props = { horizontal = true, relativeSize = util.vector2(1, 1) },
                content = ui.content({
                    { type = ui.TYPE.Widget, props = fillProps, external = { grow = ratio } },
                    { type = ui.TYPE.Widget, props = emptyProps, external = { grow = 1 - ratio } },
                }),
            },
        }),
    }
end

return meter
