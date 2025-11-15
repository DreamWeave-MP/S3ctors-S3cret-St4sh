local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

---@class CastableConstructor
---@field barColor util.color
---@field barSize util.vector2
---@field castableIcon string?
---@field castableWidth number
---@field handSize util.vector2
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
            position = Attrs.Castable(constructor.handSize),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                template = I.MWUI.templates.borders,
                name = 'CastableIcon',
                props = {
                    resource = ui.texture { path = constructor.castableIcon or 'white' },
                    size = Attrs.SubIcon(constructor.handSize),
                    visible = true,
                    color = constructor.castableIcon == nil and Colors.Black or nil,
                    alpha = constructor.castableIcon ~= nil and 1.0 or .5,
                }
            },
            {
                name = 'CastChanceContainer',
                template = I.MWUI.templates.borders,
                props = {
                    size = constructor.barSize,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        name = 'CastChanceBackground',
                        props = {
                            resource = ui.texture { path = 'white' },
                            size = constructor.barSize,
                            color = Colors.Black,
                            alpha = 0.5,
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'CastChanceBar',
                        props = {
                            resource = ui.texture { path = 'white' },
                            size = util.vector2(constructor.barSize.x * constructor.castableWidth, constructor.barSize.y),
                            color = constructor.barColor,
                        },
                    },
                }
            },
        }
    }
end
