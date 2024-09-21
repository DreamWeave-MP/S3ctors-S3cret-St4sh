local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local Aliases = require('scripts.s3.transmog.ui.menualiases')

local SpacerWidth = .166666

local updateContainerCategory = async:callback(function(_, layout)
  local name = layout.props.name

  if name == "Weapon" then
    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
  else
    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
  end

  -- This way allows you to enable or disable item types
  -- But I kinda don't like that? We'll leave the code unmodified, but override the behavior for now
  -- local typeIsActive = itemContainer.userData[layout.userData.recordType]
  -- itemContainer.userData[layout.userData.recordType] = not typeIsActive
  Aliases('inventory container').userData = {[layout.userData.recordType] = true}
  self:sendEvent('updateInventoryContainer')
end)

local function categoryButton(recordType)
  local recordString = common.recordAliases[recordType].name
  local button = common.createButton(recordString)

  button.name = recordString
  button.events.mousePress = updateContainerCategory
  button.userData = { recordType = recordType }

  return button
end

local function categoryButtons()
  local categoryButtonDistance = 0.01
  local containerSize = util.vector2(1, .425)
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Vertical Category Button Container",
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      autoSize = false,
      relativeSize = util.vector2(1 - (SpacerWidth * 2), 1),
    },
    content = ui.content {

      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Center,
          autoSize = false,
          horizontal = true,
          name = "Right Panel: Category Button Horizontal Container 1",
          relativeSize = containerSize,
        },
        content = ui.content {
          categoryButton(types.Armor),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Clothing),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Weapon),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Ingredient),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Potion),
        }
      },

      {
        template = I.MWUI.templates.horizontalLineThick,
        props = {
          relativeSize = util.vector2(.65, 0),
        },
      },

      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Center,
          autoSize = false,
          horizontal = true,
          name = "Right Panel: Category Button Horizontal Container 2",
          relativeSize = containerSize,
        },
        content = ui.content {
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Book),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Lockpick),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Probe),
          { external = { grow = categoryButtonDistance } },
          categoryButton(types.Miscellaneous),
          { external = { grow = categoryButtonDistance } },
        }
      },

    },
  }
end

local headerContent = {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Header",
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      autoSize = false,
      horizontal = true,
    },
    external = {
      stretch = 1,
      grow = 0.1375,
    },
    content = ui.content {
      { external = { grow = SpacerWidth } },

      -- { template = I.MWUI.templates.verticalLineThick },

      categoryButtons(),

      -- { template = I.MWUI.templates.verticalLineThick },

      { external = { grow = SpacerWidth } },
    },
  }

return {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: HeaderBody",
    autoSize = false,
  },
  external = { stretch = 1, grow = .125, },
  content = ui.content {
    headerContent,
    { template = I.MWUI.templates.horizontalLineThick },
  }
}
