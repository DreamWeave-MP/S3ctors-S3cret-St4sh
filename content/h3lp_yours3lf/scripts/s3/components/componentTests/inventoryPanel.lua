---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local windowSize = UtilVector2(610, 390)
local slotSize = UtilVector2(58, 58)
local iconSize = UtilVector2(50, 50)
local gridSize = UtilVector2(300, 300)
local detailSize = UtilVector2(250, 300)
local meterSize = UtilVector2(220, 16)
local searchSize = UtilVector2(520, 24)

local itemData = {
  {
    name = 'Iron Longsword',
    count = 1,
    color = util.color.rgb(0.60, 0.60, 0.64),
    value = 40,
    weight = 20,
  },
  {
    name = 'Restore Health',
    count = 3,
    color = util.color.rgb(0.65, 0.16, 0.12),
    value = 35,
    weight = 0.5,
  },
  {
    name = 'Journeyman Lockpick',
    count = 8,
    color = util.color.rgb(0.72, 0.62, 0.24),
    value = 12,
    weight = 0.2,
  },
  {
    name = 'Common Robe',
    count = 1,
    color = util.color.rgb(0.28, 0.20, 0.52),
    value = 8,
    weight = 3,
  },
  {
    name = 'Frost Salts',
    count = 5,
    color = util.color.rgb(0.30, 0.72, 0.82),
    value = 75,
    weight = 0.1,
  },
  {
    name = 'Grand Soul Gem',
    count = 2,
    color = util.color.rgb(0.30, 0.48, 0.80),
    value = 200,
    weight = 2,
  },
  {
    name = 'Dwemer Coin',
    count = 31,
    color = util.color.rgb(0.66, 0.48, 0.18),
    value = 50,
    weight = 0.1,
  },
  {
    name = 'Scroll of Ondusi',
    count = 2,
    color = util.color.rgb(0.72, 0.66, 0.50),
    value = 67,
    weight = 0.2,
  },
  {
    name = 'Chitin Cuirass',
    count = 1,
    color = util.color.rgb(0.42, 0.31, 0.18),
    value = 120,
    weight = 15,
  },
  { name = 'Sujamma', count = 4, color = util.color.rgb(0.58, 0.20, 0.12), value = 30, weight = 1 },
  { name = 'Probe', count = 6, color = util.color.rgb(0.48, 0.48, 0.48), value = 9, weight = 0.2 },
  {
    name = 'Rising Force Potion',
    count = 2,
    color = util.color.rgb(0.18, 0.58, 0.34),
    value = 90,
    weight = 0.5,
  },
}

---@param invalidate? fun()
---@return openmw.ui.Layout
local function inventoryPanel(invalidate)
  local refresh = invalidate or function() end
  local ui = I.H3UI.scope { invalidate = invalidate }
  local name = ui.text { text = 'Iron Longsword', role = 'title' }
  local details = ui.text 'Weight 20    Value 40'
  local status = ui.text { text = 'Ready', tone = 'muted' }

  local items = {}
  for index = 1, #itemData do
    local item = itemData[index]
    items[index] = {
      resource = { path = 'white' },
      count = item.count,
      props = { size = slotSize },
      iconProps = { size = iconSize, color = item.color },
      onActivate = function()
        name.props.text = item.name
        details.props.text = ('Weight %s    Value %s'):format(
          tostring(item.weight),
          tostring(item.value)
        )
        status.props.text = 'Selected ' .. item.name
        refresh()
        return true
      end,
    }
  end

  local grid = ui.itemGrid {
    columns = 4,
    columnGap = 4,
    rowGap = 4,
    items = items,
  }

  return ui.window {
    name = 'ct_demo_inventory_panel',
    title = 'Inventory Pattern',
    size = windowSize,
    resizable = false,
    pinnable = true,
    children = {
      ui.column {
        gap = 6,
        ui.row {
          gap = 8,
          ui.box {
            props = { size = gridSize },
            children = { grid },
          },
          ui.box {
            props = { size = detailSize },
            children = {
              ui.column {
                gap = 8,
                name,
                ui.divider(),
                details,
                ui.text 'Condition',
                ui.meter { value = 72, max = 100, props = { size = meterSize } },
                ui.spacer { grow = 1 },
                ui.row {
                  gap = 6,
                  ui.button {
                    label = 'Equip',
                    tone = 'positive',
                    onActivate = function()
                      status.props.text = 'Equip requested'
                      refresh()
                      return true
                    end,
                  },
                  ui.button {
                    label = 'Drop',
                    tone = 'negative',
                    onActivate = function()
                      status.props.text = 'Drop requested'
                      refresh()
                      return true
                    end,
                  },
                },
              },
            },
          },
        },
        ui.row {
          gap = 6,
          ui.searchInput {
            value = '',
            inputProps = { size = searchSize },
            onChange = function(value)
              status.props.text = value == '' and 'Ready' or ('Filter: ' .. value)
              refresh()
            end,
          },
          status,
        },
      },
    },
  }
end

return inventoryPanel
