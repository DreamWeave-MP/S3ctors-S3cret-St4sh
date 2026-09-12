---@omw-context menu|player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local clamp = util.clamp
local vector2 = util.vector2

local whiteTexture = ui.texture { path = 'white' }
local fillColor = util.color.rgb(0.65, 0.52, 0.25)
local emptyColor = util.color.rgba(0, 0, 0, 0.35)
local fullSize = vector2(1, 1)

---Build a simple horizontal meter layout.
---Allocates fresh layout, props, external, and content tables. The fill is represented by a child Image
---with relative width; callers may supply engine-supported color/size props.
---@param options? {value?: number, max?: number, name?: string, props?: table, fillProps?: table, emptyProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function meter(options)
    options = options or {}

    local value = options.value or 0
    local maximum = options.max or 1
    local ratio = maximum > 0 and clamp(value / maximum, 0, 1) or 0

    local fillProps = {}
    if options.fillProps then
        for key, propValue in next, options.fillProps do
            fillProps[key] = propValue
        end
    end
    fillProps.color = fillProps.color or fillColor
    fillProps.resource = fillProps.resource or whiteTexture
    fillProps.relativeSize = fillProps.relativeSize or vector2(ratio, 1)

    local emptyProps = {}
    if options.emptyProps then
        for key, propValue in next, options.emptyProps do
            emptyProps[key] = propValue
        end
    end
    emptyProps.color = emptyProps.color or emptyColor
    emptyProps.resource = emptyProps.resource or whiteTexture
    emptyProps.relativeSize = emptyProps.relativeSize or vector2(1 - ratio, 1)

    local props = {}
    if options.props then
        for key, propValue in next, options.props do
            props[key] = propValue
        end
    end

    local external
    if options.external then
        external = {}
        for key, propValue in next, options.external do
            external[key] = propValue
        end
    end

    return {
        template = options.template or I.MWUI.templates.box,
        name = options.name,
        props = props,
        external = external,
        events = options.events,
        userData = options.userData,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    autoSize = false,
                    relativeSize = fullSize,
                },
                content = ui.content {
                    { type = ui.TYPE.Image, props = fillProps },
                    { type = ui.TYPE.Image, props = emptyProps },
                },
            },
        },
    }
end

return meter
