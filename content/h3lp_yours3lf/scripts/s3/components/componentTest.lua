---@omw-context player

local emptyOptions = {}

local async = require 'openmw.async'
local auxUi = require 'openmw_aux.ui'
local input = require 'openmw.input'
local omwDebug = require 'openmw.debug'
local storage = require 'openmw.storage'
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
local selector = require 'scripts.s3.components.selector'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local textInput = require 'scripts.s3.components.textInput'
local toggle = require 'scripts.s3.components.toggle'
local tooltip = require 'scripts.s3.components.tooltip'
local widget = require 'scripts.s3.components.widget'
local window = require 'scripts.s3.components.window'

local applicationForm = require 'scripts.s3.components.componentTests.applicationForm'
local boundaries = require 'scripts.s3.components.componentTests.boundaries'
local controlStates = require 'scripts.s3.components.componentTests.controlStates'
local dense = require 'scripts.s3.components.componentTests.dense'
local eventComposition = require 'scripts.s3.components.componentTests.eventComposition'
local h3ui = require 'scripts.s3.components.componentTests.h3ui'
local longLabels = require 'scripts.s3.components.componentTests.longLabels'
local nesting = require 'scripts.s3.components.componentTests.nesting'
local relativeSizing = require 'scripts.s3.components.componentTests.relativeSizing'
local windowGeometry = require 'scripts.s3.components.componentTests.windowGeometry'

local UtilVector2 = util.vector2
local debugSettings = storage.playerSection 'SettingsPlayerH3UI'

local sectionGapSize = UtilVector2(0, 4)
local horizontalGapSize = UtilVector2(8, 0)
local verticalGapSize = UtilVector2(0, 8)
local fullSize = UtilVector2(1, 1)
local markerSize = UtilVector2(20, 20)
local swatchSize = UtilVector2(24, 24)
local textInputSize = UtilVector2(180, 24)
local smallIconSize = UtilVector2(14, 14)
local meterSize = UtilVector2(150, 18)
local sliderSize = UtilVector2(160, 18)
local itemIconSize = UtilVector2(72, 72)
local defaultPosition = UtilVector2(80, 80)
local defaultSize = UtilVector2(760, 720)

local swatchColor = util.color.rgb(0.30, 0.42, 0.72)
local meterFillColor = util.color.rgb(0.15, 0.65, 0.25)
local meterEmptyColor = util.color.rgb(0.18, 0.12, 0.12)
local red = util.color.rgb(1, 0, 0)
local green = util.color.rgb(0, 1, 0)
local blue = util.color.rgb(0, 0, 1)

local selectItems = { 'One', 'Two', 'Three' }
local tabItems = { 'First', 'Second', 'Third' }
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
---@field shell? 'window'|'box' Use a plain box shell instead of the interactive test window.

---@alias H3ComponentTest.DemoName
---| 'applicationForm'
---| 'boundaries'
---| 'controlStates'
---| 'dense'
---| 'eventComposition'
---| 'longLabels'
---| 'nesting'
---| 'relativeSizing'
---| 'h3ui'
---| 'windowGeometry'

---@class openmw.interfaces.H3ComponentTest
---@field makeLayout fun(options?: H3ComponentTest.Options): openmw.ui.Layout
---@field create fun(options?: H3ComponentTest.Options): openmw.ui.Element
---@field createDemo fun(name: H3ComponentTest.DemoName, options?: H3ComponentTest.Options): openmw.ui.Element
---@field destroy fun(): boolean
---@field toggle fun(options?: H3ComponentTest.Options): boolean
---@field isOpen fun(): boolean
---@field refresh fun()
---@field applicationForm fun(): openmw.ui.Layout
---@field boundaries fun(): openmw.ui.Layout
---@field controlStates fun(): openmw.ui.Layout
---@field dense fun(): openmw.ui.Layout
---@field eventComposition fun(): openmw.ui.Layout
---@field longLabels fun(): openmw.ui.Layout
---@field nesting fun(): openmw.ui.Layout
---@field relativeSizing fun(): openmw.ui.Layout
---@field h3ui fun(invalidate?: fun()): openmw.ui.Layout
---@field windowGeometry fun(): openmw.ui.Layout

---@class openmw.interfaces
---@field H3ComponentTest? openmw.interfaces.H3ComponentTest

---@type openmw.ui.Element|nil
local rootElement
---@type openmw.ui.Element|nil
local bodyElement
---@type fun(element: openmw.ui.Element)|nil
local elementUpdate
local rootDirty = false
local bodyDirty = false

local demoConstructors = {
  applicationForm = applicationForm,
  boundaries = boundaries,
  controlStates = controlStates,
  dense = dense,
  eventComposition = eventComposition,
  longLabels = longLabels,
  nesting = nesting,
  relativeSizing = relativeSizing,
  h3ui = h3ui,
  windowGeometry = windowGeometry,
}
local demoNames = {
  'applicationForm',
  'boundaries',
  'controlStates',
  'dense',
  'eventComposition',
  'longLabels',
  'nesting',
  'relativeSizing',
  'h3ui',
  'windowGeometry',
}
local currentDemoIndex = 0

local function isOpen() return rootElement ~= nil and rootElement.layout ~= nil end

local function destroy()
  local wasOpen = isOpen()
  local currentRoot = rootElement
  local currentBody = bodyElement

  rootElement = nil
  rootDirty = false
  bodyElement = nil
  bodyDirty = false

  if currentRoot and currentRoot.layout then
    auxUi.deepDestroy(currentRoot)
  elseif currentBody and currentBody.layout then
    auxUi.deepDestroy(currentBody)
  end

  return wasOpen
end

local function notify(label)
  if isOpen() then ui.showMessage('H3 component test: ' .. label) end
end

local function updateElement(element)
  if not elementUpdate then elementUpdate = element.update end
  elementUpdate(element)
end

local function refreshRoot() rootDirty = true end

local function refreshBody()
  if bodyElement and bodyElement.layout then
    bodyDirty = true
  else
    rootDirty = true
  end
end

local function flushUpdates()
  if rootDirty then
    rootDirty = false
    local element = rootElement
    if element and element.layout then updateElement(element) end
  end

  if bodyDirty then
    bodyDirty = false
    local element = bodyElement
    if element and element.layout then updateElement(element) end
  end
end

local function section(id, title, children)
  return box {
    name = 'ct_box_' .. id,
    children = {
      column {
        name = 'ct_column_' .. id,
        children = {
          text { name = 'ct_text_' .. id, text = title, props = headerTextProps },
          spacer { name = 'ct_spacer_' .. id, props = { size = sectionGapSize } },
          column { name = 'ct_section_body_' .. id, children = children },
        },
      },
    },
  }
end

local function newState()
  return {
    expanded = true,
    number = 5,
    search = 'search',
    selected = 1,
    slider = 50,
    tabs = 1,
    toggle = true,
  }
end

local function makeBodyLayout(state)
  return column {
    name = 'ct_body_column',
    children = {
      row {
        name = 'ct_header_row',
        children = {
          image {
            name = 'ct_image_marker',
            resource = { path = 'textures/menu_map_smark.dds' },
            props = { size = markerSize },
          },
          spacer { name = 'ct_header_gap', props = { size = horizontalGapSize } },
          text {
            name = 'ct_header_text',
            text = 'Manual player-context smoke layout for every H3 UI component.',
            props = normalTextProps,
          },
        },
      },

      spacer { name = 'ct_after_header_spacer', props = { size = verticalGapSize } },

      section('primitives', 'Primitives', {
        row {
          name = 'ct_primitives_row',
          children = {
            widget {
              name = 'ct_widget_swatch',
              props = {
                size = swatchSize,
              },
              children = {
                image {
                  name = 'ct_widget_image_fill',
                  resource = { path = 'white' },
                  props = {
                    relativeSize = fullSize,
                    color = swatchColor,
                  },
                },
              },
            },
            spacer { name = 'ct_primitive_gap_a', props = { size = horizontalGapSize } },
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
            size = textInputSize,
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

      spacer { name = 'ct_mid_spacer_a', props = { size = verticalGapSize } },

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
            spacer { name = 'ct_action_gap_a', props = { size = horizontalGapSize } },
            iconButton {
              name = 'ct_icon_button_notify',
              label = 'Icon',
              resource = { path = 'textures/omw_menu_scroll_left.dds' },
              iconProps = { size = smallIconSize },
              labelProps = normalTextProps,
              events = {
                mouseClick = async:callback(function() notify 'icon button clicked' end),
              },
            },
            spacer { name = 'ct_action_gap_b', props = { size = horizontalGapSize } },
            meter {
              name = 'ct_meter_demo',
              value = 67,
              max = 100,
              props = { size = meterSize },
              fillProps = { color = meterFillColor },
              emptyProps = { color = meterEmptyColor },
            },
          },
        },
      }),

      spacer { name = 'ct_mid_spacer_interactive', props = { size = verticalGapSize } },

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
                refreshBody()
              end,
            },
            spacer {
              name = 'ct_interactive_gap_a',
              props = { size = horizontalGapSize },
            },
            slider {
              name = 'ct_slider',
              value = state.slider,
              min = 0,
              max = 100,
              step = 5,
              props = { size = sliderSize },
              onChange = function(value)
                state.slider = value
                notify('slider changed to ' .. tostring(value))
                refreshBody()
              end,
            },
            spacer {
              name = 'ct_interactive_gap_b',
              props = { size = horizontalGapSize },
            },
            selector {
              name = 'ct_select',
              items = selectItems,
              selected = state.selected,
              onSelect = function(index)
                state.selected = index
                notify('selected item ' .. tostring(index))
                refreshBody()
              end,
            },
          },
        },
        tabs {
          name = 'ct_tabs',
          items = tabItems,
          selected = state.tabs,
          onSelect = function(index)
            state.tabs = index
            notify('selected tab ' .. tostring(index))
            refreshBody()
          end,
        },
        collapsible {
          name = 'ct_collapsible',
          title = 'Details',
          expanded = state.expanded,
          onToggle = function(expanded)
            state.expanded = expanded
            notify('collapsible ' .. tostring(expanded))
            refreshBody()
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
          onCommit = refreshBody,
        },
        searchInput {
          name = 'ct_search_input',
          value = state.search,
          onChange = function(value)
            state.search = value
            notify('search input changed to ' .. value)
            refreshBody()
          end,
        },
      }),

      spacer { name = 'ct_mid_spacer_b', props = { size = verticalGapSize } },

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
          spacer { name = 'ct_between_columns_gap', props = { size = horizontalGapSize } },
          section('grid', 'Grid and item slots', {
            grid {
              name = 'ct_grid_demo',
              columns = 3,
              items = {
                itemSlot {
                  name = 'ct_item_slot_one',
                  resource = { path = 'white' },
                  count = 1,
                  iconProps = { size = itemIconSize, color = red },
                },
                itemSlot {
                  name = 'ct_item_slot_two',
                  resource = { path = 'white' },
                  count = 2,
                  iconProps = { size = itemIconSize, color = green },
                },
                itemSlot {
                  name = 'ct_item_slot_three',
                  resource = { path = 'white' },
                  count = 3,
                  iconProps = { size = itemIconSize, color = blue },
                },
              },
            },
          }),
        },
      },

      spacer { name = 'ct_mid_spacer_c', props = { size = verticalGapSize } },

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

      spacer { name = 'ct_before_footer_spacer', props = { size = verticalGapSize } },

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
  }
end

local function makeWindowLayout(options, body, title)
  -- The body is a child Element in create(); keep live resize updates on the window shell.
  local resizeDirty = false

  local function finishResize()
    if not resizeDirty then return end
    resizeDirty = false
    refreshBody()
  end

  local root = window {
    name = 'ct_root_window',
    title = title or 'H3 Component Test',
    props = {
      position = options.position or defaultPosition,
      size = options.size or defaultSize,
    },
    movable = true,
    resizable = true,
    closable = true,
    pinnable = true,
    onMove = refreshRoot,
    onResize = function()
      resizeDirty = true
      refreshRoot()
    end,
    onClose = function()
      notify 'window closed'
      async:newUnsavableSimulationTimer(0, destroy)
    end,
    onPin = function(pinned)
      notify('window pinned ' .. tostring(pinned))
      refreshRoot()
    end,
    events = {
      mouseRelease = async:callback(finishResize),
      focusLoss = async:callback(finishResize),
    },
    children = { body },
  }

  root.layer = options.layer or 'Windows'
  return root
end

local function makePlainShellLayout(options, body)
  local root = box {
    name = 'ct_plain_shell',
    props = {
      position = options.position or defaultPosition,
      size = options.size or defaultSize,
    },
    children = { body },
  }

  root.layer = options.layer or 'Windows'
  return root
end

local function makeShellLayout(options, body, title)
  if options.shell == 'box' then return makePlainShellLayout(options, body) end
  return makeWindowLayout(options, body, title)
end

local function makeLayout(options)
  options = options or emptyOptions
  return makeShellLayout(options, makeBodyLayout(newState()))
end

local function createBody(options, body, title)
  if isOpen() then
    if options.replace ~= true then return rootElement end
    destroy()
  end

  -- Element:update() does not lay out child Elements, so this keeps drag/resize off the heavy test tree.
  bodyElement = ui.create(body, { noWarnUnused = true })
  rootElement = ui.create(makeShellLayout(options, bodyElement, title))
  return rootElement
end

local function create(options)
  options = options or emptyOptions
  return createBody(options, makeBodyLayout(newState()))
end

local function createDemo(name, options)
  local constructor = demoConstructors[name]
  assert(constructor, 'Unknown H3 component demo: ' .. tostring(name))

  options = options or emptyOptions
  local invalidate
  if name == 'h3ui' then invalidate = refreshBody end
  local body = column {
    name = 'ct_demo_body',
    children = { constructor(invalidate) },
  }
  return createBody(options, body, 'H3 Component Test: ' .. name)
end

local function cycleDemo()
  currentDemoIndex = currentDemoIndex % #demoNames + 1
  createDemo(demoNames[currentDemoIndex], { replace = true })
end

local function onKeyPress(key)
  if debugSettings:get 'enableDebugHotkeys' ~= true then return end
  if key.code ~= input.KEY.F7 then return end
  if key.withShift then
    omwDebug.reloadLua()
    return
  end

  cycleDemo()
end

local function toggle(options)
  if isOpen() then
    destroy()
    return false
  end

  create(options)
  return true
end

---@type openmw.interfaces.H3ComponentTest
local interface = {
  makeLayout = makeLayout,
  create = create,
  createDemo = createDemo,
  destroy = destroy,
  toggle = toggle,
  isOpen = isOpen,
  refresh = refreshBody,
  applicationForm = applicationForm,
  boundaries = boundaries,
  controlStates = controlStates,
  dense = dense,
  eventComposition = eventComposition,
  longLabels = longLabels,
  nesting = nesting,
  relativeSizing = relativeSizing,
  h3ui = h3ui,
  windowGeometry = windowGeometry,
}

return {
  interfaceName = 'H3ComponentTest',
  interface = interface,
  engineHandlers = {
    onFrame = flushUpdates,
    onKeyPress = onKeyPress,
  },
}
