local async = require('openmw.async')
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
    IMAGE_SIZE = util.vector2(32, 32),
    FONT_SIZE = 18,
    HEADER_FONT_SIZE = 24,
    HEADER_REL_SIZE = 0.1,
    FOOTER_REL_SIZE = 0.05,
    ROW_LIMIT = 15,
    WIDGET_ORIGIN_PCT = 0.75, -- % of the distance from the top-left corner of the widget to the center of the screen
  },
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

--- Resets the left panel item portraits to their default state
common.resetPortraits = function()
  I.transmogActions.baseItemContainer.content = ui.content(common.defaultPortraitContent())
  I.transmogActions.newItemContainer.content = ui.content(common.defaultPortraitContent())
end

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

return common
