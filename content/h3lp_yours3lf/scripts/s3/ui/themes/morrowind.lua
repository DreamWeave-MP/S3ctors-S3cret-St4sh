---@omw-context menu|player

local constants = require 'scripts.omw.mwui.constants'

return {
  name = 'morrowind',
  tokens = {
    spacing = {
      xs = 2,
      sm = 4,
      md = constants.padding,
      lg = constants.padding * 2,
      xl = constants.padding * 3,
    },
    color = {
      text = constants.normalColor,
      header = constants.headerColor,
    },
    textSize = {
      normal = constants.textNormalSize,
      header = constants.textHeaderSize,
    },
    border = {
      thick = constants.thickBorder,
    },
  },
  rules = {},
}
