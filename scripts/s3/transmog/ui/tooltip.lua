local aux_util = require('openmw_aux.util')
local async = require("openmw.async")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")


local common = require("scripts.s3.transmog.ui.common")
local const = common.const

local I = require("openmw.interfaces")

local ToolTip = {}
local _toolTip = {}

_toolTip.primaryFieldsRow = function()
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Tooltip: Primary Fields Row",
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    external = {
      grow = 1,
      stretch = 1,
    },
    content = ui.content {
      -- common.templateImage(nil, util.vector2(126, const.TOOLTIP_SEGMENT_HEIGHT), util.color.hex('ff0000')),
      {
        type = ui.TYPE.Text,
        props = {
          name = "Primary Fields Type Text",
          text = "Primary Fields",
          size = util.vector2(90, 0),
          textColor = const.TEXT_COLOR,
          textSize = 12,
          textAlignH = ui.ALIGNMENT.Center,
          textAlignV = ui.ALIGNMENT.Center,
          multiline = true,
          wordWrap = true,
          autoSize = false,
        },
        external = {
          stretch = 1.0,
        },
      },
      -- {
      --   type = ui.TYPE.Text,
      --   props = {
      --     name = "Primary Fields Text",
      --     text = "Primary Fields",
      --     size = util.vector2(126, const.TOOLTIP_SEGMENT_HEIGHT),
      --     textColor = const.TEXT_COLOR,
      --     textSize = 24,
      --     textAlignH = ui.ALIGNMENT.Start,
      --     textAlignV = ui.ALIGNMENT.Center,
      --     multiline = true,
      --     wordWrap = true,
      --     autoSize = false,
      --   }
      -- },
      -- { external = { grow = 1} },
      {
        type = ui.TYPE.Image,
        props = {
          name = "primaryFieldsDivisor",
          size = util.vector2(4, const.TOOLTIP_SEGMENT_HEIGHT),
          resource = ui.texture{ path = 'textures/menu_thick_border_right' .. '.dds' },
          relativePosition = util.vector2(0.5, 0),
        },
      },
      common.templateImage(util.color.hex('00ffff'), nil, nil),
    },
  }
end

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
          name = "Tooltip Item Icon",
          size = util.vector2(85, const.TOOLTIP_SEGMENT_HEIGHT),
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
          name = "Tooltip Item Name Text",
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

ToolTip.get = function()
  return I.transmogActions.message.toolTip
end

--- Returns the icon and name row for the tooltip
ToolTip.getIconAndNameRow = function()
  return common.getElementByName(ToolTip.get().layout, "Tooltip: Icon and Name Row")
end
--- Returns the primry fields row for the tooltip
--- This one's typed, so stuff specific to that record goes here
ToolTip.getPrimaryFieldsRow = function()
  return common.getElementByName(ToolTip.get().layout, "Tooltip: Primary Fields Row")
end

--- Returns the icon for the tooltip
ToolTip.getRecordIcon = function()
  return common.getElementByName(ToolTip.getIconAndNameRow(), "Tooltip Item Icon")
end

-- Returns the name for the tooltip
-- Note this is the entire element, not just the text
ToolTip.getNameText = function()
  return common.getElementByName(ToolTip.getIconAndNameRow(), "Tooltip Item Name Text")
end

ToolTip.getTypeText = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields Type Text")
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

ToolTip.updateRecordPrimaryFields = function(record, type)
  local primaryFieldsText = ToolTip.getTypeText()
  -- local newTypeText = "Type: "
  local newTypeText = ""
  if type == types.Book and record.isScroll then
      newTypeText = newTypeText .. common.recordAliases[type].alternate
  elseif type == types.Weapon then
    print("Weapon type is " .. record.type)
    newTypeText = newTypeText .. common.recordAliases[type][record.type].name
  else
    newTypeText = newTypeText .. common.recordAliases[type].name
  end

  newTypeText = newTypeText .. "\nValue:\n" ..record.value .."\n"
  newTypeText = newTypeText .. "Weight:\n" .. record.weight .."\n"
  primaryFieldsText.props.text = newTypeText
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
    ToolTip.updateRecordPrimaryFields(itemData.record, itemData.type)
    -- common.getElementByName(ToolTip.get().layout, "Primary Fields Text").props.text = itemData.record.name
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
          _toolTip.primaryFieldsRow(),
          -- {
          --   type = ui.TYPE.Image,
          --   props = {
          --     size = util.vector2(256, 85),
          --     resource = ui.texture { path = "white" },
          --     color = util.color.hex('00ff00'),
          --   },
          -- },
          common.templateImage(util.color.hex('00ff00'), nil, util.vector2(256, 85)),
          -- {
          --   type = ui.TYPE.Image,
          --   props = {
          --     size = util.vector2(256, 85),
          --     resource = ui.texture { path = "white" },
          --     color = util.color.hex('ff0000'),
          --   },
          -- },
        }
      }
    }
  }
end

return ToolTip
