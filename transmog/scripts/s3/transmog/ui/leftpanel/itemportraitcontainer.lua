local async = require('openmw.async')
local gameSelf = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local BaseUI = require('scripts.s3.transmog.ui.baseobject')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const

--- Generates the element containing the item image/icon
--- It's contained inside of an ItemPortraitContainer
--- @return ui.TYPE.Container
local function PortraitDefault()
  return {
    template = I.MWUI.templates.bordersThick,
    type = ui.TYPE.Flex,
    props = {
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
      autoSize = false,
    },
    external = {
      grow = .5,
      stretch = .75,
    },
    content = ui.content {
      {
        template = I.MWUI.templates.interval,
        props = {
          name = "Default",
        },
      }
    }
  }
end

--- The actual item name goes here
--- This is also part of an ItemPortraitContainer
-- @return:  ui.TYPE.Text
local function PortraitTextDefault()
  return {
    type = ui.TYPE.Text,
    props = {
      text = "Empty",
      textColor = common.const.TEXT_COLOR,
      textSize = common.getTextSize(),
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      multiline = true,
      wordWrap = true,
    }
  }
end

local function defaultPortraitContent()
  return {
    PortraitDefault(),
    PortraitTextDefault(),
  }
end

-- This contains the items to be modified
-- It's composed of a flex container with two elements - the image and the text
-- We specify its elements should be centered
local ItemPortraitContainer = {
  type = ui.TYPE.Flex,
  props = {
    arrange = ui.ALIGNMENT.Center,
  },
  external = {
    grow = 1,
    stretch = 1,
  },
  events = {
    mousePress = async:callback(
      function (_, layout)
        local name = layout.props.name

        if name ~= "Default" then
          layout.content = ui.content(defaultPortraitContent())
          I.transmogActions.MenuAliases('main menu'):update()
          if name == "New Item" then
            types.Actor.setEquipment(gameSelf, I.transmogActions.originalEquipment)
          end
        end
    end)
  },
  content = ui.content {
    PortraitDefault(),
    PortraitTextDefault(),
  },
}

function ItemPortraitContainer:populate(recordId)
  local gameObject = types.Actor.inventory(gameSelf):find(recordId)
  local itemRecord = common.recordAliases[gameObject.type].recordGenerator(gameObject)

  if not gameObject then
    self.content = ui.content(defaultPortraitContent())
    error("Item not found in inventory, you dun goofed")
  end

  self.content = ui.content {
    {
      template = I.MWUI.templates.bordersThick,
      type = ui.TYPE.Flex,
      props = {
        align = ui.ALIGNMENT.Center,
        arrange = ui.ALIGNMENT.Center,
        autoSize = false,
        horizontal = true,
      },
      external = {
        grow = .5,
        stretch = .75,
      },
      content = ui.content {
        {
          type = ui.TYPE.Image,
          props = {
            name = recordId .. " portrait",
            resource = ui.texture { path = itemRecord.icon },
            relativeSize = util.vector2(.75, .75),
          },
        }
      }
    },

    {
      type = ui.TYPE.Text,
      props = {
        text = itemRecord.name,
        textColor = const.TEXT_COLOR,
        textSize = common.getTextSize(),
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        multiline = true,
        wordWrap = true,
      },
      userData = {
        record = itemRecord,
        recordId = recordId,
        type = gameObject.type,
      },
    }
  }
end

function ItemPortraitContainer.new(widgetName)
  ItemPortraitContainer.props.name = widgetName
  return BaseUI.new(ItemPortraitContainer)
end

function ItemPortraitContainer:mogMenuEvent(mogArgs)
  local action = mogArgs.action
  local doUpdate = action == 'populate' or action == 'clear'

  if action == 'populate' then
    self:populate(mogArgs.recordId)
  elseif action == 'clear' then
    self.content = ui.content(defaultPortraitContent())
  end

  if doUpdate then I.transmogActions.MenuAliases('main menu'):update() end
end

return ItemPortraitContainer
