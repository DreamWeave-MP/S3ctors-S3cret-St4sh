local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local sizes = require('scripts.s3.transmog.const.size')
local Aliases = require('scripts.s3.transmog.ui.menualiases')

local function greeting()
  local box = {
    props = {
      relativeSize = util.vector2(1, 1.0),
      -- relativePosition = util.vector2(0, 0),
    },
    external = {
      grow = 1,
      stretch = 1,
    },
    content = ui.content {
      {
        template = I.MWUI.templates.boxTransparentThick,
        content = ui.content {
          {
            type = ui.TYPE.Text,
            props = {
              text = "Use your glamour prisms!",
              textColor = const.TEXT_COLOR,
              textSize = const.HEADER_FONT_SIZE,
              textAlignH = ui.ALIGNMENT.Center,
              textAlignV = ui.ALIGNMENT.Center,
              wordWrap = true,
              multiline = true,
            }
          }
        }
      }
    }
  }

  return box
end

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
  -- Autosize props here...?
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
      relativeSize = sizes.CATEGORY_BUTTON_CONTAINER,
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Right Panel: Category Button Horizontal Container 1",
          relativeSize = sizes.CATEGORY_BUTTON_CONTAINER_ROW,
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        external = {
          stretch = 1,
          grow = 1,
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
          relativeSize = sizes.CATEGORY_BUTTON_CONTAINER_ROW,
          -- size = util.vector2(0, (const.WINDOW_HEIGHT * const.HEADER_REL_SIZE) / 2),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        external = {
          stretch = 1,
          grow = 1,
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

return function()
  local greetingImage = common.templateImage(util.color.hex('ff0000'), 'white', util.vector2(1, 1))
  local fullImage = common.templateImage(util.color.hex('00ff00'), 'white', util.vector2(1.0, 1.0))
  local newGreeting = greeting()
  -- newGreeting.external = {
    -- stretch = 1,
    -- grow = 1,
  -- }
  greetingImage.external = {
    stretch = 1,
    grow = 1,
  }
  -- greetingImage.props.relativePosition = util.vector2(0.25, 0)

  local Header = {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Header",
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      -- autoSize = false,
      horizontal = true,
      -- does it need to be 0 or 1? 0 seems okay
      relativeSize = sizes.RPANEL.HEADER,
    },
    external = {
      -- stretch = 1,
      -- grow = 0.1,
    },
    content = ui.content {
      {external = { grow = 1 }},
      -- fullImage,
      -- newGreeting,
      -- greetingImage,
      categoryButtons(),
      {external = { grow = 1 }},
    },
  }
  return Header
end
