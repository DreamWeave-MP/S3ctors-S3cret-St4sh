local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

---@class CastableConstructor
---@field barColor util.color
---@field barSize util.vector2
---@field castableIcon string?
---@field castableWidth number
---@field Constants H4NDConstants

---@param constructor CastableConstructor
return function(constructor)
    local Attrs,
    Colors,
    Vectors =
        constructor.Constants.Attrs,
        constructor.Constants.Colors,
        constructor.Constants.Vectors

    return ui.create {
        type = ui.TYPE.Flex,
        name = 'CastableIndicator',
        props = {
            anchor = Vectors.BottomLeft,
            relativePosition = Attrs.Castable(),
            autoSize = false,
            relativeSize = util.vector2(.15, .15),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                template = I.MWUI.templates.borders,
                name = 'CastableIcon',
                props = {
                    resource = ui.texture { path = constructor.castableIcon or 'white' },
                    relativeSize = constructor.Constants.Attrs.IndicatorSize(),
                    visible = true,
                    color = constructor.castableIcon == nil and Colors.Black or nil,
                    alpha = constructor.castableIcon ~= nil and 1.0 or .5,
                }
            },
            {
                name = 'CastChanceContainer',
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = constructor.Constants.Attrs.BarContainer(),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        name = 'CastChanceBackground',
                        props = {
                            resource = ui.texture { path = 'white' },
                            relativeSize = constructor.Constants.Vectors.BottomRight,
                            color = Colors.Black,
                            alpha = 0.5,
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'CastChanceBar',
                        props = {
                            resource = ui.texture { path = 'white' },
                            relativeSize = util.vector2(constructor.castableWidth, 1),
                            color = constructor.barColor,
                        },
                    },
                }
            },
        }
    }
end
