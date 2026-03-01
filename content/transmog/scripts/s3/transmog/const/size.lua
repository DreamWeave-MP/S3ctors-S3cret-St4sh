local ui = require('openmw.ui')
local util = require('openmw.util')

return {
    REL_HEIGHT = 0.5,
    WINDOW_HEIGHT = ui.screenSize().y * 0.5,
    LEFT_PANE_WIDTH = ui.screenSize().x * 0.1,
    RIGHT_PANE_WIDTH = ui.screenSize().x * 0.35,
    RPANEL = {
      HEADER = util.vector2(1, 0.1),
      BODY = util.vector2(0.75, 0.85),
      CATEGORY_BUTTON_CONTAINER = util.vector2(0.25, 0.85),
      CATEGORY_BUTTON_CONTAINER_ROW = util.vector2(1, 0.5),
      CATEGORY_BUTTON = {},
      INVENTORY = util.vector2(1, 1),
      INVENTORY_ROW = util.vector2(0.75, 1),
      INVENTORY_PORTRAIT = util.vector2(1, 1),
      FOOTER = {},
    },
    LPANEL = {
      TOTAL = {},
      UPGRADE_PORTRAIT = util.vector2(0.7, 0.6),
      UPGRADE_PORTRAIT_BOX = util.vector2(1, 1),
      UPGRADE_ITEM_SIZE = util.vector2(0.75, 0.75),
      MOG_BUTTON = {},
    },
    CONFIRM = {
      TOTAL = {},
      TEXT_EDIT = {},
      BUTTON = {},
    },
  }
