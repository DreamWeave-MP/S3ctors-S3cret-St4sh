---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local windowSize = UtilVector2(660, 320)
local slotSize = UtilVector2(58, 58)
local iconSize = UtilVector2(50, 50)
local gridSize = UtilVector2(270, 214)
local detailSize = UtilVector2(330, 214)
local meterSize = UtilVector2(290, 16)
local searchSize = UtilVector2(390, 24)
local relativeWidth = UtilVector2(1, 0)

local categories = { 'All', 'Gear', 'Magic', 'Consumables', 'Tools', 'Misc' }

local itemData = {
  {
    name = 'Iron Longsword',
    category = 'Gear',
    count = 1,
    color = util.color.rgb(0.60, 0.60, 0.64),
    value = 40,
    weight = 20,
    condition = 72,
    maxCondition = 100,
  },
  {
    name = 'Restore Health',
    category = 'Consumables',
    count = 3,
    color = util.color.rgb(0.65, 0.16, 0.12),
    value = 35,
    weight = 0.5,
  },
  {
    name = 'Journeyman Lockpick',
    category = 'Tools',
    count = 8,
    color = util.color.rgb(0.72, 0.62, 0.24),
    value = 12,
    weight = 0.2,
  },
  {
    name = 'Common Robe',
    category = 'Gear',
    count = 1,
    color = util.color.rgb(0.28, 0.20, 0.52),
    value = 8,
    weight = 3,
    condition = 42,
    maxCondition = 50,
  },
  {
    name = 'Frost Salts',
    category = 'Magic',
    count = 5,
    color = util.color.rgb(0.30, 0.72, 0.82),
    value = 75,
    weight = 0.1,
  },
  {
    name = 'Grand Soul Gem',
    category = 'Magic',
    count = 2,
    color = util.color.rgb(0.30, 0.48, 0.80),
    value = 200,
    weight = 2,
  },
  {
    name = 'Dwemer Coin',
    category = 'Misc',
    count = 31,
    color = util.color.rgb(0.66, 0.48, 0.18),
    value = 50,
    weight = 0.1,
  },
  {
    name = 'Scroll of Ondusi',
    category = 'Magic',
    count = 2,
    color = util.color.rgb(0.72, 0.66, 0.50),
    value = 67,
    weight = 0.2,
  },
  {
    name = 'Chitin Cuirass',
    category = 'Gear',
    count = 1,
    color = util.color.rgb(0.42, 0.31, 0.18),
    value = 120,
    weight = 15,
    condition = 180,
    maxCondition = 200,
  },
  {
    name = 'Sujamma',
    category = 'Consumables',
    count = 4,
    color = util.color.rgb(0.58, 0.20, 0.12),
    value = 30,
    weight = 1,
  },
  {
    name = 'Probe',
    category = 'Tools',
    count = 6,
    color = util.color.rgb(0.48, 0.48, 0.48),
    value = 9,
    weight = 0.2,
  },
  {
    name = 'Rising Force Potion',
    category = 'Consumables',
    count = 2,
    color = util.color.rgb(0.18, 0.58, 0.34),
    value = 90,
    weight = 0.5,
  },
}

local function initializeState(state)
  state.category = state.category or 'All'
  state.query = state.query or ''
  state.equipped = state.equipped or {}
  if state.counts then return end

  state.counts = {}
  for index = 1, #itemData do
    local item = itemData[index]
    state.counts[item.name] = item.count
  end
end

local function visibleItems(state)
  local result = {}
  local query = string.lower(state.query)
  for index = 1, #itemData do
    local item = itemData[index]
    local count = state.counts[item.name] or 0
    local categoryMatches = state.category == 'All' or item.category == state.category
    local queryMatches = query == '' or string.find(string.lower(item.name), query, 1, true)
    if count > 0 and categoryMatches and queryMatches then result[#result + 1] = item end
  end
  return result
end

local function findItem(name)
  if name == nil then return nil end
  for index = 1, #itemData do
    if itemData[index].name == name then return itemData[index] end
  end
end

local function carryWeight(state)
  local total = 0
  for index = 1, #itemData do
    local item = itemData[index]
    total = total + item.weight * (state.counts[item.name] or 0)
  end
  return total
end

local function statRow(ui, label, value)
  return ui.row {
    external = { stretch = 1 },
    ui.text(label),
    ui.spacer { grow = 1 },
    ui.text(tostring(value)),
  }
end

local function detailPanel(ui, rebuild, state, selected)
  if selected == nil then
    return ui.column {
      gap = 8,
      props = { relativeSize = relativeWidth },
      ui.text { text = 'No matching items', role = 'title' },
      ui.divider(),
      ui.text {
        text = 'Change the category or search filter to bring inventory items back into view.',
        tone = 'muted',
      },
    }
  end

  local children = {
    ui.section {
      title = selected.name,
      secondary = selected.category,
      gap = 4,
      statRow(ui, 'Weight', selected.weight),
      statRow(ui, 'Value', selected.value),
    },
  }

  if selected.condition ~= nil then
    children[#children + 1] = ui.text 'Condition'
    children[#children + 1] = ui.meter {
      value = selected.condition,
      max = selected.maxCondition,
      props = { size = meterSize },
    }
  end

  if state.equipped[selected.name] then
    children[#children + 1] = ui.text { text = 'Equipped', tone = 'positive' }
  end

  children[#children + 1] = ui.spacer { grow = 1 }
  children[#children + 1] = ui.row {
    gap = 6,
    ui.button {
      label = state.equipped[selected.name] and 'Unequip' or 'Equip',
      tone = state.equipped[selected.name] and 'link' or 'positive',
      onActivate = function()
        state.equipped[selected.name] = not state.equipped[selected.name]
        rebuild()
        return true
      end,
    },
    ui.button {
      label = 'Drop',
      tone = 'negative',
      onActivate = function()
        local count = state.counts[selected.name] or 0
        if count > 0 then state.counts[selected.name] = count - 1 end
        if state.counts[selected.name] <= 0 then
          state.selected = nil
          state.equipped[selected.name] = nil
        end
        rebuild()
        return true
      end,
    },
  }

  return ui.column {
    gap = 8,
    props = { relativeSize = relativeWidth },
    children = children,
  }
end

---@param invalidate? fun()
---@param rebuild? fun()
---@param state? table
---@return openmw.ui.Layout
local function inventoryPanel(invalidate, rebuild, state)
  local refresh = invalidate or function() end
  rebuild = rebuild or refresh
  state = state or {}
  initializeState(state)

  local ui = I.H3UI.scope { invalidate = invalidate }
  local visible = visibleItems(state)

  local selected = findItem(state.selected)
  local selectedVisible = false
  for index = 1, #visible do
    if visible[index] == selected then
      selectedVisible = true
      break
    end
  end
  if not selectedVisible then
    selected = visible[1]
    state.selected = selected and selected.name or nil
  end

  local items = {}
  for index = 1, #visible do
    local item = visible[index]
    items[index] = {
      resource = { path = 'white' },
      count = state.counts[item.name],
      selected = state.selected == item.name,
      props = { size = slotSize },
      iconProps = { size = iconSize, color = item.color },
      onActivate = function()
        state.selected = item.name
        rebuild()
        return true
      end,
    }
  end

  local categoryButtons = {}
  for index = 1, #categories do
    local category = categories[index]
    categoryButtons[index] = ui.button {
      label = category,
      tone = state.category == category and 'link' or nil,
      onActivate = function()
        state.category = category
        rebuild()
        return true
      end,
    }
  end

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
          gap = 4,
          children = categoryButtons,
        },
        ui.row {
          gap = 8,
          ui.box {
            props = { size = gridSize },
            children = {
              ui.itemGrid {
                columns = 4,
                columnGap = 4,
                rowGap = 4,
                items = items,
              },
            },
          },
          ui.box {
            props = { size = detailSize },
            children = { detailPanel(ui, rebuild, state, selected) },
          },
        },
        ui.row {
          gap = 8,
          ui.searchInput {
            value = state.query,
            inputProps = { size = searchSize },
            onChange = function(value)
              state.query = value
              rebuild()
            end,
          },
          ui.spacer { grow = 1 },
          ui.text(('Carry %.1f / 300'):format(carryWeight(state))),
          ui.text 'Gold 1,247',
        },
      },
    },
  }
end

return inventoryPanel
