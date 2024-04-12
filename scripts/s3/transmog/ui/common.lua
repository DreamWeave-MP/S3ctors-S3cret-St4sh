local async = require('openmw.async')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local templates = I.MWUI.templates

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

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

-- Just a simple text box, this is used in multiple places
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

-- Takes text as input and gives back a laid-out button /w border
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

-- The actual item name goes here
-- This is also part of an ItemPortraitContainer
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

common.defaultPortraitContent = function()
  return {
    common.portraitDefault(),
    common.portraitTextDefault(),
  }
end

common.resetPortraits = function()
  I.transmogActions.baseItemContainer.content = ui.content(common.defaultPortraitContent())
  I.transmogActions.newItemContainer.content = ui.content(common.defaultPortraitContent())
end

common.messageBoxSingleton = function(widgetName, message, duration)
  if I.transmogActions.message.singleton ~= nil then
    async:newUnsavableSimulationTimer(duration or 1,
                                      function()
                                        common.messageBoxSingleton(widgetName, message, duration)
    end)
    return
  end

  I.transmogActions.message.singleton = ui.create {
    template = I.MWUI.templates.boxTransparentThick,
    layer = 'Notification',
    props = {
      name = widgetName,
      relativePosition = util.vector2(0.5, 0.96),
      anchor = util.vector2(0.5, 1.0),
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

  async:newUnsavableSimulationTimer(duration or 1, function()
                                        I.transmogActions.message.singleton:destroy()
                                        I.transmogActions.message.singleton = nil
                                        end)

end

common.teardownTransmog = function(prevStance)
  I.transmogActions.restoreUserInterface()
  I.transmogActions.message.hasShowedPreviewWarning = false
  types.Actor.setEquipment(self, I.transmogActions.originalInventory)
  types.Actor.setStance(self, prevStance or types.Actor.STANCE.Nothing)
  I.transmogActions.menu.layout.props.visible = false
  I.transmogActions.menu:update()
end

return common
