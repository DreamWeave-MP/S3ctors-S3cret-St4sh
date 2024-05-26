local async = require('openmw.async')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local common = require('scripts.s3.transmog.ui.common')
local ToolTip = require('scripts.s3.transmog.ui.tooltip.main')

local isPreviewing = false
--- @function updatePreview
--- Updates the character to show them wearing the item in the tooltip
local function updatePreview()
  if not I.transmogActions.canMog() or not common.isVisible('main menu') then return end

  if not common.isVisible('tooltip') and not isPreviewing then
    common.messageBoxSingleton("Preview Warning", "You must have an item selected to preview it!", 0.5)
    return
  end

  if I.transmogActions.MenuAliases('new item'):getUserData() then
    isPreviewing = true
    common.messageBoxSingleton("Preview Warning", "You must confirm your current choices before previewing another item!", 0.5)
    return
  end

  local toolTip = ToolTip.get()
  local recordId = ToolTip.getRecordId()

  local equipment = {}
  for slot, item in pairs(I.transmogActions.originalEquipment) do
    if item.recordId == recordId then
      common.messageBoxSingleton("Preview Warning", "You cannot preview an item you are currently wearing!", 0.5)
      return
    end
    equipment[slot] = item
  end

  --- I keep getting invalid item errors so we're gonna try throwing here
  local inventory = types.Actor.inventory(self)
  for index, item in pairs(equipment) do
    if not inventory:find(item.recordId) then
      equipment[index] = nil
      error('MOGMENU: Item not found in inventory')
      return
    end
  end

  if input.getBooleanActionValue("transmogMenuActivePreview") then
    local targetItem = types.Actor.inventory(self):find(recordId)

    if not targetItem then return end
    local baseRecordType = ToolTip.getRecordType()

    if not common.recordAliases[baseRecordType].wearable then
      common.messageBoxSingleton("Preview Warning", "This item cannot be previewed!")
      return
    end

    local subRecordType = ToolTip.getRecord().type

    local slot = common.recordAliases[baseRecordType].slot
      or common.recordAliases[baseRecordType][subRecordType].slot

    equipment[slot] = recordId
    isPreviewing = true
    toolTip.layout.props.visible = false
  else
    isPreviewing = false
    toolTip.layout.props.visible = true
  end

  toolTip:update()
  async:newUnsavableSimulationTimer(0.1, function() types.Actor.setEquipment(self, equipment) end)
end

return {
  eventHandlers = {
    updatePreview = updatePreview
  }
}
