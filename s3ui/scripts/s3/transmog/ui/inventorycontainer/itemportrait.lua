local async = require('openmw.async')
local gameSelf = require('openmw.self')
local input = require('openmw.input')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local common = require('scripts.s3.transmog.ui.common')
local BaseUI = require('scripts.s3.transmog.ui.baseobject')
local ToolTip = require('scripts.s3.transmog.ui.tooltip.main')

local ItemPortrait = {
  props = {
    propagateEvents = false,
  },
  external = {
    stretch = 1,
    grow = 1,
  },
}

function ItemPortrait:focusGain()
  local menus = I.transmogActions.MenuAliases()

  if not menus['main menu'] or not menus['inventory container'] then
    error('item portrait needs to update, but main menu doesn\'t exist')
  end

  if not menus['tooltip'] then
    I.transmogActions.message.toolTip = ui.create(ToolTip.create())
  end

  self:addHighlight()

  ToolTip.refreshItem(self:getUserData())

  self.userData.element:update()

  -- there's a bit of a flaw here in that the preview itself
  -- depends on the content of the tooltip to update
  -- so, we need to update the preview after the tooltip
  -- but, the refresh method of the tooltip reopens it
  -- so it's very distracting when using the active preview as the tooltip
  -- is spammed open/closed as you move the mouse
  if input.getBooleanActionValue("transmogMenuActivePreview") then
    gameSelf:sendEvent('updatePreview')
  end
end

function ItemPortrait:focusLoss()
  local menus = I.transmogActions.MenuAliases()

  if common.isVisible('tooltip') then
    menus['tooltip'].layout.props.visible = false
    menus['tooltip']:update()
  end

  self:removeHighlight()

  self.userData.element:update()
end

function ItemPortrait:addToLeftPanel(_, _layout)
    local menus = I.transmogActions.MenuAliases()
    local basePortrait = menus['base item']
    local newPortrait = menus['new item']

    local itemData = self:getUserData()
    local itemFitsBase = self.itemFitsSlot(itemData, basePortrait)
    local itemFitsNew = self.itemFitsSlot(itemData, newPortrait)

    if not itemFitsNew or not itemFitsBase then return end

    local targetName = 'new item'

    local equipment = {}
    for slot, item in pairs(I.transmogActions.originalEquipment) do
      equipment[slot] = item
    end

    if not basePortrait:getUserData()
      and (common.recordAliases[itemData.type].wearable or itemData.type == types.Book) then
      targetName = 'base item'
    else
      -- Presently, nothing may take on the appearance of a book
      -- I don't like this, don't think it's necessary
      if itemData.type == types.Book then return end

      -- If the item is wearable, we automatically preview the one in the new slot
      if common.recordAliases[itemData.type].wearable then

        local equipmentSlot = common.recordAliases[itemData.type].slot
          or common.recordAliases[itemData.type][itemData.record.type].slot

        equipment[equipmentSlot] = itemData.recordId
        types.Actor.setEquipment(gameSelf, equipment)

      else
        -- otherwise we just warn about it (once)
        if not I.transmogActions.message.hasShowedPreviewWarning then
          common.messageBoxSingleton("Miscellaneous Item Warning", "Items which are not normally equippable cannot be previewed.\nThis glamour may be risky!", 3)
          I.transmogActions.message.hasShowedPreviewWarning = true
        end
      end
    end

    types.Actor.setEquipment(gameSelf, equipment)

    I.transmogActions.MogMenuEvent({
        targetName = targetName,
        recordId = itemData.recordId,
        action = 'populate'})
end

-- We want to check:
-- 1: If the widget has an item in it at all
-- 2: If the two items have the same recordId, they are not compatible
-- Otherwise, we don't care
ItemPortrait.itemFitsSlot = function(itemData, widget)
  local targetPortraitData = widget:getUserData()
  local targetIsDefault = targetPortraitData == nil

  if widget.props.name == "New Item" and not targetIsDefault then
    local basePortraitData = I.transmogActions.MenuAliases('base item'):getUserData()
    if basePortraitData and basePortraitData.type == types.Book then
      local canStealEnchantment = itemData.type ~= types.Book
      local itemHasEnchantment = itemData.record.enchant ~= nil
      return canStealEnchantment and itemHasEnchantment
    end
  end

  if not targetIsDefault and itemData.recordId == targetPortraitData.recordId then
    return false
  end

  return true
end

function ItemPortrait.new(itemData)
  assert(itemData and itemData.recordId, "Cannot create portrait for nonexistent item!")

  local newPortrait = BaseUI.new(ItemPortrait)
  newPortrait.name = itemData.recordId .. " container portrait"
  newPortrait.userData = {}

  newPortrait.content = ui.content {
    newPortrait.getEnchantmentFrame(itemData.record.enchant or ""),
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path = itemData.record.icon },
        relativeSize = util.vector2(1, 1),
      },
      external = {
        grow = 1,
        stretch = 1,
      },
      userData = {
        record = itemData.record,
        recordId = itemData.recordId,
        type = itemData.type,
      },
    },
  }

  newPortrait.events = {
    focusGain = async:callback(function(_, _layout) newPortrait:focusGain() end),
    focusLoss = async:callback(function(_, _layout) newPortrait:focusLoss() end),
    mouseMove = ToolTip.updateTooltip,
    -- mousePress = async:callback(function(_, _layout) newPortrait:addToLeftPanel() end),
  }

  newPortrait.userData.element = ui.create(newPortrait)


  return newPortrait.userData.element
end


return ItemPortrait
