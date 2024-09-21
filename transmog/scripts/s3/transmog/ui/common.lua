local async = require('openmw.async')
-- local auxUi = require('openmw_aux.ui')
local aux_util = require('openmw_aux.util')
local core = require('openmw.core')
local input = require('openmw.input')
-- local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local Aliases = require('scripts.s3.transmog.ui.menualiases')
local templates = I.MWUI.templates

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

local function colorFromGMST(gmst)
  local colorString = core.getGMST(gmst)
  local numberTable = {}
  for numberString in colorString:gmatch("([^,]+)") do
    if #numberTable == 3 then break end
    local number = tonumber(numberString:match("^%s*(.-)%s*$"))
    if number then
      table.insert(numberTable, number / 255)
    end
  end

  assert(#numberTable == 3, 'Invalid color GMST name: ' .. gmst)

  return util.color.rgb(table.unpack(numberTable))
end

--- @class common
--- @field const table<string, any>: Constants used throughout the UI
local common = {
  const = {
    CHAR_ROTATE_SPEED = 0.3,
    DEFAULT_ITEM_TYPES = {[types.Clothing] = true},
    WINDOW_HEIGHT = math.min(640, yRes * 0.95),
    RIGHT_PANE_WIDTH = math.min(720, xRes * 0.30),
    LEFT_PANE_WIDTH = math.min(140, xRes * 0.2),
    TEXT_COLOR = colorFromGMST('fontcolor_color_normal'),
    TOOLTIP_TEXT_COLOR = colorFromGMST('fontcolor_color_header'),
    BACKGROUND_COLOR = util.color.rgb(0, 0, 0),
    HIGHLIGHT_COLOR = util.color.rgba(44 / 255, 46 / 255, 45 / 255, 0.5),
    IMAGE_SIZE = util.vector2(32, 32),
    INVENTORY_IMAGE_SIZE = util.vector2(48, 48),
    FONT_SIZE = 16,
    HEADER_FONT_SIZE = 24,
    HEADER_REL_SIZE = 0.1,
    FOOTER_REL_SIZE = 0.05,
    MAX_ITEMS = util.vector2(12, 12),
    WIDGET_ORIGIN_PCT = 0.75, -- % of the distance from the top-left corner of the widget to the center of the screen
    TOOLTIP_SEGMENT_HEIGHT = 85,
    TOOLTIP_TYPE_TEXT_SIZE = util.vector2(120.0, 28),
    TOOLTIP_PRIMARY_FIELDS_WIDTH = 120.0,
  },
  actionNames = {
    [input.ACTION.Use] = "Use",
    [input.ACTION.MoveForward] = "Move Forward",
    [input.ACTION.MoveBackward] = "Move Backward",
    [input.ACTION.MoveLeft] = "Move Left",
    [input.ACTION.MoveRight] = "Move Right",
    [input.ACTION.Jump] = "Jump",
    [input.ACTION.ZoomIn] = "Zoom In",
    [input.ACTION.ZoomOut] = "Zoom Out",
  },
  defaultActions = {
    [input.ACTION.Use] = 'Mouse 1',
    [input.ACTION.MoveForward] = 'w',
    [input.ACTION.MoveBackward] = 's',
    [input.ACTION.MoveLeft] = 'a',
    [input.ACTION.MoveRight] = 'd',
    [input.ACTION.Jump] = 'e',
    [input.ACTION.ZoomIn] = 'Wheel Up',
    [input.ACTION.ZoomOut] = 'Wheel Down',
  },
  recordAliases = {
    [types.Armor] = {
      name = "Armor",
      wearable = true,
      recordGenerator = types.Armor.record,

      icon = {
        Light = "icons\\k\\stealth_lightarmor.dds",
        Medium = "icons\\k\\combat_mediumarmor.dds",
        Heavy = "icons\\k\\combat_heavyarmor.dds",
      },

      [types.Armor.TYPE.Cuirass] = {
        name = "Cuirass",
        slot = types.Actor.EQUIPMENT_SLOT.Cuirass,
        weight = core.getGMST('iCuirassWeight'),
      },

      [types.Armor.TYPE.Greaves] = {
        name = "Greaves",
        slot = types.Actor.EQUIPMENT_SLOT.Greaves,
        weight = core.getGMST('iGreavesWeight'),
      },

      [types.Armor.TYPE.Boots] = {
        name = "Boots",
        slot = types.Actor.EQUIPMENT_SLOT.Boots,
        weight = core.getGMST('iBootsWeight'),
      },

      [types.Armor.TYPE.Helmet] = {
        name = "Helmet",
        slot = types.Actor.EQUIPMENT_SLOT.Helmet,
        weight = core.getGMST('iHelmWeight'),
      },

      [types.Armor.TYPE.LPauldron] = {
        name = "Left Pauldron",
        slot = types.Actor.EQUIPMENT_SLOT.LeftPauldron,
        weight = core.getGMST('iCuirassWeight'),
      },

      [types.Armor.TYPE.RPauldron] = {
        name = "Right Pauldron",
        slot = types.Actor.EQUIPMENT_SLOT.RightPauldron,
        weight = core.getGMST('iPauldronWeight'),
      },

      [types.Armor.TYPE.LGauntlet] = {
        name = "Left Gauntlet",
        slot = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
        weight = core.getGMST('iGauntletWeight'),
      },

      [types.Armor.TYPE.LBracer] = {
        name = "Left Bracer",
        slot = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
        weight = core.getGMST('iGauntletWeight'),
      },

      [types.Armor.TYPE.RGauntlet] = {
        name = "Right Gauntlet",
        slot = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
        weight = core.getGMST('iGauntletWeight'),
      },

      [types.Armor.TYPE.RBracer] = {
        name = "Right Bracer",
        slot = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
        weight = core.getGMST('iGauntletWeight'),
      },

      [types.Armor.TYPE.Shield] = {
        name = "Shield",
        icon = "icons\\k\\combat_block.dds",
        slot = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
        weight = core.getGMST('iShieldWeight'),
      },

    },
    [types.Weapon] = {
      name = "Weapon",
      wearable = true,
      recordGenerator = types.Weapon.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
      [types.Weapon.TYPE.AxeOneHand] = {
        name = "One Handed Axe",
        icon = 'icons\\k\\combat_axe.dds',
      },
      [types.Weapon.TYPE.AxeTwoHand] = {
        name = "Two Handed Axe",
        icon = 'icons\\k\\combat_axe.dds',
      },
      [types.Weapon.TYPE.BluntOneHand] = {
        name = "One Handed Blunt",
        icon = 'icons\\k\\combat_blunt.dds',
      },
      [types.Weapon.TYPE.BluntTwoClose] = {
        name = "Close Two Handed Blunt",
        icon = 'icons\\k\\combat_blunt.dds',
      },
      [types.Weapon.TYPE.BluntTwoWide] = {
        name = "Wide Two Handed Blunt",
        icon = 'icons\\k\\combat_blunt.dds',
      },
      [types.Weapon.TYPE.MarksmanBow] = {
        name = "Bow",
        icon = 'icons\\k\\stealth_marksman.dds',
      },
      [types.Weapon.TYPE.MarksmanCrossbow] = {
        name = "Crossbow",
        icon = 'icons\\k\\stealth_marksman.dds',
      },
      [types.Weapon.TYPE.MarksmanThrown] = {
        name = "Thrown",
        icon = 'icons\\k\\stealth_marksman.dds',
      },
      [types.Weapon.TYPE.LongBladeOneHand] = {
        name = "One Handed Long Blade",
        icon = 'icons\\k\\combat_longblade.dds',
      },
      [types.Weapon.TYPE.LongBladeTwoHand] = {
        name = "Two Handed Long Blade",
        icon = 'icons\\k\\combat_longblade.dds',
      },
      [types.Weapon.TYPE.ShortBladeOneHand] = {
        name = "Short Blade",
        icon = 'icons\\k\\stealth_shortblade.dds',
      },
      [types.Weapon.TYPE.SpearTwoWide] = {
        name = "Spear",
        icon = 'icons\\k\\combat_spear.dds',
      },
      [types.Weapon.TYPE.Arrow] = {
        name = "Arrow",
        icon = 'icons\\k\\stealth_marksman.dds',
      },
      [types.Weapon.TYPE.Bolt] = {
        name = "Bolt",
        icon = 'icons\\k\\stealth_marksman.dds',
      },
    },
    [types.Clothing] = {
      name = "Clothing",
      wearable = true,
      icon = 'icons\\k\\magic_unarmored.dds',
      recordGenerator = types.Clothing.record,
      [types.Clothing.TYPE.Shirt] = {
        name = "Shirt",
        slot = types.Actor.EQUIPMENT_SLOT.Shirt,
      },
      [types.Clothing.TYPE.Pants] = {
        name = "Pants",
        slot = types.Actor.EQUIPMENT_SLOT.Pants,
      },
      [types.Clothing.TYPE.Skirt] = {
        name = "Skirt",
        slot = types.Actor.EQUIPMENT_SLOT.Skirt,
      },
      [types.Clothing.TYPE.Robe] = {
        name = "Robe",
        slot = types.Actor.EQUIPMENT_SLOT.Robe,
      },
      [types.Clothing.TYPE.Shoes] = {
        name = "Shoes",
        slot = types.Actor.EQUIPMENT_SLOT.Boots,
      },
      [types.Clothing.TYPE.Amulet] = {
        name = "Amulet",
        slot = types.Actor.EQUIPMENT_SLOT.Amulet,
      },
      [types.Clothing.TYPE.Belt] = {
        name = "Belt",
        slot = types.Actor.EQUIPMENT_SLOT.Belt,
      },
      [types.Clothing.TYPE.Ring] = {
        name = "Ring",
        -- Maybe a bit sus to only offer one ring slot, but they're not visible anyway.
        slot = types.Actor.EQUIPMENT_SLOT.LeftRing,
      },
    },
    [types.Miscellaneous] = {
      name = "Miscellaneous",
      recordGenerator = types.Miscellaneous.record,
      icon = "icons\\k\\attribute_luck.dds",
    },
    [types.Apparatus] = {
      name = "Apparatus",
      recordGenerator = types.Apparatus.record,
      [types.Apparatus.TYPE.Alembic] = {
        name = "Alembic",
        icon = "icons\\k\\magic_alchemy.dds",
      },
      [types.Apparatus.TYPE.Calcinator] = {
        name = "Calcinator",
        icon = "icons\\k\\magic_alchemy.dds",
      },
      [types.Apparatus.TYPE.Retort] = {
        name = "Retort",
        icon = "icons\\k\\magic_alchemy.dds",
      },
      [types.Apparatus.TYPE.MortarPestle] = {
        name = "Mortar and Pestle",
        icon = "icons\\k\\magic_alchemy.dds",
      },
    },
    [types.Book] = {
      name = "Book",
      recordGenerator = types.Book.record,
      icon = "icons\\k\\attribute_int.dds",
      alternate = "Scroll",
    },
    [types.Ingredient] = {
      name = "Ingredient",
      icon = "icons\\k\\magic_alchemy.dds",
      recordGenerator = types.Ingredient.record,
    },
    [types.Light] = {
      name = "Light",
      icon = "icons\\s\\tx_s_light.dds",
      wearable = true,
      recordGenerator = types.Light.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Lockpick] = {
      name = "Lockpick",
      icon = "icons\\k\\stealth_security.dds",
      wearable = true,
      recordGenerator = types.Lockpick.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Probe] = {
      name = "Probe",
      icon = "icons\\k\\stealth_security.dds",
      wearable = true,
      recordGenerator = types.Probe.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Repair] = {
      recordGenerator = types.Repair.record,
      icon = "icons\\k\\combat_armor.dds",
      name = "Repair",
    },
    [types.Potion] = {
      recordGenerator = types.Potion.record,
      name = "Potion",
      icon = "icons\\k\\magic_alchemy.dds",
    },
  }
}

function common.getTextSize()
  if ui.layers[1].size.y <= 600 then
    return common.const.FONT_SIZE - 8
  elseif ui.layers[1].size.y <= 720 then
    return common.const.FONT_SIZE - 4
  elseif ui.layers[1].size.y <= 1080 then
    return common.const.FONT_SIZE
  elseif ui.layers[1].size.y >= 2160 then
    return common.const.FONT_SIZE + 8
  end
end

--- Just a simple text box, this is used in multiple places
--- @param text string: The text to display
--- @return ui.TYPE.Text
function common.TextBox(text)

  local textBox = {
    type = ui.TYPE.Text,
    props = {
      text = text,
      textColor = common.const.TEXT_COLOR,
      textSize = common.getTextSize(),
      autoSize = true,
    }
  }

  local widget = {
    template = templates.padding,
    content = ui.content{ textBox },
  }

  return ui.content{ widget }
end

--- Takes text as input and gives back a laid-out button /w border
--- @param text string: The text to display on the button
--- @return ui.TYPE.Container
function common.createButton(text)
return {
  template = templates.boxTransparentThick,
  content = common.TextBox(text),
  props = {},
  events = {},
}
end

--- Generates an image element
--- could be used for testing or actual elements
--- Stretch and grow are set to 1 by default, so fills empty space in a flex
--- @param path string: The path to the image, possibly an item record
--- @param relativeSize util.vector2: The size of the image
--- @param color util.color: The color of the image
common.templateImage = function(color, path, relativeSize)
  local image = {
    type = ui.TYPE.Image,
    external = {
      stretch = 1,
      grow = 1,
    },
    props = {
      relativeSize = relativeSize or util.vector2(1, 1),
      resource = ui.texture { path = path or "white" },
    },
  }
  if color then
    image.props.color = color
  end
  return image
end

common.templateBoxImageWithText = function(widgetName, iconPath)
  local templateBox = {
    template = I.MWUI.templates.boxTransparentThick,
    props = {
      name = widgetName .. " Border",
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = widgetName .. " Flex",
          align = ui.ALIGNMENT.Start,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(common.const.TOOLTIP_PRIMARY_FIELDS_WIDTH, 0),
          horizontal = true,
        },
        content = ui.content {
          { external = { grow = 1 }, name = "Spacer Left" },
          {
            type = ui.TYPE.Text,
            external = {
              grow = 1,
              stretch = 1,
            },
            props = {
              name = widgetName .. " Text",
              text = widgetName or "",
              textColor = common.const.TEXT_COLOR,
              textSize = 16,
              textAlignV = ui.ALIGNMENT.Center,
              autoSize = false,
            },
          },
          { external = { grow = 1 }, name = "Spacer Right" },
        }
      },
    }
  }
  local templateFlex = templateBox.content[1]
  if iconPath then
    templateFlex.content:insert(1,
                                {
                                  type = ui.TYPE.Image,
                                  props = {
                                    name = widgetName .. " Image",
                                    size = util.vector2(24, 24),
                                    resource = ui.texture { path = iconPath or 'white' },
                                  },
    })
  end
  return templateBox
end

common.templateBorderlessBoxStack = function(stackName, boxes, horizontal)
  local BoxStack = {}
  for _, stackedBox in ipairs(boxes) do
    local newBox = common.templateBoxImageWithText(stackedBox.name, stackedBox.icon)
    newBox.template = stackedBox.template or I.MWUI.templates.boxTransparent
    local size = stackedBox.iconSize or util.vector2(22, 22)
    local fakeSpacer = stackedBox.spacer --or { external = { grow = 0.5 } }
    local text = common.getElementByName(newBox, stackedBox.name .. " Text")
    local image = common.getElementByName(newBox, stackedBox.name .. " Image")
    if image then
      image.props.size = size
    else
      text.props.autoSize = true
      text.props.textSize = stackedBox.textSize or 16
    end
    if stackedBox.spacer then
      newBox.content[1].content[2] = fakeSpacer
      newBox.content[1].content[4] = fakeSpacer
    end

    if stackedBox.autoSize and not text.props.autoSize then
      text.props.autoSize = true
    end

    BoxStack[#BoxStack + 1] = newBox
  end

  return {
    template = I.MWUI.templates.boxTransparent,
    props = {
      name = stackName .. " Container",
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = stackName .. " Row",
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Center,
          relativeSize = util.vector2(1, 0),
          horizontal = horizontal,
        },
        content = ui.content(BoxStack),
      }
    }
  }
end

--- Checks if the element is visible
--- @param element openmw_ui#ContentOrElement: The element to check for visibility
common.isVisible = function(element)
  return Aliases(element) and Aliases(element).layout.props.visible
end

local messages = {}

--- Creates a message box that will self terminate after a duration and can be queued
--- @param widgetName string: The name of the widget, probably not really used but gives a unique identifier
--- @param message string: The message to display
--- @param duration number: The duration in seconds to display the message
common.messageBoxSingleton = function(widgetName, message, duration)
  if I.transmogActions.message.singleton then
    if I.transmogActions.message.singleton.layout.props.visible then
      for queuedMessage in pairs(messages) do
        if messages[queuedMessage][1] == widgetName then
          return
        end
      end
      messages[#messages + 1] = {widgetName, message, duration}
      return
    else
      I.transmogActions.message.singleton.layout.props.visible = true
      I.transmogActions.message.singleton.layout.props.name = widgetName
      I.transmogActions.message.singleton.layout.content[1].content[1].props.text = message
      I.transmogActions.message.singleton:update()
    end
  else
    local shadowColor = common.const.TEXT_COLOR:asRgb() * .5
    I.transmogActions.message.singleton = ui.create {
      template = I.MWUI.templates.boxTransparentThick,
      layer = 'Notification',
      props = {
        name = widgetName,
        relativePosition = util.vector2(0.5, 0.96),
        anchor = util.vector2(0.5, 1.0),
        visible = true,
      },
      content = ui.content {
        {
          type = ui.TYPE.Flex,
          props = {
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            size = util.vector2(256, 64),
          },
          content = ui.content {
            {
              type = ui.TYPE.Text,
              props = {
                text = message,
                textColor = common.const.TEXT_COLOR,
                wordWrap = true,
                multiline = true,
                textShadow = true,
                textShadowColor = util.color.rgb(shadowColor.x, shadowColor.y, shadowColor.z),
                textSize = 20,
                textAlignV = ui.ALIGNMENT.Center,
                textAlignH = ui.ALIGNMENT.Center,
              }
            },
          }
        }
      }
    }
  end

  -- the messagebox should always self terminate if it's either created or updated
  async:newUnsavableSimulationTimer(duration or 1, function()
                                        I.transmogActions.message.singleton.layout.props.visible = false
                                        I.transmogActions.message.singleton:update()
                                        local newMessage = table.remove(messages, 1)
                                        if newMessage then
                                          common.messageBoxSingleton(newMessage[1], newMessage[2], newMessage[3])
                                        end
                                        end)
end

common.getElementByName = function(layout, name)
  for _, child in ipairs(layout.content or {}) do
    if child.props and child.props.name == name then
      return child
    end
    local found = common.getElementByName(child, name)
    if found then return found end
  end
end

common.deepPrint = function(item, depth)
  print(aux_util.deepToString(item, depth or 1))
end

--- Gets the armor class for a given armor type and weight
--- @param armorType types.Armor.TYPE: The type of armor
--- @param weight number: The weight of the armor
common.getArmorClass = function(armorType, weight)
  local epsilon = 5e-4
  local weightMod = common.recordAliases[types.Armor][armorType].weight
  local lightMaxmod = core.getGMST('fLightMaxMod')
  local medMaxmod = core.getGMST('fMedMaxMod')

  if weight == 0 then return 'Unarmored' end
  if weight <= weightMod * lightMaxmod + epsilon then return 'Light' end
  if weight <= weightMod * medMaxmod + epsilon then return 'Medium' end
  return 'Heavy'
end

--- Gets the item slot for a given item
--- @param itemRecord #Types.RECORD: can actually be any record type, but not an ID or GO
common.getItemSlotForRecord = function(itemType, subType)
  if not subType -- no subtype, thus not equippable
    or not common.recordAliases[itemType] -- Not saved at all
    or not common.recordAliases[itemType].wearable -- Save but not wearable
  then return end

  return common.recordAliases[itemType][subType].slot
end

--- Gets the item slot for a given game object
--- Because I suddenly realized I was working directly with gameObjects
--- @param gameObject #GameObject: The game object to get the slot for
common.getItemSlotForGameObject = function(gameObject)
  assert(gameObject ~= nil, 'Gameobject must not be nil!')
  local record = gameObject.type.records[gameObject.recordId]
  return common.getItemSlotForRecord(gameObject.type, record.type)
end

--- When a mog is done, and equip is true on the `updateItemContainer` event,
--- Run this to add the item to the player's inventory and refresh it
--- @param item #GameObject: The item to equip
--- @return #Types.EQUIPMENT_SLOT: The slot the item was equipped to, or nil
common.refreshEquipment = function(item)
  local newSlot = common.getItemSlotForGameObject(item)
  if newSlot then
    common.addToOriginalEquipment(newSlot, item)
  end
  return newSlot
end

--- Adds an item to the original equipment
--- This is used when 'mogging an item, and an inventorry slot was replaced
--- @param slot #Types.EQUIPMENT_SLOT: The slot to add the item to
--- @param gameObjectOrId #GameObjectOrRecordId: Can be an item from the inventory directly (or another), or just a string id
common.addToOriginalEquipment = function(slot, gameObjectOrId)
  Aliases()['original equipment'][slot] = gameObjectOrId
end

--- Updates the original equipment
--- This is used to restore the player's inventory to its correct state
--- Mostly only when constructing the ui from scratch
--- This is NOT used when 'mogging an item, as you may be previewing something
common.updateOriginalEquipment = function()
  Aliases()['original equipment'] = {}
  for slot, item in pairs(Aliases('current equipment')) do
    Aliases()['original equipment'][slot] = item
  end
end


return common
