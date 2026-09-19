---@omw-context player

local I = require 'openmw.interfaces'
local openmwUi = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local fullSize = UtilVector2(1, 1)
local windowSize = UtilVector2(660, 380)
local slotSize = UtilVector2(58, 58)
local iconSize = UtilVector2(50, 50)
local gridSize = UtilVector2(252, 252)
local detailSize = UtilVector2(348, 252)
local meterSize = UtilVector2(290, 16)
local searchSize = UtilVector2(390, 24)
local relativeWidth = UtilVector2(1, 0)

local categories = { 'All', 'Weapon', 'Apparel', 'Magic', 'Misc' }

local itemData = {
  {
    name = 'Iron Longsword',
    category = 'Weapon',
    count = 1,
    color = util.color.rgb(0.60, 0.60, 0.64),
    value = 40,
    weight = 20,
    condition = 72,
    maxCondition = 100,
  },
  {
    name = 'Restore Health',
    category = 'Magic',
    count = 3,
    color = util.color.rgb(0.65, 0.16, 0.12),
    value = 35,
    weight = 0.5,
  },
  {
    name = 'Journeyman Lockpick',
    category = 'Misc',
    count = 8,
    color = util.color.rgb(0.72, 0.62, 0.24),
    value = 12,
    weight = 0.2,
  },
  {
    name = 'Common Robe',
    category = 'Apparel',
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
    category = 'Misc',
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
    category = 'Apparel',
    count = 1,
    color = util.color.rgb(0.42, 0.31, 0.18),
    value = 120,
    weight = 15,
    condition = 180,
    maxCondition = 200,
  },
  {
    name = 'Sujamma',
    category = 'Magic',
    count = 4,
    color = util.color.rgb(0.58, 0.20, 0.12),
    value = 30,
    weight = 1,
  },
  {
    name = 'Probe',
    category = 'Misc',
    count = 6,
    color = util.color.rgb(0.48, 0.48, 0.48),
    value = 9,
    weight = 0.2,
  },
  {
    name = 'Rising Force Potion',
    category = 'Magic',
    count = 2,
    color = util.color.rgb(0.18, 0.58, 0.34),
    value = 90,
    weight = 0.5,
  },
  {
    name = 'Steel Dagger',
    category = 'Weapon',
    count = 1,
    color = util.color.rgb(0.35, 0.37, 0.42),
    value = 16,
    weight = 4,
  },
  {
    name = 'Leather Boots',
    category = 'Apparel',
    count = 1,
    color = util.color.rgb(0.30, 0.20, 0.10),
    value = 5,
    weight = 4,
    condition = 25,
    maxCondition = 30,
  },
  {
    name = 'Cure Poison',
    category = 'Magic',
    count = 2,
    color = util.color.rgb(0.55, 0.80, 0.45),
    value = 20,
    weight = 0.5,
  },
  {
    name = 'Torch',
    category = 'Misc',
    count = 3,
    color = util.color.rgb(0.80, 0.45, 0.15),
    value = 3,
    weight = 1,
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

---@param invalidate? fun()
---@param rebuild? fun()
---@param state? table
---@return openmw.ui.Layout
local function inventoryPanel(invalidate, rebuild, state)
  rebuild = rebuild or function() end
  state = state or {}
  initializeState(state)

  local shellUi = I.H3UI.scope { invalidate = invalidate }

  local gridElement
  local gridUi = shellUi.child {
    element = function() return gridElement end,
  }
  local detailElement
  local detailUi = shellUi.child {
    element = function() return detailElement end,
  }

  local selectItem
  local refilter
  local buildFooter
  local tabsRow
  local gridBox
  local detailBox
  local footerRow

  local function currentSelection()
    local selected = findItem(state.selected)
    local fresh = visibleItems(state)
    local selectedVisible = false
    for index = 1, #fresh do
      if fresh[index] == selected then
        selectedVisible = true
        break
      end
    end
    if not selectedVisible then
      selected = fresh[1]
      state.selected = selected and selected.name or nil
    end
    return selected
  end

  local function buildItems()
    local result = {}
    local fresh = visibleItems(state)
    for index = 1, #fresh do
      local item = fresh[index]
      result[#result + 1] = {
        resource = { path = 'white' },
        count = state.counts[item.name],
        selected = state.selected == item.name,
        props = { size = slotSize },
        iconProps = { size = iconSize, color = item.color },
        onActivate = function()
          selectItem(item.name)
          return true
        end,
      }
    end
    return result
  end

  local function buildGrid()
    return gridUi.itemGrid {
      columns = 4,
      columnGap = 4,
      rowGap = 4,
      props = {
        autoSize = false,
        relativeSize = fullSize,
      },
      items = buildItems(),
    }
  end

  local function detailPanel()
    local selected = currentSelection()
    if selected == nil then
      return detailUi.column {
        gap = 8,
        props = { relativeSize = relativeWidth },
        detailUi.text { text = 'No matching items', role = 'title' },
        detailUi.divider(),
        detailUi.text {
          text = 'Change the category or search filter to bring inventory items back into view.',
          tone = 'muted',
        },
      }
    end

    local children = {
      detailUi.section {
        title = selected.name,
        secondary = selected.category,
        gap = 4,
        statRow(detailUi, 'Weight', selected.weight),
        statRow(detailUi, 'Value', selected.value),
      },
    }

    if selected.condition ~= nil then
      children[#children + 1] = detailUi.text 'Condition'
      children[#children + 1] = detailUi.meter {
        value = selected.condition,
        max = selected.maxCondition,
        props = { size = meterSize },
      }
    end

    if state.equipped[selected.name] then
      children[#children + 1] = detailUi.text { text = 'Equipped', tone = 'positive' }
    end

    children[#children + 1] = detailUi.spacer { grow = 1 }
    children[#children + 1] = detailUi.row {
      gap = 6,
      detailUi.button {
        label = state.equipped[selected.name] and 'Unequip' or 'Equip',
        tone = state.equipped[selected.name] and 'link' or 'positive',
        onActivate = function()
          state.equipped[selected.name] = not state.equipped[selected.name]
          detailUi.setChildren(detailBox, { detailPanel() })
          return true
        end,
      },
      detailUi.button {
        label = 'Drop',
        tone = 'negative',
        onActivate = function()
          local count = state.counts[selected.name] or 0
          if count > 0 then state.counts[selected.name] = count - 1 end
          if state.counts[selected.name] <= 0 then
            state.selected = nil
            state.equipped[selected.name] = nil
          end
          gridUi.setChildren(gridBox, { buildGrid() })
          detailUi.setChildren(detailBox, { detailPanel() })
          shellUi.setChildren(footerRow, buildFooter())
          return true
        end,
      },
    }

    return detailUi.column {
      gap = 8,
      props = { autoSize = false, relativeSize = fullSize },
      children = children,
    }
  end

  function buildFooter()
    return {
      shellUi.searchInput {
        value = state.query,
        inputProps = { size = searchSize },
        onChange = function(value)
          state.query = value
          refilter()
        end,
      },
      shellUi.spacer { grow = 1 },
      shellUi.text(('Carry %.1f / 300'):format(carryWeight(state))),
      shellUi.text 'Gold 1,247',
    }
  end

  local function buildCategoryButtons()
    local buttons = {}
    for index = 1, #categories do
      local category = categories[index]
      buttons[index] = shellUi.button {
        label = category,
        tone = state.category == category and 'link' or nil,
        onActivate = function()
          state.category = category
          shellUi.setChildren(tabsRow, buildCategoryButtons())
          gridUi.setChildren(gridBox, { buildGrid() })
          detailUi.setChildren(detailBox, { detailPanel() })
          return true
        end,
      }
    end
    return buttons
  end

  function selectItem(name)
    state.selected = name
    gridUi.setChildren(gridBox, { buildGrid() })
    detailUi.setChildren(detailBox, { detailPanel() })
  end

  function refilter()
    gridUi.setChildren(gridBox, { buildGrid() })
    detailUi.setChildren(detailBox, { detailPanel() })
  end

  tabsRow = shellUi.row {
    gap = 4,
    children = buildCategoryButtons(),
  }

  gridBox = gridUi.box {
    props = { size = gridSize },
    children = { buildGrid() },
  }
  gridElement = openmwUi.create(gridBox)

  detailBox = detailUi.box {
    props = { size = detailSize },
    children = { detailPanel() },
  }
  detailElement = openmwUi.create(detailBox)

  footerRow = shellUi.row {
    gap = 8,
    children = buildFooter(),
  }

  return shellUi.window {
    name = 'ct_demo_inventory_panel',
    title = 'Inventory Pattern',
    size = windowSize,
    resizable = false,
    pinnable = true,
    children = {
      shellUi.column {
        gap = 6,
        props = { autoSize = false, relativeSize = fullSize },
        tabsRow,
        shellUi.row {
          gap = 8,
          gridElement,
          detailElement,
        },
        shellUi.spacer { grow = 1 },
        footerRow,
      },
    },
  }
end

return inventoryPanel
