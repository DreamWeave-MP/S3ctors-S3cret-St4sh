local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')

local function greeting()
  return {
    type = ui.TYPE.Text,
    props = {
      text = "Use your glamour prisms!",
      textColor = const.TEXT_COLOR,
      textSize = const.HEADER_FONT_SIZE,
    }
  }
end

local updateContainerCategory = async:callback(function(_, layout)
  local name = layout.props.name

  self:sendEvent('itemContainerRequest', 'CategoryButtonItemContainer')

  local itemContainer = I.transmogActions.menus.itemContainer
  if name == "Weapon" then
    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
  else
    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
  end
  local typeIsActive = itemContainer.userData[layout.userData.recordType]
  itemContainer.userData[layout.userData.recordType] = not typeIsActive
  itemContainer.content = ui.content(ItemContainer.updateContent(itemContainer.userData))
  types.Actor.setEquipment(self, I.transmogActions.menus.originalInventory)
  common.mainMenu():update()
end)

local function categoryButton(recordType)
  local recordString = common.recordAliases[recordType].name
  local button = common.createButton(recordString)
  button.props.name =  recordString
  button.events.mousePress = updateContainerCategory
  button.userData = { recordType = recordType }
  return button
end

local function categoryButtons()
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Vertical Category Button Container",
      size = util.vector2(0, const.WINDOW_HEIGHT * const.HEADER_REL_SIZE),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
    },
    external = {
      stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Right Panel: Category Button Horizontal Container 1",
          size = util.vector2(0, (const.WINDOW_HEIGHT * const.HEADER_REL_SIZE) / 2),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        external = {
          stretch = 1,
        },
        content = ui.content {
          { external = { grow = 1 } },
          categoryButton(types.Armor),
          -- { external = { grow = 0.5 } },
          categoryButton(types.Clothing),
          -- { external = { grow = 0.5 } },
          categoryButton(types.Weapon),
          -- { external = { grow = 1 } },
          categoryButton(types.Ingredient),
          -- { external = { grow = 1 } },
          categoryButton(types.Potion),
          { external = { grow = 1 } },
        }
      },
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Right Panel: Category Button Horizontal Container 1",
          size = util.vector2(0, (const.WINDOW_HEIGHT * const.HEADER_REL_SIZE) / 2),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        external = {
          stretch = 1,
        },
        content = ui.content {
          { external = { grow = 1 } },
          categoryButton(types.Book),
          -- { external = { grow = 1 } },
          categoryButton(types.Lockpick),
          -- { external = { grow = 1 } },
          categoryButton(types.Probe),
          -- { external = { grow = 1 } },
          categoryButton(types.Miscellaneous),
          { external = { grow = 1 } }
        }
      },
    },
  }
end

return {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: Header",
    arrange = ui.ALIGNMENT.Center,
    size = util.vector2(const.RIGHT_PANE_WIDTH, 0),
  },
  external = {
    stretch = 1,
  },
  content = ui.content {
    greeting(),
    categoryButtons(),
  }
}
