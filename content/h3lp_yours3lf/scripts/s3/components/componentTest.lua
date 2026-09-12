---@omw-context player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local bookFrame = require 'scripts.s3.components.bookFrame'
local box = require 'scripts.s3.components.box'
local button = require 'scripts.s3.components.button'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local grid = require 'scripts.s3.components.grid'
local iconButton = require 'scripts.s3.components.iconButton'
local image = require 'scripts.s3.components.image'
local itemSlot = require 'scripts.s3.components.itemSlot'
local list = require 'scripts.s3.components.list'
local listItem = require 'scripts.s3.components.listItem'
local meter = require 'scripts.s3.components.meter'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local select = require 'scripts.s3.components.select'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local textInput = require 'scripts.s3.components.textInput'
local toggle = require 'scripts.s3.components.toggle'
local tooltip = require 'scripts.s3.components.tooltip'
local widget = require 'scripts.s3.components.widget'
local window = require 'scripts.s3.components.window'

local v2 = util.vector2

local whiteTexture = constants.whiteTexture
local markerTexture = ui.texture { path = 'textures/menu_map_smark.dds' }
local leftArrowTexture = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local normalTextProps = {
  textColor = constants.normalColor,
  textSize = constants.textNormalSize,
}
local headerTextProps = {
  textColor = constants.headerColor,
  textSize = constants.textHeaderSize,
}

---@class H3ComponentTest.Options
---@field layer? string Root UI layer. Defaults to `Windows` for in-game console use.
---@field replace? boolean Destroy an existing owned root before creating a new one.
---@field position? openmw.util.Vector2 Optional root window position.
---@field size? openmw.util.Vector2 Optional root window size.

---@class openmw.interfaces.H3ComponentTest
---@field makeLayout fun(opts?: H3ComponentTest.Options): openmw.ui.Layout
---@field create fun(opts?: H3ComponentTest.Options): openmw.ui.Element
---@field destroy fun(): boolean
---@field toggle fun(opts?: H3ComponentTest.Options): boolean
---@field isOpen fun(): boolean

---@class openmw.interfaces
---@field H3ComponentTest? openmw.interfaces.H3ComponentTest

---@type openmw.ui.Element|nil
local rootElement = nil

local function isOpen() return rootElement ~= nil and rootElement.layout ~= nil end

local function destroy()
  if not isOpen() then
    rootElement = nil
    return false
  end
  rootElement:destroy()
  rootElement = nil
  return true
end

local function notify(label)
  if isOpen() then ui.showMessage('H3 component test: ' .. label) end
end

local function section(id, title, children)
  return box {
    name = 'ct_box_' .. id,
    children = {
      column {
        name = 'ct_column_' .. id,
        children = {
          text { name = 'ct_text_' .. id, text = title, props = headerTextProps },
          spacer { name = 'ct_spacer_' .. id, props = { size = v2(0, 4) } },
          column { name = 'ct_section_body_' .. id, children = children },
        },
      },
    },
  }
end

local function makeLayout(opts)
  opts = opts or {}

  local state = {
    expanded = true,
    number = 5,
    search = 'search',
    selected = 1,
    slider = 50,
    tabs = 1,
    toggle = true,
  }

  local function refresh()
    if isOpen() then rootElement:update() end
  end

  local root = window {
    name = 'ct_root_window',
    title = 'H3 Component Test',
    props = {
      position = opts.position or v2(80, 80),
      size = opts.size or v2(760, 720),
    },
    movable = true,
    resizable = true,
    closable = true,
    pinnable = true,
    onMove = function() refresh() end,
    onResize = function() refresh() end,
    onClose = function()
      notify 'window closed'
      async:newUnsavableSimulationTimer(0, destroy)
    end,
    onPin = function(pinned)
      notify('window pinned ' .. tostring(pinned))
      refresh()
    end,
    children = {
      column {
        name = 'ct_body_column',
        children = {
          row {
            name = 'ct_header_row',
            children = {
              image {
                name = 'ct_image_marker',
                resource = markerTexture,
                props = { size = v2(20, 20) },
              },
              spacer { name = 'ct_header_gap', props = { size = v2(8, 0) } },
              text {
                name = 'ct_header_text',
                text = 'Manual player-context smoke layout for every H3 UI component.',
                props = normalTextProps,
              },
            },
          },

          spacer { name = 'ct_after_header_spacer', props = { size = v2(0, 8) } },

          section('primitives', 'Primitives', {
            row {
              name = 'ct_primitives_row',
              children = {
                widget {
                  name = 'ct_widget_swatch',
                  props = {
                    size = v2(24, 24),
                  },
                  children = {
                    image {
                      name = 'ct_widget_image_fill',
                      resource = whiteTexture,
                      props = {
                        relativeSize = v2(1, 1),
                        color = util.color.rgb(0.30, 0.42, 0.72),
                      },
                    },
                  },
                },
                spacer { name = 'ct_primitive_gap_a', props = { size = v2(8, 0) } },
                text {
                  name = 'ct_primitive_text',
                  text = 'widget + image + text',
                  props = normalTextProps,
                },
              },
            },
            textInput {
              name = 'ct_text_input',
              text = 'edit me',
              props = {
                size = v2(180, 24),
                textColor = constants.normalColor,
                textSize = constants.textNormalSize,
              },
              events = {
                textChanged = async:callback(function()
                  -- Deliberately no persistence; this just verifies callback plumbing.
                end),
                focusLoss = async:callback(function() notify 'text input focus lost' end),
              },
            },
          }),

          spacer { name = 'ct_mid_spacer_a', props = { size = v2(0, 8) } },

          section('actions', 'Actions and meters', {
            row {
              name = 'ct_actions_row',
              children = {
                button {
                  name = 'ct_button_notify',
                  label = 'Button',
                  labelProps = normalTextProps,
                  events = {
                    mouseClick = async:callback(function() notify 'button clicked' end),
                  },
                },
                spacer { name = 'ct_action_gap_a', props = { size = v2(8, 0) } },
                iconButton {
                  name = 'ct_icon_button_notify',
                  label = 'Icon',
                  resource = leftArrowTexture,
                  iconProps = { size = v2(14, 14) },
                  labelProps = normalTextProps,
                  events = {
                    mouseClick = async:callback(function() notify 'icon button clicked' end),
                  },
                },
                spacer { name = 'ct_action_gap_b', props = { size = v2(8, 0) } },
                meter {
                  name = 'ct_meter_demo',
                  value = 67,
                  max = 100,
                  props = { size = v2(150, 18) },
                  fillProps = { color = util.color.rgb(0.15, 0.65, 0.25) },
                  emptyProps = { color = util.color.rgb(0.18, 0.12, 0.12) },
                },
              },
            },
          }),

          spacer { name = 'ct_mid_spacer_interactive', props = { size = v2(0, 8) } },

          section('interactive', 'Interactive controls', {
            row {
              name = 'ct_interactive_row',
              children = {
                toggle {
                  name = 'ct_toggle',
                  value = state.toggle,
                  onChange = function(value)
                    state.toggle = value
                    notify('toggle changed to ' .. tostring(value))
                    refresh()
                  end,
                },
                spacer { name = 'ct_interactive_gap_a', props = { size = v2(8, 0) } },
                slider {
                  name = 'ct_slider',
                  value = state.slider,
                  min = 0,
                  max = 100,
                  step = 5,
                  props = { size = v2(160, 18) },
                  onChange = function(value)
                    state.slider = value
                    notify('slider changed to ' .. tostring(value))
                    refresh()
                  end,
                },
                spacer { name = 'ct_interactive_gap_b', props = { size = v2(8, 0) } },
                select {
                  name = 'ct_select',
                  items = { 'One', 'Two', 'Three' },
                  selected = state.selected,
                  onSelect = function(index)
                    state.selected = index
                    notify('selected item ' .. tostring(index))
                    refresh()
                  end,
                },
              },
            },
            tabs {
              name = 'ct_tabs',
              items = { 'First', 'Second', 'Third' },
              selected = state.tabs,
              onSelect = function(index)
                state.tabs = index
                notify('selected tab ' .. tostring(index))
                refresh()
              end,
            },
            collapsible {
              name = 'ct_collapsible',
              title = 'Details',
              expanded = state.expanded,
              onToggle = function(expanded)
                state.expanded = expanded
                notify('collapsible ' .. tostring(expanded))
                refresh()
              end,
              children = {
                text {
                  name = 'ct_collapsible_text',
                  text = 'Disclosure content.',
                  props = normalTextProps,
                },
              },
            },
            numberInput {
              name = 'ct_number_input',
              value = state.number,
              min = 0,
              max = 10,
              step = 1,
              integer = true,
              onChange = function(value)
                state.number = value
                notify('number input changed to ' .. tostring(value))
              end,
              onCommit = function() refresh() end,
            },
            searchInput {
              name = 'ct_search_input',
              value = state.search,
              onChange = function(value)
                state.search = value
                notify('search input changed to ' .. value)
                refresh()
              end,
            },
          }),

          spacer { name = 'ct_mid_spacer_b', props = { size = v2(0, 8) } },

          row {
            name = 'ct_lists_and_frames_row',
            children = {
              section('list', 'List', {
                list {
                  name = 'ct_list_demo',
                  items = {
                    listItem { name = 'ct_list_item_one', label = 'listItem one' },
                    listItem { name = 'ct_list_item_two', label = 'listItem two' },
                    listItem { name = 'ct_list_item_three', label = 'listItem three' },
                  },
                },
              }),
              spacer { name = 'ct_between_columns_gap', props = { size = v2(8, 0) } },
              section('grid', 'Grid and item slots', {
                grid {
                  name = 'ct_grid_demo',
                  columns = 3,
                  items = {
                    itemSlot {
                      name = 'ct_item_slot_one',
                      resource = markerTexture,
                      count = 1,
                      iconProps = { size = v2(28, 28) },
                    },
                    itemSlot {
                      name = 'ct_item_slot_two',
                      resource = whiteTexture,
                      count = 2,
                      iconProps = { size = v2(28, 28), color = util.color.rgb(0.72, 0.48, 0.18) },
                    },
                    itemSlot {
                      name = 'ct_item_slot_three',
                      resource = leftArrowTexture,
                      count = 3,
                      iconProps = { size = v2(28, 28) },
                    },
                  },
                },
              }),
            },
          },

          spacer { name = 'ct_mid_spacer_c', props = { size = v2(0, 8) } },

          bookFrame {
            name = 'ct_book_frame_demo',
            title = 'bookFrame + tooltip',
            children = {
              tooltip {
                name = 'ct_tooltip_demo',
                text = 'Tooltip layout demo; not cursor-attached in this test interface.',
              },
            },
          },

          spacer { name = 'ct_before_footer_spacer', props = { size = v2(0, 8) } },

          row {
            name = 'ct_footer_row',
            children = {
              spacer { name = 'ct_footer_grow', grow = 1 },
              button {
                name = 'ct_close_button',
                label = 'Destroy',
                events = {
                  mouseClick = async:callback(
                    function() async:newUnsavableSimulationTimer(0, destroy) end
                  ),
                },
              },
            },
          },
        },
      },
    },
  }
  root.layer = opts.layer or 'Windows'
  return root
end

local function create(opts)
  opts = opts or {}
  if isOpen() then
    if opts.replace ~= true then return rootElement end
    destroy()
  end
  rootElement = ui.create(makeLayout(opts))
  return rootElement
end

local function toggle(opts)
  if isOpen() then
    destroy()
    return false
  end
  create(opts)
  return true
end

---@type openmw.interfaces.H3ComponentTest
local interface = {
  makeLayout = makeLayout,
  create = create,
  destroy = destroy,
  toggle = toggle,
  isOpen = isOpen,
}

return {
  interfaceName = 'H3ComponentTest',
  interface = interface,
}
