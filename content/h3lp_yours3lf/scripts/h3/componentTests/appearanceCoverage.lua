---@omw-context player
---@module 'scripts.h3.componentTests.appearanceCoverage'

local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local bookFrame = require 'scripts.h3.components.bookFrame'
local box = require 'scripts.h3.components.box'
local button = require 'scripts.h3.components.button'
local chrome = require 'scripts.h3.ui.chrome'
local collapsible = require 'scripts.h3.components.collapsible'
local column = require 'scripts.h3.components.column'
local headBlock = require 'scripts.h3.components.headBlock'
local iconButton = require 'scripts.h3.components.iconButton'
local image = require 'scripts.h3.components.image'
local itemSlot = require 'scripts.h3.components.itemSlot'
local listItem = require 'scripts.h3.components.listItem'
local meter = require 'scripts.h3.components.meter'
local pinButton = require 'scripts.h3.components.pinButton'
local row = require 'scripts.h3.components.row'
local searchInput = require 'scripts.h3.components.searchInput'
local selector = require 'scripts.h3.components.selector'
local spacer = require 'scripts.h3.components.spacer'
local surface = require 'scripts.h3.ui.surface'
local tabs = require 'scripts.h3.components.tabs'
local text = require 'scripts.h3.components.text'
local textInput = require 'scripts.h3.components.textInput'
local toggle = require 'scripts.h3.components.toggle'
local tooltip = require 'scripts.h3.components.tooltip'
local window = require 'scripts.h3.components.window'

local StrFormat = string.format

local ColorRGB, UtilVector2 = util.color.rgb, util.vector2
local Lime, Magenta = ColorRGB(0, 1, 0), ColorRGB(1, 0, 1)

local EntryGap, ColumnGap, ControlSize, FrameSize, HeadBlockSize, ItemSize =
  UtilVector2(0, 4),
  UtilVector2(12, 0),
  UtilVector2(180, 24),
  UtilVector2(180, 54),
  UtilVector2(180, 20),
  UtilVector2(48, 48)
local ToggleValue = true

---@param color openmw.util.Color
---@return table
local function labelProps(color)
  return { textColor = color, textSize = appearance.token 'textSize.normal' }
end

---@param name string
---@param role string
---@param component openmw.ui.Layout
---@return openmw.ui.Layout
local function entry(name, role, component)
  return column {
    children = {
      text {
        text = StrFormat('%s [%s]', name, role),
        props = labelProps(Magenta),
      },
      spacer { props = { size = EntryGap } },
      component,
      spacer { props = { size = EntryGap } },
    },
  }
end

---@param invalidate? fun(): nil
---@return openmw.ui.Layout
local function coverage(invalidate)
  local refresh = invalidate or
    ---@return nil
    function() end

  return column {
    name = 'ct_demo_appearance_coverage',
    children = {
      text {
        text = 'Appearance coverage: use a loud custom palette and chrome color; legacy gold should be obvious.',
        props = labelProps(Magenta),
      },

      spacer { props = { size = UtilVector2(0, 8) } },
      row {
        children = {
          entry('text', 'none', text { text = 'default text' }),
          spacer { props = { size = ColumnGap } },
          entry('button', 'frame.button', button { label = 'default button' }),
          spacer { props = { size = ColumnGap } },
          entry(
            'iconButton',
            'frame.button',
            iconButton {
              resource = chrome.texture(appearance.chrome 'scroll.left'),
              iconProps = { size = UtilVector2(16, 16) },
              label = 'icon',
            }
          ),
        },
      },

      row {
        children = {
          entry(
            'itemSlot',
            'frame.thin',
            itemSlot {
              resource = { path = 'white' },
              count = 7,
              props = { size = ItemSize },
              iconProps = { size = UtilVector2(40, 40) },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry('listItem', 'padding', listItem { label = 'default list item' }),
          spacer { props = { size = ColumnGap } },
          entry(
            'toggle',
            'frame.button',
            toggle {
              value = ToggleValue,
              ---@param value boolean
              ---@return nil
              onChange = function(value)
                ToggleValue = value
                refresh()
              end,
            }
          ),
        },
      },

      row {
        children = {
          entry(
            'selector',
            'frame.button',
            selector {
              items = { 'One', 'Two' },
              labelProps = { size = UtilVector2(72, 20) },
              onSelect = refresh,
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'tabs',
            'frame.button',
            tabs {
              items = { 'A', 'B' },
              onSelect = refresh,
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'collapsible',
            'frame.button',
            collapsible {
              title = 'Details',
              children = { text { text = 'default details' } },
              onToggle = refresh,
            }
          ),
        },
      },

      row {
        children = {
          entry('searchInput', 'frame.thin', searchInput { props = { size = ControlSize } }),
          spacer { props = { size = ColumnGap } },
          entry(
            'textInput',
            'H3 TextEdit',
            textInput { text = 'editable text', props = { size = ControlSize } }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'meter',
            'frame.thin',
            meter {
              value = 65,
              max = 100,
              props = { size = ControlSize },
            }
          ),
        },
      },

      row {
        children = {
          entry('tooltip', 'frame.thin + H3 padding', tooltip { text = 'bright tooltip' }),
          spacer { props = { size = ColumnGap } },
          entry(
            'meter (unsized)',
            'frame.thin, no size',
            meter {
              value = 65,
              max = 100,
            }
          ),
        },
      },

      row {
        children = {
          entry(
            'box',
            'frame.thin',
            box {
              props = { size = FrameSize },
              children = { text { text = 'default box' } },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'bookFrame',
            'frame.thin',
            bookFrame {
              title = 'Book frame',
              children = { text { text = 'default book' } },
            }
          ),
        },
      },

      row {
        children = {
          entry(
            'window',
            'frame.thick + caption',
            window {
              title = 'Window',
              props = { size = FrameSize },
              children = { text { text = 'default window' } },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry('headBlock', 'caption', headBlock { props = { size = HeadBlockSize } }),
          spacer { props = { size = ColumnGap } },
          entry('pinButton', 'pin.up/down', pinButton {}),
        },
      },

      row {
        children = {
          entry(
            'button (fixed)',
            'frame.button, fixed size',
            button {
              label = 'fixed button',
              props = { size = ControlSize },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'surface (auto, padded)',
            'frame.thin + slot',
            surface.build {
              skin = appearance.chrome 'frame.thin',
              padding = 8,
              tint = appearance.token 'color.chromeBorder',
              alpha = appearance.token 'transparency.chrome',
              content = { text { text = 'padded surface' } },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'surface (fixed, padded)',
            'frame.thin + slot',
            surface.build {
              skin = appearance.chrome 'frame.thin',
              padding = 8,
              tint = appearance.token 'color.chromeBorder',
              alpha = appearance.token 'transparency.chrome',
              props = { size = FrameSize },
              content = { text { text = 'fixed surface' } },
            }
          ),
        },
      },

      row {
        children = {
          entry(
            'surface (auto, unpadded)',
            'frame.thin + slot',
            surface.build {
              skin = appearance.chrome 'frame.thin',
              tint = appearance.token 'color.chromeBorder',
              alpha = appearance.token 'transparency.chrome',
              content = { text { text = 'unpadded surface' } },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'itemSlot (edge icon)',
            'frame.thin, icon fills slot',
            itemSlot {
              resource = { path = 'white' },
              count = 7,
              props = { size = ItemSize },
              iconProps = { size = ItemSize },
            }
          ),
          spacer { props = { size = ColumnGap } },
          entry(
            'box (full-bleed image)',
            'frame stays above content',
            box {
              props = { size = FrameSize },
              children = {
                image {
                  resource = { path = 'white' },
                  props = { size = FrameSize },
                },
              },
            }
          ),
        },
      },

      spacer { props = { size = UtilVector2(0, 8) } },
      text {
        text = 'Expected: control text follows the active H3UI palette, and every H3-owned frame follows the chosen chrome color.',
        props = labelProps(Lime),
      },
    },
  }
end

return coverage
