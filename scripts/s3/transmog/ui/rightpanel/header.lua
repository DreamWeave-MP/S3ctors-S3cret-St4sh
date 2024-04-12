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

  local itemContainer = I.transmogActions.itemContainer
  if name == "Apparel Button" then
    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    itemContainer.content = ui.content(ItemContainer.updateContent("Apparel"))
  elseif name == "Weapons Button" then
    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
    itemContainer.content = ui.content(ItemContainer.updateContent("Weapons"))
  end
  common.resetPortraits()
  types.Actor.setEquipment(self, I.transmogActions.originalInventory)
  I.transmogActions.menu:update()
end)

local function categoryButton(categoryName)
  local button = common.createButton(categoryName)
  button.props.name = categoryName .. " Button"
  button.events.mousePress = updateContainerCategory
  return button
end

local function categoryButtons()
  local ApparelButton = categoryButton("Apparel")
  -- local ArmorButton = categoryButton("Armor")
  -- local ClothingButton = categoryButton("Clothing")
  local WeaponsButton = categoryButton("Weapons")
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Category Button Container",
      size = util.vector2(0, const.WINDOW_HEIGHT * const.HEADER_REL_SIZE),
      arrange = ui.ALIGNMENT.End,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    external = {
      stretch = 1,
    },
    content = ui.content {
      { external = { grow = 1 } },
      ApparelButton,
      -- ArmorButton,
      { external = { grow = 0.5 } },
      -- ClothingButton,
      -- { external = { grow = 0.5 } },
      WeaponsButton,
      { external = { grow = 1 } },
    }
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
