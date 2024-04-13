local aux_util = require('openmw_aux.util')
local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local common = require("scripts.s3.transmog.ui.common")
local const = common.const

local I = require("openmw.interfaces")

local ToolTip = {}
local _toolTip = {}

_toolTip.iconAndNameRow = function()
  return {
    type = ui.TYPE.Flex,
    props = {
      -- size = util.vector2(256, 85),
      name = "Tooltip: Icon and Name Row",
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    external = {
      stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Image,
        props = {
          -- text = "Tooltip",
          size = util.vector2(85, 85),
          -- resource = ui.texture { path = "white" },
          -- color = util.color.hex('ff00ff'),
          -- textColor = util.color.hex('ffffff'),
          -- textSize = 24,
          -- textAlignH = ui.ALIGNMENT.Center,
          -- textAlignV = ui.ALIGNMENT.Center,
          -- autoSize = false,
        },
      },
      {
        type = ui.TYPE.Text,
        external = {
          grow = 1,
        },
        props = {
          name = "Tooltip",
          relativeSize = util.vector2(1, 1),
          textColor = util.color.hex('ffffff'),
          textSize = 24,
          textAlignH = ui.ALIGNMENT.Start,
          textAlignV = ui.ALIGNMENT.Center,
          multiline = true,
          wordWrap = true,
          autoSize = false,
        }
      },
    },
  }
end

--- Returns the icon and name row for the tooltip
ToolTip.getIconAndNameRow = function()
  return I.transmogActions.message.toolTip.layout.content[1].content[1]
end

--- Returns the icon for the tooltip
ToolTip.getRecordIcon = function()
  return ToolTip.getIconAndNameRow().content[1]
end

-- Returns the name for the tooltip
-- Note this is the entire element, not just the text
ToolTip.getNameText = function()
  return ToolTip.getIconAndNameRow().content[2]
end

--- Updates the icon for the tooltip
--- Maybe this should be part of the internal table?
--- @param iconPath string: The path to the icon to display
ToolTip.updateRecordIcon = function(iconPath)
  ToolTip.getRecordIcon().props.resource = ui.texture { path = iconPath }
end

--- Updates the name for the tooltip
--- @param name string: The name to display
ToolTip.updateRecordName = function(name)
  ToolTip.getNameText().props.text = name
end

--- Callback function for updating the tooltip
--- @param mousePosition openmw.ui#MouseEvent: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_ui.html##(MouseEvent)
--- @param layout openmt_ui#Layout: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_ui.html##(Layout)
ToolTip.updateTooltip = async:callback(function(mouseEvent, _layout)
    -- print("Tooltip is:\n" .. aux_util.deepToString(layout.content[2], 2))
    if not I.transmogActions.message.toolTip then print("Tooltip should be constructed!") return end
    I.transmogActions.message.toolTip.layout.props.position = mouseEvent.position + util.vector2(25, 25)
    I.transmogActions.message.toolTip:update()
end)

--- Refreshes the tooltip with new item data
--- @param itemData table: The item data to display, contains the type, recordId, and the whole record
ToolTip.refreshItem = function(itemData)
  if not I.transmogActions.message.toolTip then print("Tooltip should be constructed!") return end
  I.transmogActions.message.toolTip.layout.props.visible = true
  if I.transmogActions.message.toolTip.layout.userData.recordId ~= itemData.recordId then
    I.transmogActions.message.toolTip.layout.userData.recordId = itemData.recordId
    -- print(aux_util.deepToString(I.transmogActions.message.toolTip.layout.content[1].content[1].content[1], 2))
    ToolTip.updateRecordIcon(itemData.record.icon)
    ToolTip.updateRecordName(itemData.record.name)
  end
  I.transmogActions.message.toolTip:update()
end

ToolTip.create = function()
  if I.transmogActions.message.toolTip then error("Duplicate tooltip!") return end
  return {
    template = I.MWUI.templates.boxTransparentThick,
    layer = 'Notification',
    props = {
      name = "Tooltip",
      -- relativePosition = util.vector2(0.5, 0.5),
      -- anchor = util.vector2(0.5, 0.5)
    },
    userData = {},
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.End,
          size = util.vector2(256, 256),
        },
        content = ui.content {
          _toolTip.iconAndNameRow(),
          -- {
          --   type = ui.TYPE.Image,
          --   props = {
          --     size = util.vector2(256, 85),
          --     resource = ui.texture { path = "white" },
          --     color = util.color.hex('0000ff'),
          --   },
          -- },
          {
            type = ui.TYPE.Image,
            props = {
              size = util.vector2(256, 85),
              resource = ui.texture { path = "white" },
              color = util.color.hex('00ff00'),
            },
          },
          {
            type = ui.TYPE.Image,
            props = {
              size = util.vector2(256, 85),
              resource = ui.texture { path = "white" },
              color = util.color.hex('ff0000'),
            },
          },
        }
      }
    }
  }
end

return ToolTip
