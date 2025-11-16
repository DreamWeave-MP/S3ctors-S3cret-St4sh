local util = require 'openmw.util'

---@alias ScaleFunction fun(): util.vector2

---@class H4NDConstants
---@field Attrs table<string, ScaleFunction>
---@field Colors table<string, util.color>
---@field Vectors table<string, util.vector2|table<string, util.vector2>>
return {
    --- Size functions for hand images are aspect ratios
    Attrs = {
        ---@return util.vector2
        BarContainer = function()
            return util.vector2(1, .15)
        end,
        ---@return util.vector2
        Castable = function()
            return util.vector2(.7775, .15)
        end,
        ---@return util.vector2
        ChanceBar = function()
            return util.vector2(.2, 0.03)
        end,
        ---@return util.vector2
        EffectBar = function()
            return util.vector2(1, 0.15)
        end,
        IndicatorSize = function()
            return util.vector2(1, .85)
        end,
        ---@return util.vector2, util.vector2
        Middle = function()
            local width = .55

            return util.vector2(width, width * 1.15), util.vector2(.24, .625)
        end,
        ---@return util.vector2, util.vector2
        Pinky = function()
            local width = .275
            return util.vector2(width, width * 2.0), util.vector2(.63, .69)
        end,
        ---@return util.vector2, util.vector2
        Thumb = function()
            local width = .6
            return util.vector2(width, width * 0.974820143885), util.vector2(.0825, .85)
        end,
        ---@return util.vector2
        Weapon = function()
            return util.vector2(.125, .275)
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
