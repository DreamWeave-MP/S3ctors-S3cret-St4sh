---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local camera = require 'openmw.camera'
local constants = require 'scripts.omw.mwui.constants'
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
local UtilVector2 = util.vector2

local smallGap = constants.padding * 3
local mediumGap = constants.padding * 4
local largeGap = constants.padding * 6
local outerGap = constants.padding * 8
local gridGap = constants.padding * 3
local selectionNameWidth = 210
local selectionNameHeight = 48
local selectionIconSize = 72
local selectionBodyHeight = 152
local iconColor = util.color.rgb(1, 0.78, 0.25)
local hoveredIconAlpha = 1
local normalIconAlpha = 0.78

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

local function makeSpacer(width, height)
  return H3UI.build {
    component = 'spacer',
    args = { props = { size = UtilVector2(width, height) } },
  }
end

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
  local selectionItem = H3UI.build {
    component = 'itemSlot',
    role = 'selection-item',
    args = {
      resource = data and data.record.icon and ui.texture { path = data.record.icon } or nil,
      iconProps = { size = UtilVector2(selectionIconSize, selectionIconSize) },
      props = { size = UtilVector2(selectionIconSize, selectionIconSize) },
    },
  }

  local selectionContent = H3UI.build {
    component = 'column',
    role = 'selection-content',
    args = {
      props = { autoSize = false, relativeSize = UtilVector2(1, 1) },
      children = {
        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },
        H3UI.build {
          component = 'row',
          role = 'selection-item-row',
          args = {
            props = { align = ui.ALIGNMENT.Center },
            external = { stretch = 1 },
            children = { selectionItem },
          },
        },
        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },
        H3UI.build {
          component = 'text',
          role = data and 'selection-name' or 'selection-empty',
          args = {
            text = data and data.record.name or 'None selected',
            props = {
              textColor = constants.headerColor,
              textSize = constants.textHeaderSize,
              multiline = true,
              wordWrap = true,
              autoSize = false,
              size = UtilVector2(selectionNameWidth, selectionNameHeight),
              textAlignH = ui.ALIGNMENT.Center,
              textAlignV = ui.ALIGNMENT.End,
            },
          },
        },
      },
    },
  }

  local children = {
    H3UI.build {
      component = 'widget',
      role = 'selection-body',
      args = {
        props = {
          autoSize = false,
          size = UtilVector2(selectionNameWidth, selectionBodyHeight),
        },
        children = { selectionContent },
      },
    },
  }

  return H3UI.build {
    component = 'bookFrame',
    role = 'selection',
    args = {
      title = label,
      titleProps = {
        size = UtilVector2(selectionNameWidth, constants.textHeaderSize),
        autoSize = false,
        multiline = false,
        wordWrap = false,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      },
      children = children,
      external = { grow = 1 },
    },
  }
end

local function isSelected(data)
  return state.base and state.base.object == data.object
    or state.appearance and state.appearance.object == data.object
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
  local selected = isSelected(data)
  local iconProps = {
    size = UtilVector2(48, 48),
    alpha = selected and hoveredIconAlpha or normalIconAlpha,
  }
  if selected then iconProps.color = iconColor end

  return {
    resource = data.record.icon and ui.texture { path = data.record.icon } or nil,
    count = data.object.count > 1 and data.object.count or nil,
    iconProps = iconProps,
    props = { size = UtilVector2(48, 48) },
    userData = data,
    events = {
      focusGain = async:callback(function(_, layout)
        layout.content.icon.props.alpha = hoveredIconAlpha
        return true
      end),
      focusLoss = async:callback(function(_, layout)
        layout.content.icon.props.alpha = selected and hoveredIconAlpha or normalIconAlpha
        return true
      end),
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
      external = { stretch = 1 },
      children = {
        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },

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

        makeSpacer(mediumGap, 0),

        H3UI.build {
          component = 'text',
          role = 'page-status',
          args = {
            text = StrFormat('Page %d / %d', state.page, pageCount),
            props = { textColor = constants.normalColor },
          },
        },

        makeSpacer(mediumGap, 0),

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

        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },
      },
    },
  }

  return H3UI.build {
    component = 'bookFrame',
    role = 'inventory-panel',
    args = {
      title = 'Inventory',
      children = {
        makeSpacer(0, smallGap),

        H3UI.build {
          recipe = 'itemGrid',
          columns = 7,
          items = items,
          columnGap = gridGap,
          rowGap = gridGap,
        },

        makeSpacer(0, largeGap),
        navigation,
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

local function buildSearch()
  return H3UI.build {
    component = 'bookFrame',
    role = 'search-panel',
    args = {
      title = 'Filter inventory',
      children = {
        H3UI.build {
          component = 'text',
          role = 'search-label',
          args = { text = 'Search by item name' },
        },
        makeSpacer(0, mediumGap),
        H3UI.build {
          component = 'searchInput',
          role = 'inventory-search',
          args = {
            value = state.search,
            clearable = true,
            inputProps = { size = UtilVector2(420, 28) },
            onChange = function(value)
              state.search = value
              state.page = 1
              rebuild()
            end,
          },
        },
      },
    },
  }
end

local function buildActions()
  local actionButtons = H3UI.build {
    component = 'row',
    role = 'primary-actions',
    args = {
      external = { stretch = 1 },
      children = {
        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },
        H3UI.build {
          component = 'button',
          role = 'clear',
          args = { label = 'Clear', events = { mouseClick = async:callback(clearSelection) } },
        },
        makeSpacer(largeGap, 0),
        H3UI.build {
          component = 'button',
          role = 'confirm',
          args = { label = 'Create', events = { mouseClick = async:callback(confirm) } },
        },
        makeSpacer(largeGap, 0),
        H3UI.build {
          component = 'button',
          role = 'close',
          args = { label = 'Close', events = { mouseClick = async:callback(menu.close) } },
        },
        H3UI.build {
          component = 'spacer',
          args = { grow = 1 },
        },
      },
    },
  }

  return H3UI.build {
    component = 'bookFrame',
    role = 'actions-panel',
    args = {
      title = 'Create item',
      children = {
        H3UI.build {
          component = 'row',
          role = 'name-control',
          args = {
            external = { stretch = 1 },
            children = {
              H3UI.build {
                component = 'text',
                role = 'name-label',
                args = {
                  text = 'New item name',
                  props = {
                    textColor = constants.headerColor,
                    textSize = constants.textHeaderSize,
                  },
                },
              },
              makeSpacer(mediumGap, 0),
              H3UI.build {
                component = 'textInput',
                role = 'name-input',
                args = {
                  text = state.itemName,
                  props = { size = UtilVector2(320, 28) },
                  external = { grow = 1 },
                  events = {
                    textChanged = async:callback(function(value, layout)
                      state.itemName = value
                      layout.props.text = value
                      return true
                    end),
                  },
                },
              },
            },
          },
        },
        makeSpacer(0, largeGap),
        actionButtons,
      },
    },
  }
end

local function build()
  local selected = H3UI.build {
    component = 'row',
    role = 'selections',
    args = {
      children = {
        selectedSlot('Base item', state.base),
        makeSpacer(mediumGap, 0),
        selectedSlot('Appearance', state.appearance),
      },
    },
  }

  return H3UI.build {
    component = 'window',
    role = 'root',
    args = {
      layer = 'Windows',
      title = 'Transmog',
      captionHeight = 24,
      closable = false,
      movable = false,
      resizable = false,
      position = UtilVector2(20, 80),
      size = UtilVector2(620, 650),
      children = {
        H3UI.build {
          component = 'row',
          role = 'body-inset',
          args = {
            props = { autoSize = false, relativeSize = UtilVector2(1, 1) },
            external = { grow = 1, stretch = 1 },
            children = {
              makeSpacer(outerGap, 0),
              H3UI.build {
                component = 'column',
                role = 'body',
                args = {
                  props = { arrange = ui.ALIGNMENT.Center, autoSize = false },
                  external = { grow = 1, stretch = 1 },
                  children = {
                    makeSpacer(0, outerGap),
                    selected,
                    makeSpacer(0, largeGap),
                    buildSearch(),
                    makeSpacer(0, largeGap),
                    buildInventory(),
                    makeSpacer(0, largeGap),
                    buildActions(),
                    makeSpacer(0, outerGap),
                  },
                },
              },
              makeSpacer(outerGap, 0),
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
