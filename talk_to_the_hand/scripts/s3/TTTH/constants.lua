local util = require 'openmw.util'

---@alias ScaleFunction fun(size: util.vector2): util.vector2

---@class H4NDConstants
---@field Attrs table<string, ScaleFunction>
---@field Colors table<string, util.color>
---@field Vectors table<string, util.vector2|table<string, util.vector2>>
return {
    --- Size functions for hand images are aspect ratios
    Attrs = {
        ---@param handSize util.vector2
        ---@return util.vector2
        Castable = function(handSize)
            return util.vector2(handSize.x * .7775, handSize.y * .235)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2
        ChanceBar = function(handSize)
            return util.vector2(handSize.x * .2, handSize.x * 0.02)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2
        EffectBar = function(handSize)
            return util.vector2(handSize.x, handSize.y * 0.1)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2, util.vector2
        Middle = function(handSize)
            local width = handSize.x * .55

            return util.vector2(width, width * 1.37), util.vector2(handSize.x * .255, handSize.y * 0.015)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2, util.vector2
        Pinky = function(handSize)
            local width = handSize.x * .275

            return util.vector2(width, width * 2.0), util.vector2(handSize.x * .64, handSize.y * .235)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2
        SubIcon = function(handSize)
            return util.vector2(handSize.x * .2, handSize.x * .2)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2, util.vector2
        Thumb = function(handSize)
            local width = handSize.x * .625

            return util.vector2(width, width * 0.974820143885), util.vector2(handSize.x * .075, handSize.y * .35)
        end,
        ---@param handSize util.vector2
        ---@return util.vector2
        Weapon = function(handSize)
            return util.vector2(handSize.x * .025, handSize.y * .15)
        end,
    },
    Colors = {
        Black = util.color.hex('000000'),
    },
    Vectors = {
        BottomLeft = util.vector2(0, 1),
        BottomRight = util.vector2(1, 1),
        Center = util.vector2(.5, .5),
        LeftCenter = util.vector2(0, .5),
        Zero = util.vector2(0, 0),
        Tiles = {
            Pinky = util.vector2(128, 256),
            Middle = util.vector2(256, 512),
            Thumb = util.vector2(278, 271),
            Compass = util.vector2(64, 64),
            MoonAndStarAdjust = util.vector2(0, .015625)
        },
        TopRight = util.vector2(1, 0),

    }
}
