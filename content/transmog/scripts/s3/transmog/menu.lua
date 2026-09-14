---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local camera = require 'openmw.camera'
local core = require 'openmw.core'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local H3UI = I.H3UI
local s3lf = I.s3.lf
local CONTROL_SWITCH = s3lf.CONTROL_SWITCH

local catalog = require 'scripts.s3.transmog.catalog'

local Next = next
local StrFind = string.find
local StrLower = string.lower
local StrFormat = string.format
local TableSort = table.sort
local MathCeil = math.ceil
local MathMax = math.max
local MathMin = math.min

---@class TransmogElement
---@field layout table?
---@field update fun(self: TransmogElement)
---@field destroy fun(self: TransmogElement)
local menu = {}
local state = {
  ---@type TransmogElement?
  element = nil,
  base = nil,
  appearance = nil,
  search = '',
  itemName = '',
  equipment = nil,
  stance = nil,
  cameraMode = nil,
  previewing = false,
  page = 1,
  controls = nil,
  createData = {},
}

local function copyEquipment()
  local result = {}

  for slot, item in Next, s3lf.getEquipment() do
    result[slot] = item
  end

  return result
end

local function restoreEquipment()
  if state.equipment then s3lf.setEquipment(state.equipment) end
end

local function itemData(item)
  local record = item.type.records[item.recordId]

  if not record then return end

  return {
    object = item,
    record = record,
    recordId = item.recordId,
    type = item.type,
  }
end

local function sortByName(a, b) return StrLower(a.record.name) < StrLower(b.record.name) end

local function inventory()
  local result = {}
  local query = StrLower(state.search)

  local inventoryItems = s3lf.inventory():getAll()

  for index = 1, #inventoryItems do
    local item = inventoryItems[index]
    if item:isValid() and catalog.isSupported(item) then
      local data = itemData(item)
      if data and data.record then
        local name = data.record.name
        if query == '' or StrFind(StrLower(name), query, 1, true) then
          result[#result + 1] = data
        end
      end
    end
  end

  TableSort(result, sortByName)

  return result
end

local function canUseAsBase(data)
  return data.type == types.Armor
    or data.type == types.Clothing
    or data.type == types.Weapon
    or data.type == types.Book
end

local function canUseAsAppearance(data)
  if not state.base then return false end

  if data.recordId == state.base.recordId then return false end

  if state.base.type == types.Book then
    return data.type == types.Armor or data.type == types.Clothing or data.type == types.Weapon
  end

  return data.type ~= types.Book
end

local function selectedSlot(label, data)
  local children = {
    H3UI.build {
      component = 'text',
      role = 'selection-label',
      args = {
        text = label,
      },
    },
  }

  if data then
    children[#children + 1] = H3UI.build {
      component = 'itemSlot',
      role = 'selection-item',
      args = {
        resource = data.record.icon and ui.texture { path = data.record.icon } or nil,
        iconProps = { size = util.vector2(64, 64) },
        props = { size = util.vector2(64, 64) },
      },
    }

    children[#children + 1] = H3UI.build {
      component = 'text',
      role = 'selection-name',
      args = {
        text = data.record.name,
      },
    }
  else
    children[#children + 1] = H3UI.build {
      component = 'text',
      role = 'selection-empty',
      args = {
        text = 'None selected',
      },
    }
  end

  return H3UI.build {
    component = 'column',
    role = 'selection',
    args = {
      children = children,
      external = { grow = 1 },
    },
  }
end

local rebuild

local function selectItem(data)
  if not state.base then
    if not canUseAsBase(data) then
      return ui.showMessage 'Choose armor, clothing, a weapon, or an enchanted book as the base item.'
    end
    state.base = data
  elseif canUseAsAppearance(data) then
    state.appearance = data
    state.itemName = data.record.name or ''
    if catalog.isWearable(data.object) then
      local equipment = copyEquipment()
      local slot = catalog.slot(data.object)
      if slot then
        equipment[slot] = data.object
        s3lf.setEquipment(equipment)
      end
    end
  else
    return ui.showMessage 'That item cannot be used for the current Transmog selection.'
  end

  rebuild()
end

local function inventoryItem(data)
  return {
    resource = data.record.icon and ui.texture { path = data.record.icon } or nil,
    count = data.object.count > 1 and data.object.count or nil,
    iconProps = { size = util.vector2(48, 48) },
    props = { size = util.vector2(48, 48) },
    userData = data,
    events = {
      mouseClick = async:callback(function()
        selectItem(data)
        return true
      end),
    },
  }
end

local function buildInventory()
  local allItems = inventory()
  local items = {}
  local pageSize = 49
  local pageCount = MathMax(1, MathCeil(#allItems / pageSize))
  state.page = MathMin(state.page, pageCount)

  local first = (state.page - 1) * pageSize + 1
  local last = MathMin(#allItems, first + pageSize - 1)

  for index = first, last do
    items[#items + 1] = inventoryItem(allItems[index])
  end

  local navigation = H3UI.build {
    component = 'row',
    role = 'pagination',
    args = {
      children = {
        H3UI.build {
          component = 'button',
          role = 'previous-page',
          args = {
            label = '<',
            events = {
              mouseClick = async:callback(function()
                if state.page > 1 then
                  state.page = state.page - 1
                  rebuild()
                end
                return true
              end),
            },
          },
        },

        H3UI.build {
          component = 'text',
          role = 'page-status',
          args = { text = StrFormat('Page %d / %d', state.page, pageCount) },
        },

        H3UI.build {
          component = 'button',
          role = 'next-page',
          args = {
            label = '>',
            events = {
              mouseClick = async:callback(function()
                if state.page < pageCount then
                  state.page = state.page + 1
                  rebuild()
                end
                return true
              end),
            },
          },
        },
      },
    },
  }

  return H3UI.build {
    component = 'column',
    role = 'inventory-panel',
    args = {
      external = { grow = 1, stretch = 1 },
      children = {
        H3UI.build {
          component = 'searchInput',
          role = 'inventory-search',
          args = {
            value = state.search,
            clearable = true,
            onChange = function(value)
              state.search = value
              state.page = 1
              rebuild()
            end,
          },
        },

        navigation,

        H3UI.build {
          recipe = 'itemGrid',
          columns = 7,
          items = items,
          external = { grow = 1, stretch = 1 },
        },
      },
    },
  }
end

local function clearSelection()
  state.base = nil
  state.appearance = nil
  state.itemName = ''
  state.previewing = false
  state.page = 1

  restoreEquipment()
  rebuild()
end

local function confirm()
  if not state.base or not state.appearance then
    return ui.showMessage 'Choose a base item and an appearance first.'
  end

  if state.itemName == '' then return ui.showMessage 'Name the new item first.' end

  restoreEquipment()

  local createData = state.createData
  createData.actor = s3lf.object
  createData.baseRecordId = state.base.recordId
  createData.appearanceRecordId = state.appearance.recordId
  createData.name = state.itemName
  core.sendGlobalEvent('TransmogCreate', createData)
end

local function build()
  local selected = H3UI.build {
    component = 'row',
    role = 'selections',
    args = {
      children = {
        selectedSlot('Base item', state.base),
        selectedSlot('Appearance', state.appearance),
      },
    },
  }

  local controls = {
    H3UI.build {
      component = 'textInput',
      role = 'name-input',
      args = {
        text = state.itemName,
        props = { size = util.vector2(220, 24) },
        events = {
          textChanged = async:callback(function(value, layout)
            state.itemName = value
            layout.props.text = value
            return true
          end),
        },
      },
    },

    H3UI.build {
      component = 'button',
      role = 'clear',
      args = { label = 'Clear', events = { mouseClick = async:callback(clearSelection) } },
    },

    H3UI.build {
      component = 'button',
      role = 'confirm',
      args = { label = 'Create', events = { mouseClick = async:callback(confirm) } },
    },

    H3UI.build {
      component = 'button',
      role = 'close',
      args = { label = 'Close', events = { mouseClick = async:callback(menu.close) } },
    },
  }

  return H3UI.build {
    component = 'window',
    role = 'root',
    args = {
      layer = 'Windows',
      title = 'Transmog',
      closable = false,
      movable = false,
      resizable = false,
      position = util.vector2(20, 80),
      size = util.vector2(620, 650),
      children = {
        H3UI.build {
          component = 'column',
          role = 'body',
          args = {
            props = { relativeSize = util.vector2(1, 1) },
            children = {
              selected,

              H3UI.build {
                component = 'row',
                role = 'controls',
                args = { children = controls },
              },
              buildInventory(),
            },
          },
        },
      },
    },
  }
end

rebuild = function()
  if not state.element then return end

  state.element.layout = build()
  state.element:update()
end

function menu.isOpen() return state.element ~= nil end

function menu.open()
  if state.element then return end

  if I.UI.getMode() ~= nil then
    return ui.showMessage 'Close other menus before opening Transmog.'
  end

  if s3lf.isSwimming() or not s3lf.isOnGround() then
    return ui.showMessage 'You must be standing on the ground to use Transmog.'
  end

  state.equipment = copyEquipment()
  state.stance = s3lf.getStance()
  state.cameraMode = camera.getMode()
  state.base = nil
  state.appearance = nil
  state.search = ''
  state.itemName = ''
  state.previewing = false
  state.page = 1
  state.controls = {
    controls = s3lf.getControlSwitch(CONTROL_SWITCH.Controls),
    looking = s3lf.getControlSwitch(CONTROL_SWITCH.Looking),
  }

  s3lf.setStance(s3lf.STANCE.Nothing)
  s3lf.setControlSwitch(CONTROL_SWITCH.Controls, false)
  s3lf.setControlSwitch(CONTROL_SWITCH.Looking, false)
  I.Controls.overrideUiControls(true)
  camera.showCrosshair(false)
  camera.setYaw(math.pi)
  camera.setPitch(0)
  camera.setRoll(0)
  camera.setMode(camera.MODE.Static)
  camera.setStaticPosition(s3lf.object.position + util.vector3(25, 75, 75))
  I.UI.setHudVisibility(false)
  I.UI.setPauseOnMode(I.UI.MODE.Interface, false)
  I.UI.setMode(I.UI.MODE.Interface, { windows = {} })

  state.element = ui.create(build())
end

function menu.close()
  if not state.element then return end

  restoreEquipment()

  if state.stance then s3lf.setStance(state.stance) end
  s3lf.setControlSwitch(CONTROL_SWITCH.Controls, state.controls.controls)
  s3lf.setControlSwitch(CONTROL_SWITCH.Looking, state.controls.looking)
  I.Controls.overrideUiControls(false)
  camera.showCrosshair(true)
  if state.cameraMode then camera.setMode(state.cameraMode) end
  I.UI.setHudVisibility(true)
  I.UI.setPauseOnMode(I.UI.MODE.Interface, true)
  I.UI.setMode()

  state.element:destroy()
  state.element = nil
  state.equipment = nil
  state.stance = nil
  state.cameraMode = nil
  state.controls = nil
end

function menu.toggle()
  if state.element then
    menu.close()
  else
    menu.open()
  end
end

function menu.confirm()
  if state.element then confirm() end
end

function menu.preview(enabled)
  if
    not state.element
    or not state.appearance
    or not catalog.isWearable(state.appearance.object)
  then
    return
  end

  if enabled then
    local equipment = {}
    for slot, item in Next, state.equipment do
      equipment[slot] = item
    end

    local slot = catalog.slot(state.appearance.object)
    if slot then equipment[slot] = state.appearance.object end
    s3lf.setEquipment(equipment)
  else
    restoreEquipment()

    if state.appearance then
      local equipment = copyEquipment()
      local slot = catalog.slot(state.appearance.object)
      if slot then equipment[slot] = state.appearance.object end
      s3lf.setEquipment(equipment)
    end
  end

  state.previewing = enabled
end

function menu.rotate(amount)
  if state.element then s3lf.controls.yawChange = amount end
end

function menu.created(data)
  if not state.element then return end
  clearSelection()
  if data and data.object and data.object:isValid() then
    local slot = catalog.slot(data.object)
    if slot then
      state.equipment[slot] = data.object
      s3lf.setEquipment(state.equipment)
    end
  end
end

return menu
