---@omw-context player

local core = require 'openmw.core'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local calendar = require 'openmw_aux.calendar'

local appearance = require 'scripts.h3.ui.appearance'
local button = require 'scripts.h3.components.button'
local column = require 'scripts.h3.components.column'
local metrics = require 'scripts.h3.parity.vanillaMetrics'
local row = require 'scripts.h3.components.row'
local slider = require 'scripts.h3.components.slider'
local surface = require 'scripts.h3.ui.surface'
local text = require 'scripts.h3.components.text'
local textInput = require 'scripts.h3.components.textInput'
local window = require 'scripts.h3.components.window'

local Assert, MathFloor, StrFormat, StrGmatch, StrGsub, StrMatch, ToNumber, ToString =
  assert, math.floor, string.format, string.gmatch, string.gsub, string.match, tonumber, tostring

local GetGameTime, GetGmst, L10n = core.getGameTime, core.getGMST, core.l10n
local UiAlignment, UiContent, UiLayers, UiType, UtilVector2 =
  ui.ALIGNMENT, ui.content, ui.layers, ui.TYPE, util.vector2

---@type H3UI.VanillaMetrics
local Metrics = metrics

-- Values the engine sets in C++ rather than in a layout or skin, at the metrics' engine commit.
local Engine = {
  -- MessageBox::MessageBox, apps/openmw/mwgui/messagebox.cpp.
  messageBottomPadding = 48,
  -- InteractiveMessageBox::InteractiveMessageBox: the text width, then its paddings.
  interactiveTextWidth = 400,
  interactivePadding = 10,
  -- ConfirmationDialog::askForConfirmation, apps/openmw/mwgui/confirmationdialog.cpp: the window
  -- is the message's width plus this, frame included.
  confirmationWidthMargin = 24,
  -- CountDialog::openCountDialog, apps/openmw/mwgui/countdialog.cpp: the window is
  -- max(item text width + 160, 320) wide, which is 320 for an item name under 160 pixels.
  countWidth = 320,
  -- InfoBoxDialog::onOpen, apps/openmw/mwgui/class.cpp: layoutVertically margins.
  infoButtonMargin = 6,
  infoMainMargin = 10,
}

-- The item #11's capture steps drag a stack of, so the count window's texts are known.
local CountItem, CountItemCount = 'ingred_ash_yam_01', 5

local EmptyList, FullSize, NoGrowth = {}, UtilVector2(1, 1), UtilVector2(0, 0)

---@param tag string
---@return string
local function resolveTag(tag)
  local context, key = StrMatch(tag, '^([^:]+):(.+)$')
  if context then return L10n(context)(key) end

  return ToString(GetGmst(tag) or tag)
end

---@param value string
---@return string
local function resolveTags(value) return (StrGsub(value, '#{([^}]+)}', resolveTag)) end

---@param widget H3UI.VanillaWidget
---@param key string
---@return string?
local function property(widget, key)
  local properties = widget.properties or EmptyList
  for index = 1, #properties do
    local pair = properties[index]
    if pair[1] == key then return pair[2] end
  end

  return nil
end

---@param widget H3UI.VanillaWidget
---@param key string
---@return string?
local function userString(widget, key)
  local userStrings = widget.userStrings or EmptyList
  for index = 1, #userStrings do
    local pair = userStrings[index]
    if pair[1] == key then return pair[2] end
  end

  return nil
end

---@param align? string
---@return H3UI.ParityAlignFlags
local function alignFlags(align)
  if not align then return { bottom = false, left = true, right = false, top = true } end

  local flags = { bottom = false, left = false, right = false, top = false }
  for word in StrGmatch(align, '[^%s|]+') do
    if word == 'Left' or word == 'HStretch' or word == 'Stretch' or word == 'Default' then
      flags.left = true
    end
    if word == 'Right' or word == 'HStretch' or word == 'Stretch' then flags.right = true end
    if word == 'Top' or word == 'VStretch' or word == 'Stretch' or word == 'Default' then
      flags.top = true
    end
    if word == 'Bottom' or word == 'VStretch' or word == 'Stretch' then flags.bottom = true end
  end

  return flags
end

---@param textAlign? string
---@return openmw.ui.Alignment horizontal
---@return openmw.ui.Alignment vertical
local function textAlignment(textAlign)
  local flags = alignFlags(textAlign or 'Default')
  local horizontal = flags.left and not flags.right and UiAlignment.Start
    or flags.right and not flags.left and UiAlignment.End
    or UiAlignment.Center
  local vertical = flags.top and not flags.bottom and UiAlignment.Start
    or flags.bottom and not flags.top and UiAlignment.End
    or UiAlignment.Center

  return horizontal, vertical
end

-- MyGUI realigns a child only when its parent is resized (Widget::_setAlign): stretch grows it
-- with the parent, Right or Bottom alone keeps its distance to the far edge, and neither side
-- centres it. OpenMW layouts express each rule through relativeSize, relativePosition and anchor,
-- so the engine itself keeps the child aligned to whatever size H3UI gives its parent.
---@param widget H3UI.VanillaWidget
---@param parentSize openmw.util.Vector2 The parent client area's declared size.
---@param growth openmw.util.Vector2 How much larger than declared the reconstruction's root is.
---@return table props
local function placement(widget, parentSize, growth)
  local position = widget.position or { 0, 0, 0, 0 }
  local x, y, width, height = position[1], position[2], position[3], position[4]
  local flags = alignFlags(widget.align)
  local relativeX, relativeY, stretchX, stretchY, anchorX, anchorY = 0, 0, 0, 0, 0, 0

  if flags.left and flags.right then
    width, stretchX = width - parentSize.x, 1
  elseif flags.right then
    x, relativeX = x - parentSize.x, 1
  elseif not flags.left and growth.x ~= 0 then
    x, relativeX, anchorX = 0, 0.5, 0.5
  end

  if flags.top and flags.bottom then
    height, stretchY = height - parentSize.y, 1
  elseif flags.bottom then
    y, relativeY = y - parentSize.y, 1
  elseif not flags.top and growth.y ~= 0 then
    y, relativeY, anchorY = 0, 0.5, 0.5
  end

  return {
    anchor = UtilVector2(anchorX, anchorY),
    position = UtilVector2(x, y),
    relativePosition = UtilVector2(relativeX, relativeY),
    relativeSize = UtilVector2(stretchX, stretchY),
    size = UtilVector2(width, height),
  }
end

local reconstruct

---@param widgets? H3UI.VanillaWidget[]
---@param parentSize openmw.util.Vector2
---@param context H3UI.ParityReconstructionContext
---@param flowing boolean Whether a Flex places the children, so they keep only their size.
---@return openmw.ui.Layout[]
local function reconstructChildren(widgets, parentSize, context, flowing)
  local children = {}
  widgets = widgets or EmptyList

  for index = 1, #widgets do
    children[index] = reconstruct(widgets[index], parentSize, context, flowing)
  end

  return children
end

---@param widget H3UI.VanillaWidget
---@param parentSize openmw.util.Vector2
---@param context H3UI.ParityReconstructionContext
---@param flowing boolean
---@return openmw.ui.Layout
reconstruct = function(widget, parentSize, context, flowing)
  local props = placement(widget, parentSize, context.growth)
  local kind = widget.type
  local caption = context.texts[widget.name or ''] or property(widget, 'Caption')
  local label = caption and resolveTags(caption)

  local external
  if flowing then
    props = { size = props.size }
    if userString(widget, 'HStretch') == 'true' then external = { stretch = 1 } end
  end

  if kind == 'AutoSizedButton' then
    if not flowing then props.size = nil end
    return button { label = label, props = props, external = external }
  end

  if kind == 'Button' then return button { label = label, props = props, external = external } end

  if kind == 'TextBox' or kind == 'AutoSizedTextBox' or property(widget, 'Static') == 'true' then
    local horizontal, vertical = textAlignment(property(widget, 'TextAlign'))
    props.autoSize = kind == 'AutoSizedTextBox' or kind == 'AutoSizedEditBox'
    props.multiline = property(widget, 'MultiLine') ~= nil
    props.wordWrap = property(widget, 'WordWrap') == 'true'
    props.textAlignH = horizontal
    props.textAlignV = vertical
    return text { text = label or '', props = props, external = external }
  end

  if kind == 'EditBox' or kind == 'NumericEditBox' then
    return textInput { text = label or '', props = props, external = external }
  end

  local declared = widget.position or { 0, 0, 0, 0 }
  -- H3UI's slider maps the pointer through a fixed track width (slider.lua), so a scroll bar that
  -- a box stretches, declared zero wide, has no reconstruction: its space stays empty.
  if kind == 'ScrollBar' and declared[3] <= 0 then
    return { type = UiType.Widget, external = external, props = props }
  end

  if kind == 'ScrollBar' then
    local range = context.sliderRange or 2
    local stretched = props.relativeSize and props.relativeSize.x ~= 0
    return slider {
      min = 0,
      max = range - 1,
      value = context.sliderValue or 0,
      trackWidth = stretched and declared[3] + context.growth.x or declared[3],
      props = props,
    }
  end

  local inner = UtilVector2(declared[3], declared[4])
  if kind == 'HBox' or kind == 'VBox' then
    local spacing = ToNumber(property(widget, 'Spacing'))
    local children = reconstructChildren(widget.widgets, inner, context, true)
    local flex = kind == 'HBox' and row or column
    return flex { gap = spacing, props = props, external = external, children = children }
  end

  if kind == 'Spacer' then return { type = UiType.Widget, external = { grow = 1 }, props = {} } end

  return {
    type = UiType.Widget,
    props = props,
    content = UiContent(reconstructChildren(widget.widgets, inner, context, false)),
  }
end

---@param layer string
---@return openmw.util.Vector2
local function layerSize(layer)
  local index = UiLayers.indexOf(layer)
  return (index and UiLayers[index].size) or ui.screenSize()
end

-- WindowModal::center, apps/openmw/mwgui/windowbase.cpp: integer division of the layer's free space.
---@param layer string
---@param size openmw.util.Vector2
---@return openmw.util.Vector2
local function centred(layer, size)
  local available = layerSize(layer)
  return UtilVector2(MathFloor((available.x - size.x) / 2), MathFloor((available.y - size.y) / 2))
end

---@param skin? string
---@return boolean
local function opaque(skin) return skin ~= nil and StrMatch(skin, 'NoTransp$') ~= nil end

---@param skin? string
---@return H3UI.ChromeFrame
local function frameFor(skin)
  if skin == 'HUD_Box' then return appearance.chrome 'frame.thin' end
  return appearance.chrome 'frame.thick'
end

---@param layoutName string
---@return H3UI.VanillaWidget
local function rootOf(layoutName) return Metrics.layouts[layoutName].widgets[1] end

-- The space a skin's frame takes around its Client child: left, top, and the total width and height.
---@param skinName? string
---@return integer[]
local function frameMargins(skinName)
  local skin = Metrics.skins[skinName or '']
  local size = skin and skin.size
  local children = skin and skin.children or EmptyList
  for index = 1, #children do
    local child = children[index]
    local offset = child.offset
    if child.name == 'Client' and size and offset then
      return { offset[1], offset[2], size[1] - offset[3], size[2] - offset[4] }
    end
  end

  return { 0, 0, 0, 0 }
end

---@param root H3UI.VanillaWidget
---@param size openmw.util.Vector2
---@param context H3UI.ParityReconstructionContext
---@return openmw.ui.Layout
local function fixedWindow(root, size, context)
  local position = root.position or { 0, 0, 0, 0 }
  local margins = frameMargins(root.skin)
  local clientSize = UtilVector2(position[3] - margins[3], position[4] - margins[4])
  local layer = root.layer or 'Windows'

  return window {
    layer = layer,
    position = centred(layer, size),
    size = size,
    minSize = size,
    movable = false,
    resizable = false,
    innerBorder = false,
    padding = 0,
    backgroundProps = opaque(root.skin) and { alpha = 1 } or nil,
    {
      type = UiType.Widget,
      props = { relativeSize = FullSize },
      content = UiContent(reconstructChildren(root.widgets, clientSize, context, false)),
    },
  }
end

---@param root H3UI.VanillaWidget
---@param children openmw.ui.Layout[]
---@param padding number
---@param props table
---@return openmw.ui.Layout
local function fittedSurface(root, children, padding, props)
  local layout = surface.build {
    skin = frameFor(root.skin),
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    backgroundProps = opaque(root.skin) and { alpha = 1 } or nil,
    padding = padding,
    props = props,
    content = UiContent(children),
  }
  layout.layer = root.layer
  return layout
end

---@param texts table<string, string>
---@param growth? openmw.util.Vector2
---@return H3UI.ParityReconstructionContext
local function contextWith(texts, growth) return { growth = growth or NoGrowth, texts = texts } end

---@return table
local function centredProps()
  return { relativePosition = UtilVector2(0.5, 0.5), anchor = UtilVector2(0.5, 0.5) }
end

---@param entry H3UI.ParityManifestEntry
---@return openmw.ui.Layout
local function messagebox(entry)
  local root = rootOf 'messagebox'
  local message = root.widgets[1]
  local horizontal = textAlignment(property(message, 'TextAlign'))
  local padding = ToNumber(property(root, 'Padding')) or 0

  return fittedSurface(
    root,
    {
      text {
        text = entry.opens.text,
        props = {
          autoSize = true,
          multiline = true,
          wordWrap = true,
          size = UtilVector2(message.position[3], 0),
          textAlignH = horizontal,
        },
      },
    },
    padding,
    {
      relativePosition = UtilVector2(0.5, 1),
      anchor = UtilVector2(0.5, 1),
      position = UtilVector2(0, -Engine.messageBottomPadding),
    }
  )
end

---@param layoutName string
---@return H3UI.ParityReconstruction
local function interactiveMessage(layoutName)
  ---@param entry H3UI.ParityManifestEntry
  ---@return openmw.ui.Layout
  return function(entry)
    local root = rootOf(layoutName)
    local padding = Engine.interactivePadding

    return fittedSurface(root, {
      column {
        gap = padding,
        children = {
          text {
            text = entry.opens.text,
            props = {
              autoSize = true,
              multiline = true,
              wordWrap = true,
              size = UtilVector2(Engine.interactiveTextWidth, 0),
              textAlignH = UiAlignment.Center,
            },
          },
          row { children = { button { label = resolveTags '#{Interface:OK}' } } },
        },
      },
    }, padding, centredProps())
  end
end

---@return openmw.ui.Layout
local function confirmationDialog()
  local root = rootOf 'confirmation_dialog'
  local context = contextWith { Message = '#{OMWEngine:QuitGameConfirmation}' }
  local message, buttons = root.widgets[1], root.widgets[2]
  local horizontal = textAlignment(property(message, 'TextAlign'))
  local padding = (Engine.confirmationWidthMargin - frameMargins(root.skin)[3]) / 2

  return fittedSurface(root, {
    column {
      children = {
        text {
          text = resolveTags(context.texts.Message),
          props = { autoSize = true, multiline = true, wordWrap = true, textAlignH = horizontal },
        },
        reconstruct(buttons.widgets[1], UtilVector2(0, 0), context, true),
      },
    },
  }, padding, centredProps())
end

---@return openmw.ui.Layout
local function countWindow()
  local root = rootOf 'count_window'
  local record = types.Ingredient.record(CountItem)
  local context = contextWith({
    LabelText = '#{sTake}',
    ItemText = record and record.name or CountItem,
    ItemEdit = StrFormat('%d', CountItemCount),
  }, UtilVector2(Engine.countWidth - root.position[3], 0))
  context.sliderRange = CountItemCount
  context.sliderValue = CountItemCount - 1

  return fixedWindow(root, UtilVector2(Engine.countWidth, root.position[4]), context)
end

---@return openmw.ui.Layout
local function textInputDialog()
  local root = rootOf 'text_input'
  local record = Assert(types.NPC.record(self.object), 'The player has no NPC record')
  local context = contextWith { LabelT = '#{sName}', TextEdit = record.name, OKButton = '#{sNext}' }

  return fixedWindow(root, UtilVector2(root.position[3], root.position[4]), context)
end

---@return openmw.ui.Layout
local function waitDialog()
  local root = rootOf 'wait_dialog'
  -- WaitDialog::onOpen, apps/openmw/mwgui/waitdialog.cpp: the day of the month, the month, the
  -- days passed (the game time's whole days), and the hour on a 12-hour clock.
  local now = GetGameTime()
  local date = calendar.formatGameTime('*t', now)
  local halfDay = date.hour >= 12 and '#{Calendar:pm}' or '#{Calendar:am}'
  local clockHour = date.hour % 12 == 0 and 12 or date.hour % 12
  local monthName = L10n 'Calendar'(StrFormat('month%d', date.month))
  local daysPassed = MathFloor(now / 86400)

  local context = contextWith {
    DateTimeText = StrFormat(
      '%d %s (#{Calendar:day} %d) %d %s',
      date.day,
      monthName,
      daysPassed,
      clockHour,
      halfDay
    ),
    RestText = '#{sRestMenu3}',
    HourText = '1 #{sRestMenu2}',
  }
  context.sliderRange = 24

  return fittedSurface(root, {
    column {
      gap = ToNumber(property(root, 'Spacing')),
      children = reconstructChildren(root.widgets, UtilVector2(0, 0), context, true),
    },
  }, ToNumber(property(root, 'Padding')) or 0, centredProps())
end

---@return openmw.ui.Layout
local function infobox()
  local root = rootOf 'infobox'
  local labels = { 'sClassChoiceMenu1', 'sClassChoiceMenu2', 'sClassChoiceMenu3', 'sBack' }
  local buttons = {}
  for index = 1, #labels do
    buttons[index] = button { label = resolveTag(labels[index]) }
  end

  return fittedSurface(root, {
    column { gap = Engine.infoButtonMargin, children = buttons },
  }, Engine.infoMainMargin, centredProps())
end

---@type table<string, H3UI.ParityReconstruction>
return {
  confirmation_dialog = confirmationDialog,
  count_window = countWindow,
  infobox = infobox,
  interactive_messagebox = interactiveMessage 'interactive_messagebox',
  messagebox = messagebox,
  text_input = textInputDialog,
  wait_dialog = waitDialog,
}
