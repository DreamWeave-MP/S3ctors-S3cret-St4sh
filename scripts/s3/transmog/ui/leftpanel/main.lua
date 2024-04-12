local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local common = require('scripts.s3.transmog.ui.common')
local core = require('openmw.core')
local const = common.const
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

--local templates = require('openmw.interfaces').MWUI.templates
local I = require('openmw.interfaces')

local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')

-- This contains the item to be modified
-- It's composed of a flex container with two elements - the image and the text
-- We specify its elements should be centered and it has a max width of 200px
local function ItemPortraitContainer(widgetName)
  return {
    type = ui.TYPE.Flex,
    props = {
      name = widgetName,
      size = util.vector2(const.LEFT_PANE_WIDTH, 0),
      arrange = ui.ALIGNMENT.Center,
    },
    events = {
      mousePress = async:callback(
        function (_, layout)
          local name = layout.props.name

          if name ~= "Default" then
            layout.content = ui.content(common.defaultPortraitContent())
            I.transmogActions.menu:update()
            if name == "New Item" then
              types.Actor.setEquipment(self, I.transmogActions.originalInventory)
            end
          end
      end)
    },
    content = ui.content {
      common.portraitDefault(),
      common.portraitTextDefault(),
    },
  }
end

local function CancelButton()
  local button = common.createButton("Cancel")
  button.events.mousePress = async:callback(
    function (_, _layout)
      I.transmogActions.message.confirmScreen:destroy()
      I.transmogActions.message.confirmScreen = nil
      I.transmogActions.menu.layout.props.visible = true
      I.transmogActions.menu:update()
    end)
  return button
end

local function CreateButton()
  local button = common.createButton("Create")
  button.events.mousePress = async:callback(
    function (_, _layout)
      local newItemName = I.transmogActions.message.confirmScreen.layout.content[2].content[1].props.text

      if newItemName == "" then
        common.messageBoxSingleton("No Name Warning", "You must name your item!")
        return
      end

      local baseItem = I.transmogActions.baseItemContainer.content[2].userData
      local newItem = I.transmogActions.newItemContainer.content[2].userData

      -- A weapon is used as base, with the appearance of a non-equippable item
      -- In this case we only apply the model from the new item on the new record.
      if baseItem.type == types.Weapon then
        local weaponTable = {name = newItemName, model = newItem.record.model, icon = newItem.record.icon}
        core.sendGlobalEvent("mogOnWeaponCreate",
                             {
                               target = self,
                               item = weaponTable,
                               toRemove = baseItem.recordId
                             })
      elseif baseItem.type == types.Book then
        local bookTable = { name = newItemName }
        core.sendGlobalEvent("mogOnBookCreate",
                             {
                               target = self,
                               item = bookTable,
                               toRemoveBook = baseItem.recordId,
                               toRemoveItem = newItem.recordId,
                             })
      elseif baseItem.type == types.Clothing or baseItem.type == types.Armor then
        local apparelTable = { name = newItemName }
        core.sendGlobalEvent("mogOnApparelCreate",
                             {
                               target = self,
                               item = apparelTable,
                               oldItem = baseItem.recordId,
                               newItem = newItem.recordId,
                             })
      end
      types.Actor.setEquipment(self, I.transmogActions.originalInventory)
        I.transmogActions.message.confirmScreen:destroy()
        I.transmogActions.message.confirmScreen = nil
        -- Don't forget there's a tiny delay before the inventory & actor are properly updated,
        -- so we *do* need to wait before updating the UI
        async:newUnsavableSimulationTimer(0.01, function()
                                            common.resetPortraits()
                                            I.transmogActions.itemContainer.content
                                              = ui.content(ItemContainer.updateContent("Apparel"))
                                            I.transmogActions.menu.layout.props.visible = true
                                            I.transmogActions.menu:update()
        end)
  end)
  return button
end

local function ConfirmScreen(itemData)
  I.transmogActions.message.confirmScreen = true
  return {
    type = ui.TYPE.Flex,
    layer = 'HUD',
    props = {
      name = "Confirm Screen",
      size = util.vector2(512, 256),
      relativePosition = util.vector2(0.5, 0.5),
      anchor = util.vector2(0.5, 0.5),
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          text = "Pick a name and confirm",
          size = util.vector2(256, 64),
          textColor = const.TEXT_COLOR,
          textSize = const.FONT_SIZE + 2,
          textAlignH = ui.ALIGNMENT.Center,
          autoSize = false,
        }
      },
      {
        template = I.MWUI.templates.boxSolidThick,
        props = {
          name = "Name Input Box",
        },
        content = ui.content {
          {
            type = ui.TYPE.TextEdit,
            events = {
              textChanged = async:callback(
                function (text, layout)
                  layout.props.text = text
                end)
            },
            props = {
              name = "Name Input",
              size = util.vector2(384, 32),
              textSize = const.FONT_SIZE,
              text = itemData.record.name,
              textColor = const.TEXT_COLOR,
              textAlignH = ui.ALIGNMENT.Center,
              textAlignV = ui.ALIGNMENT.Center,
              autoSize = false,
            }
          }
        }
      },
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Confirm Screen Buttons",
          size = util.vector2(256, 64),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        content = ui.content {
          CancelButton(),
          { external = { grow = 1 } },
          CreateButton(),
        }
      }
    }
  }
end

local function glamourButton()
  local button = common.createButton("Apply Glamour")
  button.events.mousePress = async:callback(
    function (_, _layout)
      local baseItem = I.transmogActions.baseItemContainer.content[2].userData
      local newItem = I.transmogActions.newItemContainer.content[2].userData
      if baseItem and newItem then
        if not I.transmogActions.message.confirmScreen then
          I.transmogActions.message.confirmScreen = ui.create(ConfirmScreen(baseItem))
          I.transmogActions.menu.layout.props.visible = false
          I.transmogActions.menu:update()
        end
      else
        common.messageBoxSingleton("No Glamour Warning", "You must choose two items!")
      end
    end)
  return button
end

return {
  type = ui.TYPE.Flex,
  props = {
    name = "leftpanel",
    size = util.vector2(const.LEFT_PANE_WIDTH, 1),
    arrange = ui.ALIGNMENT.Center,
    },
  content = ui.content {
      { external = { grow = 1 } },
      ItemPortraitContainer("Base Item"),
      { external = { grow = 0.5 } },
      ItemPortraitContainer("New Item"),
      { external = { grow = 0.2 } },
      glamourButton(),
      { external = { grow = 1 } },
  },
  external = {
    stretch = 1,
  }
}
