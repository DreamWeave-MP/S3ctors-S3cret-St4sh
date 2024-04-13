local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local templates = I.MWUI.templates

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

--- @class common
--- @field const table<string, any>: Constants used throughout the UI
local common = {
  const = {
    WINDOW_HEIGHT = math.min(520, yRes * 0.95), -- Occupy 800px preferably, or full vertical size
    RIGHT_PANE_WIDTH = math.min(600, xRes * 0.30), -- Occupy 600px preferably, or 25% horizontal size
    LEFT_PANE_WIDTH = math.min(140, xRes * 0.2), -- Occupy 200px preferably, or 20% horizontal size
    TEXT_COLOR = util.color.rgb(255, 255, 255),
    BACKGROUND_COLOR = util.color.rgb(0, 0, 0),
    HIGHLIGHT_COLOR = util.color.rgba(44 / 255, 46 / 255, 45 / 255, 0.5),
    IMAGE_SIZE = util.vector2(32, 32),
    FONT_SIZE = 18,
    HEADER_FONT_SIZE = 24,
    HEADER_REL_SIZE = 0.1,
    FOOTER_REL_SIZE = 0.05,
    ROW_LIMIT = 15,
    WIDGET_ORIGIN_PCT = 0.75, -- % of the distance from the top-left corner of the widget to the center of the screen
    TOOLTIP_SEGMENT_HEIGHT = 85,
    TOOLTIP_TYPE_TEXT_SIZE = util.vector2(90, 28)
  },
  recordAliases = {
    [types.Armor] = {
      name = "Armor",
      wearable = true,
      recordGenerator = types.Armor.record,
      [types.Armor.TYPE.Cuirass] = {
        name = "Cuirass",
        slot = types.Actor.EQUIPMENT_SLOT.Cuirass,
        weightClasses = {
          low = 18.0,
          high = 27.0,
        }
      },
      [types.Armor.TYPE.Greaves] = {
        name = "Greaves",
        slot = types.Actor.EQUIPMENT_SLOT.Greaves,
        weightClasses = {
          low = 9.0,
          high = 13.5,
        }
      },
      [types.Armor.TYPE.Boots] = {
        name = "Boots",
        slot = types.Actor.EQUIPMENT_SLOT.Boots,
        weightClasses = {
          low = 12.0,
          high = 18.0,
        }
      },
      [types.Armor.TYPE.Helmet] = {
        name = "Helmet",
        slot = types.Actor.EQUIPMENT_SLOT.Helmet,
        weightClasses = {
          low = 3.0,
          high = 4.5,
        }
      },
      [types.Armor.TYPE.LPauldron] = {
        name = "Left Pauldron",
        slot = types.Actor.EQUIPMENT_SLOT.LeftPauldron,
        weightClasses = {
          low = 6.0,
          high = 9.0,
        },
      },
      [types.Armor.TYPE.RPauldron] = {
        name = "Right Pauldron",
        slot = types.Actor.EQUIPMENT_SLOT.RightPauldron,
        weightClasses = {
          low = 6.0,
          high = 9.0,
        },
      },
      [types.Armor.TYPE.LGauntlet] = {
        name = "Left Gauntlet",
        slot = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
        weightClasses = {
          low = 3.0,
          high = 4.5,
        }
      },
      [types.Armor.TYPE.LBracer] = {
        name = "Left Bracer",
        slot = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
        weightClasses = {
          low = 3.0,
          high = 4.5,
        }
      },
      [types.Armor.TYPE.RGauntlet] = {
        name = "Right Gauntlet",
        slot = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
        weightClasses = {
          low = 3.0,
          high = 4.5,
        }
      },
      [types.Armor.TYPE.RBracer] = {
        name = "Right Bracer",
        slot = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
        weightClasses = {
          low = 3.0,
          high = 4.5,
        }
      },
      [types.Armor.TYPE.Shield] = {
        name = "Shield",
        slot = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
        weightClasses = {
          low = 9.0,
          high = 13.5,
        }
      },
    },
    [types.Weapon] = {
      name = "Weapon",
      wearable = true,
      recordGenerator = types.Weapon.record,
      [types.Weapon.TYPE.AxeOneHand] = {
        name = "One Handed Axe",
      },
      [types.Weapon.TYPE.AxeTwoHand] = {
        name = "Two Handed Axe",
      },
      [types.Weapon.TYPE.BluntOneHand] = {
        name = "One Handed Blunt",
      },
      [types.Weapon.TYPE.BluntTwoClose] = {
        name = "Close Two Handed Blunt",
      },
      [types.Weapon.TYPE.BluntTwoWide] = {
        name = "Wide Two Handed Blunt",
      },
      [types.Weapon.TYPE.MarksmanBow] = {
        name = "Bow",
      },
      [types.Weapon.TYPE.MarksmanCrossbow] = {
        name = "Crossbow",
      },
      [types.Weapon.TYPE.MarksmanThrown] = {
        name = "Thrown",
      },
      [types.Weapon.TYPE.LongBladeOneHand] = {
        name = "One Handed Long Blade",
      },
      [types.Weapon.TYPE.LongBladeTwoHand] = {
        name = "Two Handed Long Blade",
      },
      [types.Weapon.TYPE.ShortBladeOneHand] = {
        name = "Short Blade",
      },
      [types.Weapon.TYPE.SpearTwoWide] = {
        name = "Spear",
      },
      [types.Weapon.TYPE.Arrow] = {
        name = "Arrow",
      },
      [types.Weapon.TYPE.Bolt] = {
        name = "Bolt",
      },
    },
    [types.Clothing] = {
      name = "Clothing",
      wearable = true,
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
    },
    [types.Apparatus] = {
      name = "Apparatus",
      recordGenerator = types.Apparatus.record,
    },
    [types.Book] = {
      name = "Book",
      recordGenerator = types.Book.record,
      alternate = "Scroll",
    },
    [types.Ingredient] = {
      name = "Ingredient",
      recordGenerator = types.Ingredient.record,
    },
    [types.Light] = {
      name = "Light",
      wearable = true,
      recordGenerator = types.Light.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Lockpick] = {
      name = "Lockpick",
      wearable = true,
      recordGenerator = types.Lockpick.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Probe] = {
      name = "Probe",
      wearable = true,
      recordGenerator = types.Probe.record,
      slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
    },
    [types.Repair] = {
      recordGenerator = types.Repair.record,
      name = "Repair",
    },
    [types.Potion] = {
      recordGenerator = types.Potion.record,
      name = "Potion",
    },
  }
}

--- Just a simple text box, this is used in multiple places
--- @param text string: The text to display
--- @return ui.TYPE.Text
function common.TextBox(text)
  local textBox = {
    type = ui.TYPE.Text,
    props = {
      text = text,
      textColor = common.const.TEXT_COLOR,
      textSize = common.const.FONT_SIZE,
      autoSize = true,
    }
  }

  -- We'll probably need to extend this throughout the app but I want to get a
  -- rough gauge for what vertical resolutions people actually use
  if common.const.RIGHT_PANE_WIDTH + common.const.LEFT_PANE_WIDTH < 600 then
    --textBox.props.wordWrap = true
    textBox.props.textSize = 24
    common.const.HEADER_FONT_SIZE = 20
  end

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

--- Generates the element containing the item image/icon
--- It's contained inside of an ItemPortraitContainer
--- @return ui.TYPE.Container
function common.portraitDefault()
  return {
    template = templates.boxTransparentThick,
    content = ui.content {
      {
        template = templates.interval,
        props = {
          name = "Default",
          size = common.const.IMAGE_SIZE * 2,
        },
        external = {
          grow = 1,
        }
      }
    }
  }
end

--- The actual item name goes here
--- This is also part of an ItemPortraitContainer
-- @return ui.TYPE.Text
function common.portraitTextDefault()
  return {
    type = ui.TYPE.Text,
      props = {
        text = "Empty",
        size = util.vector2(128, 64),
        textColor = common.const.TEXT_COLOR,
        textSize = common.const.FONT_SIZE,
        textAlignH = ui.ALIGNMENT.Center,
        multiline = true,
        autoSize = false,
        wordWrap = true,
      }
  }
end

--- Generates the content for the left panel item portraits
common.defaultPortraitContent = function()
  return {
    common.portraitDefault(),
    common.portraitTextDefault(),
  }
end

--- Generates an image element
--- could be used for testing or actual elements
--- Stretch and grow are set to 1 by default, so fills empty space in a flex
--- @param path string: The path to the image, possibly an item record
--- @param size util.vector2: The size of the image
--- @param color util.color: The color of the image
common.templateImage = function(color, path, size)
  local image = {
    type = ui.TYPE.Image,
    external = {
      stretch = 1,
      grow = 1,
    },
    props = {
      size = size or common.const.IMAGE_SIZE,
      resource = ui.texture { path = path or "white" },
    },
  }
  if color then
    image.props.color = color
  end
  return image
end

--- Resets the left panel item portraits to their default state
common.resetPortraits = function()
  I.transmogActions.baseItemContainer.content = ui.content(common.defaultPortraitContent())
  I.transmogActions.newItemContainer.content = ui.content(common.defaultPortraitContent())
end

--- Checks if the confirm menu is visible
--- @return boolean
common.confirmIsVisible = function()
  return I.transmogActions.message.confirmScreen and I.transmogActions.message.confirmScreen.layout.props.visible
end

--- Checks if the menu is visible
--- @return boolean
common.mainIsVisible = function()
  return I.transmogActions.menu and I.transmogActions.menu.layout.props.visible
end

--- Checks if the message box is visible
--- @return boolean
common.messageIsVisible = function()
  return I.transmogActions.message.singleton and I.transmogActions.message.singleton.layout.props.visible
end

--- Checks if the tooltip is visible
--- @return boolean
common.toolTipIsVisible = function()
  return I.transmogActions.message.toolTip and I.transmogActions.message.toolTip.layout.props.visible
end

local messages = {}

--- Creates a message box that will self terminate after a duration and can be queued
--- @param widgetName string: The name of the widget, probably not really used but gives a unique identifier
--- @param message string: The message to display
--- @param duration number: The duration in seconds to display the message
common.messageBoxSingleton = function(widgetName, message, duration)
  if I.transmogActions.message.singleton then
    if I.transmogActions.message.singleton.layout.props.visible then
      messages[#messages + 1] = {widgetName, message, duration}
      return
    else
      I.transmogActions.message.singleton.layout.props.visible = true
      I.transmogActions.message.singleton.layout.props.name = widgetName
      I.transmogActions.message.singleton.layout.content[1].content[1].props.text = message
      I.transmogActions.message.singleton:update()
    end
  else
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
                textShadowColor = util.color.rgb(40, 40, 40),
                textSize = 20,
                textAlignH = ui.ALIGNMENT.Center,
                size = util.vector2(128, 64),
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

--- Restores the user interface to its original state
--- @field prevStance types.Actor.STANCE
common.teardownTransmog = function(prevStance)
  if common.toolTipIsVisible() then
    I.transmogActions.message.toolTip.layout.props.visible = false
    I.transmogActions.message.toolTip:update()
  end
  I.transmogActions.restoreUserInterface()
  I.transmogActions.message.hasShowedPreviewWarning = false
  types.Actor.setEquipment(self, I.transmogActions.originalInventory)
  types.Actor.setStance(self, prevStance or types.Actor.STANCE.Nothing)
  I.transmogActions.menu.layout.props.visible = false
  I.transmogActions.menu:update()
end

--- Checks if a layout has a highlight
--- @param layout openmw_ui#Layout: The layout to check for a highlight
--- @return boolean
common.hasHighlight = function(layout)
  for _, child in ipairs(layout.content) do
    if child.props and child.props.name == "highlight" then
      return true
    end
  end
  return false
end

--- Removes a highlight from an arbitrary layout
--- Don't forget you need to actually update it after!
--- @param layout openmw_ui#Layout: The layout to remove the highlight from
common.removeHighlight = function(layout)
  for index, child in ipairs(layout.content) do
    if child.props and child.props.name == "highlight" then
      table.remove(layout.content, index)
      break
    end
  end
end

--- Adds a highlight to an arbitrary layout
--- Don't forget you need to actually update it after!
--- @param layout openmw_ui#Layout: The layout to add the highlight to
common.addHighlight = function(layout, size)
  if common.hasHighlight(layout) then
    return
  end

  layout.content:insert(1,
                        {
                          type = ui.TYPE.Image,
                          props = {
                            name = "highlight",
                            resource = ui.texture{ path = 'white' },
                            color = common.const.HIGHLIGHT_COLOR,
                            size = size or common.const.IMAGE_SIZE,
                            relativeSize = util.vector2(1, 1),
                          },
                        }
  )
end

common.getElementByName = function(layout, name)
  for _, child in ipairs(layout.content or {}) do
    if child.props and child.props.name == name then
      -- print("Found " .. name)
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
  local classes = common.recordAliases[types.Armor][armorType].weightClasses
  return classes and (
    (weight <= classes.low and "Light") or
    (weight >= classes.high and "Heavy") or
    "Medium"
  )
end

return common
