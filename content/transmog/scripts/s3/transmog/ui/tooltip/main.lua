local async = require("openmw.async")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")

local common = require("scripts.s3.transmog.ui.common")
local const = common.const

local I = require("openmw.interfaces")
local PrimaryFieldsRow = require("scripts.s3.transmog.ui.tooltip.primaryfieldsrow")
local Border = require('scripts.s3.transmog.ui.template.border')

local ToolTip = {}
local _toolTip = {}

_toolTip.iconAndNameRow = function()
  return {
    type = ui.TYPE.Flex,
    props = {
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
          name = "Tooltip Item Icon",
          size = util.vector2(85, const.TOOLTIP_SEGMENT_HEIGHT),
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
          textColor = const.TOOLTIP_TEXT_COLOR,
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

---Returns the primry fields row for the tooltip
--- This one's typed, so stuff specific to that record goes here
ToolTip.getSecondaryFieldsRow = function()
  return common.getElementByName(ToolTip.get().layout, "Tooltip: Secondary Fields Row")
end

--- Returns the icon for the tooltip
ToolTip.getRecordIcon = function()
  return common.getElementByName(ToolTip.getIconAndNameRow(), "Tooltip Item Icon")
end

--- Updates the icon for the tooltip
--- Maybe this should be part of the internal table?
--- @param iconPath string: The path to the icon to display
ToolTip.setRecordIcon = function(iconPath)
  ToolTip.getRecordIcon().props.resource = ui.texture { path = iconPath }
end

-- Returns the name for the tooltip
-- Note this is the entire element, not just the text
ToolTip.getNameText = function()
  return common.getElementByName(ToolTip.getIconAndNameRow(), "Tooltip Item Name Text")
end

--- Updates the name for the tooltip
--- @param name string: The name to display
ToolTip.setNameText = function(name)
  ToolTip.getNameText().props.text = name
end

ToolTip.getTypeText = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields Type Text")
end

ToolTip.getGoldPerText = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields GoldPer Text")
end

ToolTip.setGoldPerText = function(value)
  ToolTip.getGoldPerText().props.text = string.format("%.2f", tostring(value))
end

ToolTip.setTypeText = function(record, type)
  local primaryFieldsText = ToolTip.getTypeText()
  local newTypeText = ""
  if record.isScroll then
      newTypeText = newTypeText .. common.recordAliases[type].alternate
  elseif type == types.Weapon or type == types.Armor or type == types.Clothing then
    newTypeText = newTypeText .. common.recordAliases[type][record.type].name
  else
    newTypeText = newTypeText .. common.recordAliases[type].name
  end
  primaryFieldsText.props.text = newTypeText
end

ToolTip.getWeightText = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields Weight Text")
end

ToolTip.setWeightText = function(value)
  ToolTip.getWeightText().props.text = string.format("%.2f", tostring(value))
end

ToolTip.getValueText = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields Value Text")
end

ToolTip.setValueText = function(value)
  ToolTip.getValueText().props.text = tostring(value)
end

ToolTip.getSkillImage = function()
  return common.getElementByName(ToolTip.getPrimaryFieldsRow(), "Primary Fields Skill Image")
end

ToolTip.findSkillImage = function(record, itemType)
  if record.type and common.recordAliases[itemType][record.type].icon then
    return common.recordAliases[itemType][record.type].icon
  end

  if common.recordAliases[itemType].icon and type(common.recordAliases[itemType].icon) == 'string' then
    return common.recordAliases[itemType].icon
  end

  if common.recordAliases[itemType].icon[common.getArmorClass(record.type, record.weight)] then
    return common.recordAliases[itemType].icon[common.getArmorClass(record.type, record.weight)]
  end

  return 'white'
end

ToolTip.setSkillImage = function(value)
  ToolTip.getSkillImage().props.resource = ui.texture { path = value or "white" }
end

ToolTip.setRecordPrimaryFields = function(record, type)
  ToolTip.setTypeText(record, type)
  ToolTip.setValueText(record.value)
  ToolTip.setWeightText(record.weight)
  ToolTip.setGoldPerText(record.value / record.weight)
  ToolTip.setSkillImage(ToolTip.findSkillImage(record, type))
end

ToolTip.getWeaponSpeedText = function()
  return common.getElementByName(ToolTip.getSecondaryFieldsRow(), "Secondary Fields Weapon Speed Text")
end

ToolTip.setWeaponSpeedText = function(value)
  ToolTip.getWeaponSpeedText().props.text = string.format("%.2f", tostring(value))
end

ToolTip.getWeaponReachText = function()
  return common.getElementByName(ToolTip.getSecondaryFieldsRow(), "Secondary Fields Weapon Reach Text")
end

ToolTip.setWeaponReachText = function(value)
  ToolTip.getWeaponReachText().props.text = string.format("%.2f", tostring(value))
end

ToolTip.getWeaponThrustText = function()
  return common.getElementByName(ToolTip.getSecondaryFieldsRow(), "Secondary Fields Weapon Thrust Text")
end

ToolTip.setWeaponThrustText = function(min, max)
  ToolTip.getWeaponThrustText().props.text = tostring(min) .. " - " .. tostring(max)
end

ToolTip.getWeaponChopText = function()
  return common.getElementByName(ToolTip.getSecondaryFieldsRow(), "Secondary Fields Weapon Chop Text")
end

ToolTip.setWeaponChopText = function(min, max)
  ToolTip.getWeaponChopText().props.text = tostring(min) .. " - " .. tostring(max)
end

ToolTip.getWeaponSlashText = function()
  return common.getElementByName(ToolTip.getSecondaryFieldsRow(), "Secondary Fields Weapon Slash Text")
end

ToolTip.setWeaponSlashText = function(min, max)
  ToolTip.getWeaponSlashText().props.text = tostring(min) .. " - " .. tostring(max)
end

ToolTip.WeaponSecondaryRow = function()
  local commonSpacer = { external = { grow = 0.1 } }
  return common.templateBorderlessBoxStack ("Tooltip: Weapon Secondary Row", {
    {
      name = "Secondary Fields Weapon Reach",
      icon = 'icons\\k\\combat_spear.dds',
      -- template = I.MWUI.templates.boxTransparentThick,
      spacer = commonSpacer
    },
    {
      name = "Secondary Fields Weapon Speed",
      icon = 'icons\\k\\attribute_speed.dds',
      spacer = commonSpacer
    },
    {
      name = "Secondary Fields Weapon Thrust",
      icon = 'icons\\k\\stealth_shortblade.dds',
      -- template = I.MWUI.templates.boxTransparentThick,
      spacer = commonSpacer
    },
    {
      name = "Secondary Fields Weapon Chop",
      icon = 'icons\\k\\combat_axe.dds',
      spacer = commonSpacer
    },
    {
      name = "Secondary Fields Weapon Slash",
      icon = 'icons\\k\\combat_longblade.dds',
      -- template = I.MWUI.templates.boxTransparentThick,
      spacer = commonSpacer
    },
  }
  )
end

ToolTip.updateWeaponSecondaryRow = function(record)
    ToolTip.setWeaponSpeedText(record.speed)
    ToolTip.setWeaponReachText(record.reach)
    ToolTip.setWeaponThrustText(record.thrustMinDamage, record.thrustMaxDamage)
    ToolTip.setWeaponChopText(record.chopMinDamage, record.chopMaxDamage)
    ToolTip.setWeaponSlashText(record.slashMinDamage, record.slashMaxDamage)
end

ToolTip.helpWeaponSecondaryRow = function()
    ToolTip.setWeaponSpeedText("Speed")
    ToolTip.setWeaponReachText("Reach")
    ToolTip.setWeaponThrustText("Min", "Max")
    ToolTip.setWeaponChopText("Min", "Max")
    ToolTip.setWeaponSlashText("Min", "Max")
end

ToolTip.SecondaryRowFunctions = {
  [types.Weapon] = {ToolTip.WeaponSecondaryRow, ToolTip.updateWeaponSecondaryRow}
}

ToolTip.buildRecordSecondaryFields = function(record, recordType)
  local secondaryFields = ToolTip.getSecondaryFieldsRow()
  for index, _ in ipairs(secondaryFields.content) do
    secondaryFields.content[index] = nil
  end
  if ToolTip.SecondaryRowFunctions[recordType] then
    secondaryFields.content = ui.content{ToolTip.SecondaryRowFunctions[recordType][1]()}
    ToolTip.SecondaryRowFunctions[recordType][2](record)
  end
end

ToolTip.getRecordId = function()
  return ToolTip.get().layout.userData.recordId
end

ToolTip.setRecordId = function(recordId)
  ToolTip.get().layout.userData.recordId = recordId
end

ToolTip.getRecordType = function()
  return ToolTip.get().layout.userData.type
end

ToolTip.setRecordType = function(type)
  ToolTip.get().layout.userData.type = type
end

ToolTip.getRecord = function()
  return ToolTip.get().layout.userData.record
end

ToolTip.setRecord = function(record)
  ToolTip.get().layout.userData.record = record
end

ToolTip.updateCommonFields = function(itemData)
    ToolTip.setRecordId(itemData.recordId)
    ToolTip.setRecordType(itemData.type)
    ToolTip.setRecord(itemData.record)
    ToolTip.setRecordIcon(itemData.record.icon)
    ToolTip.setNameText(itemData.record.name)
end

--- Callback function for updating the tooltip
--- @param mousePosition openmw.ui#MouseEvent: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_ui.html##(MouseEvent)
--- @param layout openmt_ui#Layout: https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_ui.html##(Layout)
ToolTip.updateTooltip = async:callback(function(mouseEvent, _layout)
    -- print("Tooltip is:\n" .. aux_util.deepToString(layout.content[2], 2))
    if not I.transmogActions.message.toolTip then return end
    I.transmogActions.message.toolTip.layout.props.position = mouseEvent.position + util.vector2(25, 25)
    I.transmogActions.message.toolTip:update()
end)

--- Refreshes the tooltip with new item data
--- @param itemData table: The item data to display, contains the type, recordId, and the whole record
ToolTip.refreshItem = function(itemData)
  if not I.transmogActions.message.toolTip then return end
  I.transmogActions.message.toolTip.layout.props.visible = true
  if ToolTip.getRecordId() ~= itemData.recordId then
    ToolTip.updateCommonFields(itemData)
    ToolTip.setRecordPrimaryFields(itemData.record, itemData.type)
    ToolTip.buildRecordSecondaryFields(itemData.record, itemData.type)
  end
  I.transmogActions.message.toolTip:update()
end

ToolTip.create = function()
  if I.transmogActions.message.toolTip then error("Duplicate tooltip!") return end
  local hBorder = Border(true, 4)
  return {
    template = I.MWUI.templates.boxTransparentThick,
    layer = 'Notification',
    props = {
      name = "Tooltip",
    },
    userData = {},
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.End,
          size = util.vector2(256, 320),
        },
        content = ui.content {
          _toolTip.iconAndNameRow(),
          hBorder,
          PrimaryFieldsRow(),
          hBorder,
          common.templateImage(util.color.hex('000000'), nil, util.vector2(1, 0)),
        }
      }
    }
  }
end

return ToolTip
