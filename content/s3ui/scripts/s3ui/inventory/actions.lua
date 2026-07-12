---@omw-context player

local core = require 'openmw.core'
local countModal = require 'scripts.s3ui.components.count_modal'
local input = require 'openmw.input'
local self = require 'openmw.self'
local types = require 'openmw.types'

---@class S3UI.InventoryActionsModule
local M = {}

local Actor = types.Actor
local SLOT = Actor.EQUIPMENT_SLOT

local function playerObject() return self.object or self end

local function playerSelf() return self end

local function queueRebuild(ctx)
  if ctx and ctx.queueRebuild then ctx.queueRebuild() end
end

local function unequipSlot(slot, ctx)
  if not slot or not slot.slot then return false end
  local actor = playerSelf()
  local equipment = Actor.getEquipment(actor)
  if not equipment[slot.slot] then return false end
  equipment[slot.slot] = nil
  Actor.setEquipment(actor, equipment)
  queueRebuild(ctx)
  return true
end

local function dropEventData(itemData, count)
  local actor = playerObject()
  return {
    player = actor,
    item = itemData.item,
    count = count,
    cellName = actor.cell and actor.cell.name or '',
    position = actor.position,
    onGround = true,
  }
end

local function dropCount(itemData, count, ctx)
  if not itemData or not itemData.item then return end
  count = math.floor(tonumber(count) or 0)
  if count < 1 then return end
  if count > itemData.count then count = itemData.count end
  core.sendGlobalEvent('S3UI_DropItem', dropEventData(itemData, count))
end

local function openDropCountModal(itemData, ctx)
  countModal.show {
    title = 'Drop ' .. itemData.name,
    min = 1,
    max = itemData.count,
    initial = itemData.count,
    onOk = function(count) dropCount(itemData, count, ctx) end,
  }
end

local function sendUseItem(item, actor, force)
  core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = force })
  self:sendEvent 'S3UI_InventoryActionQueued'
end

local function useItem(itemData, ctx)
  if not itemData.item then return false end
  local item = itemData.item
  local actor = playerObject()
  local force = itemData.force or false
  if itemData.item.type == types.Repair then
    if ctx and ctx.closeInventoryForRepair then
      ctx.closeInventoryForRepair(function() sendUseItem(item, actor, force) end)
      return true
    end
    sendUseItem(item, actor, force)
    return true
  end
  sendUseItem(item, actor, force)
  return true
end

function M.activateItem(itemData, ctx)
  if not itemData then return end
  if input.isShiftPressed() then
    openDropCountModal(itemData, ctx)
  elseif input.isCtrlPressed() then
    dropCount(itemData, 1, ctx)
  else
    useItem(itemData, ctx)
  end
end

function M.activateEquipmentSlot(slot, ctx)
  if not slot or not slot.itemData then return false end
  return unequipSlot(slot, ctx)
end

return M
