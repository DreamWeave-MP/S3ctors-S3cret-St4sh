local async = require('openmw.async')
-- local aux_ui = require('openmw_aux.ui')
-- local aux_util = require('openmw_aux.util')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local ToolTip = require('scripts.s3.transmog.ui.tooltip.main')

local I = require('openmw.interfaces')

local _ItemContainer = {}

local function isEquippable(itemData)
  return itemData.type == types.Armor
    or itemData.type == types.Clothing
    or itemData.type == types.Weapon
    or itemData.type == types.Probe
    or itemData.type == types.Lockpick
    or itemData.type == types.Apparatus
end

_ItemContainer.updateSelectionPortrait = function(itemData)
  return {
    {
      template = I.MWUI.templates.boxTransparentThick,
      content = ui.content {{
          type = ui.TYPE.Image,
          props = {
            name = itemData.recordId .. " portrait",
            resource = ui.texture{ path = itemData.record.icon },
            size = common.const.IMAGE_SIZE * 2,
          },
          external = {
            grow = 1,
          }
      }}
    },
    {
      type = ui.TYPE.Text,
      props = {
        text = itemData.record.name,
        textColor = const.TEXT_COLOR,
        textSize = const.FONT_SIZE,
        size = util.vector2(128, 64),
        textAlignH = ui.ALIGNMENT.Center,
        multiline = true,
        autoSize = false,
        wordWrap = true,
      },
      userData = {
        record = itemData.record,
        recordId = itemData.recordId,
        type = itemData.type,
      },
    }
  }
end

-- We want to check:
-- 1: If the widget has an item in it at all
-- 2: If the two items have the same recordId, they are not compatible
-- Otherwise, we don't care
_ItemContainer.itemFitsSlot = function(itemData, widget)
  local targetPortraitData = widget.content[2].userData
  local targetIsDefault = targetPortraitData == nil

  if widget.props.name == "New Item" and not targetIsDefault then
    local basePortraitData = I.transmogActions.menus.baseItemContainer.content[2].userData
    if basePortraitData
      and basePortraitData.type == types.Book
      and (itemData.type ~= types.Weapon
           and itemData.type ~= types.Armor
           and itemData.type ~= types.Clothing) then
      return false
    end
  end

  if not targetIsDefault and itemData.recordId == targetPortraitData.recordId then
    return false
  end

  return true
end

_ItemContainer.getUserDataFromLayout = function(layout)
  for _, content in ipairs(layout.content) do
    if content.userData then
      return content.userData
    end
  end
end

_ItemContainer.addToLeftPanel = async:callback(function(_, layout)
    -- The portrait, then the box, then the actual image
    -- It should be at index 1, but the highlight is at index 1
    local itemData = _ItemContainer.getUserDataFromLayout(layout)
    local mainWidget = I.transmogActions.menus.main
    local basePortrait = I.transmogActions.menus.baseItemContainer
    local newPortrait = I.transmogActions.menus.newItemContainer

    local updatedPortrait = _ItemContainer.updateSelectionPortrait(itemData)

    local baseIsDefault = basePortrait.content[2].userData == nil
    local itemFitsBase = _ItemContainer.itemFitsSlot(itemData, basePortrait)
    local itemFitsNew = _ItemContainer.itemFitsSlot(itemData, newPortrait)
    if itemFitsNew and itemFitsBase then
      if not baseIsDefault then
        if itemData.type == types.Book then return end
        newPortrait.content = ui.content(updatedPortrait)
        if isEquippable(itemData) then
          local equipmentSlot =  common.recordAliases[itemData.type].slot or common.recordAliases[itemData.type][itemData.record.type].slot
          local equipment = {}
          for slot, item in pairs(I.transmogActions.menus.originalInventory) do
            equipment[slot] = item
          end
          equipment[equipmentSlot] = itemData.recordId
          types.Actor.setEquipment(self, equipment)
        else
          if not I.transmogActions.message.hasShowedPreviewWarning then
            common.messageBoxSingleton("Miscellaneous Item Warning", "Items which are not normally equippable cannot be previewed.\nThis glamour may be risky!", 3)
            I.transmogActions.message.hasShowedPreviewWarning = true
          end
          local equipment = {}
          for slot, item in pairs(I.transmogActions.menus.originalInventory) do
            equipment[slot] = item
          end
          types.Actor.setEquipment(self, equipment)
        end
      else
        if isEquippable(itemData) or itemData.type == types.Book then
          basePortrait.content = ui.content(updatedPortrait)
        end
      end
      mainWidget:update()
    end
end)

_ItemContainer.getEnchantmentFrame = function(record)
  if record.enchant == nil or record.enchant == "" then return nil end
  return {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{ path = "textures\\mogenchant\\menu_icon_magic.dds" },
      size = const.IMAGE_SIZE * 1.5,
    },
  }
end

_ItemContainer.ItemPortrait = function(itemData)
  if not itemData then
    error("Oops! Empty item data!")
  end

  -- Maybe later we remove the padding. It seems sus.
  local container = {
    template = I.MWUI.templates.boxTransparent,
    -- template = I.MWUI.templates.padding,
    --type = ui.TYPE.Flex,
    props = {
      propagateEvents = false,
      name = itemData.recordId .. " container portrait",
    },
    events = {
      mousePress = _ItemContainer.addToLeftPanel,
      mouseMove = ToolTip.updateTooltip,
      focusGain = async:callback(function(_, layout)
          if not I.transmogActions.message.toolTip then
            I.transmogActions.message.toolTip = ui.create(ToolTip.create())
          end
          common.addHighlight(layout)
          ToolTip.refreshItem(itemData)
          I.transmogActions.menus.main:update()
          if input.getBooleanActionValue("transmogMenuActivePreview") then
            I.transmogActions.updatePreview()
          end
      end),
      focusLoss = async:callback(function(_, layout)
          local toolTip = I.transmogActions.message.toolTip
          if common.toolTipIsVisible() then
            toolTip.layout.props.visible = false
            toolTip:update()
          end
          common.removeHighlight(layout)
          I.transmogActions.menus.main:update()
      end),
    },
    content = ui.content {
      _ItemContainer.getEnchantmentFrame(itemData.record) or { props = { name = "Fake Enchantment Frame" }},
      {
        type = ui.TYPE.Image,
        props = {
          resource = ui.texture{ path = itemData.record.icon },
          size = const.IMAGE_SIZE * 1.5,
        },
        userData = {
          record = itemData.record,
          recordId = itemData.recordId,
          type = itemData.type,
        },
      },
    },
  }

  return container
end

_ItemContainer.getItemData = function(typedInventory, itemIndex)
  local item = typedInventory[itemIndex]

  if not item then
    return
  end

  local itemRecord = common.recordAliases[item.type].recordGenerator(item)

  if not itemRecord then
    error("Unequippable item type, you dun goofed")
  end

  return {
    record = itemRecord,
    recordId = item.recordId,
    type = item.type,
  }
  end

_ItemContainer.ItemRow = function(maxRows, typedInventory, itemIndex)
  local ItemRow = {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Item Row ",
      horizontal = true,
      size = util.vector2(common.const.MAX_ITEMS.x * (const.IMAGE_SIZE.x - 4), 0),
    },
    external = {
      stretch = 1,
    },
    content = {},
  }

  for rowIndex = 1, maxRows do
    ItemRow.props.name = ItemRow.props.name .. rowIndex
    local itemData = _ItemContainer.getItemData(typedInventory, itemIndex + rowIndex)
    if itemData then
      ItemRow.content[#ItemRow.content + 1] = _ItemContainer.ItemPortrait(itemData)
    else
      ItemRow.content[#ItemRow.content + 1] = {
        template = I.MWUI.templates.Interval,
        props = {
          size = const.IMAGE_SIZE * 1.5,
        },
      }
    end
  end

  ItemRow.content = ui.content(ItemRow.content)

  return ItemRow
  end

local ItemContainer = {}

ItemContainer.updateContent = function(acceptedTypes)
  local typedInventory = {}

  local maxCols = const.MAX_ITEMS.x
  local maxRows = const.MAX_ITEMS.y

  local typedItems = types.Actor.inventory(self):getAll()

  for _, item in ipairs(typedItems) do
    if acceptedTypes[item.type] then
      typedInventory[#typedInventory + 1] = item
    end
  end

  local itemIndex = 0
  local content = {}

  for _ = 1, maxCols do
    local itemRow = _ItemContainer.ItemRow(maxRows, typedInventory, itemIndex)
    itemIndex = itemIndex + #itemRow.content
    content[#content + 1] = itemRow
  end

  return content
end

ItemContainer.ItemContainer = function(acceptedTypes)
  local Container = {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Item Container",
    },
    userData = acceptedTypes or const.DEFAULT_ITEM_TYPES,
  }

  Container.content = ui.content(ItemContainer.updateContent(Container.userData))

  return Container
end

return ItemContainer
