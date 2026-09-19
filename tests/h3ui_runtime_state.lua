---@omw-context none

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_runtime_state%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

package.preload['openmw.async'] = function()
  return {
    callback = function(_, callback) return callback end,
  }
end

package.preload['openmw.interfaces'] = function()
  return {
    MWUI = {
      templates = {
        borders = {},
        box = {},
        interval = {},
        padding = {},
        textNormal = {},
      },
    },
  }
end

package.preload['openmw.ui'] = function()
  local function content(value)
    local proxy = newproxy(true)
    local metatable = getmetatable(proxy)
    metatable.__index = function(_, key)
      if key == 'add' then
        return function(_, child) value[#value + 1] = child end
      end
      if type(key) == 'number' then return value[key] end
      if value[key] ~= nil then return value[key] end
      if type(key) == 'string' then
        for index = 1, #value do
          if value[index].name == key then return value[index] end
        end
      end
    end
    metatable.__newindex = function(_, key, newValue)
      assert(type(key) == 'string' and newValue == nil, 'mock content only supports named removal')
      for index = 1, #value do
        if value[index].name == key then
          table.remove(value, index)
          return
        end
      end
    end
    metatable.__len = function() return #value end
    return proxy
  end

  return {
    content = content,
    ALIGNMENT = { Center = 'Center' },
    TYPE = {
      Container = 'Container',
      Flex = 'Flex',
      Image = 'Image',
      TextEdit = 'TextEdit',
      Widget = 'Widget',
    },
    layers = { indexOf = function() return nil end },
    texture = function(value) return value end,
    create = function(layout)
      return { layout = layout, update = function() end }
    end,
  }
end

package.preload['openmw.util'] = function()
  return {
    clamp = function(value, minimum, maximum) return math.max(minimum, math.min(value, maximum)) end,
    color = {
      commaString = function(value) return value end,
      rgb = function(red, green, blue) return { red, green, blue } end,
      rgba = function(red, green, blue, alpha) return { red, green, blue, alpha } end,
    },
    vector2 = function(x, y) return { x = x, y = y } end,
  }
end

package.preload['scripts.omw.mwui.constants'] = function()
  return {
    headerColor = 'header-color',
    normalColor = 'normal-color',
    textHeaderSize = 18,
    textNormalSize = 16,
    padding = 2,
    border = 2,
    thickBorder = 4,
    whiteTexture = { path = 'white' },
  }
end

package.preload['scripts.h3.ui.appearance'] = function()
  local chrome = require 'scripts.h3.ui.chrome'
  return {
    chrome = function(path) return chrome.resolve(nil, path) end,
    token = function(path)
      if path == 'color.chromeBorder' then return 'chrome-border' end
      if path == 'color.text' then return 'text-color' end
      if path == 'border.normal' then return 2 end
      if path == 'textSize.normal' then return 16 end
      if path == 'transparency.chrome' then return 0.75 end
      if path == 'spacing.padding' then return 2 end
      return nil
    end,
  }
end

local I = require 'openmw.interfaces'
local bookFrame = require 'scripts.h3.components.bookFrame'
local chrome = require 'scripts.h3.ui.chrome'
local chromeAssets = require 'scripts.h3.ui.themes.chromeAssets'
local itemGrid = require 'scripts.h3.ui.recipes.itemGrid'
local itemSlot = require 'scripts.h3.components.itemSlot'
local meter = require 'scripts.h3.components.meter'
local newRegistry = require 'scripts.h3.ui.registry'
local newResolver = require 'scripts.h3.ui.resolver'
local newScope = require 'scripts.h3.ui.scope'
local pinButton = require 'scripts.h3.components.pinButton'
local searchInput = require 'scripts.h3.components.searchInput'
local searchableList = require 'scripts.h3.ui.recipes.searchableList'
local selector = require 'scripts.h3.components.selector'
local surface = require 'scripts.h3.ui.surface'
local tabbedWindow = require 'scripts.h3.ui.recipes.tabbedWindow'
local tabs = require 'scripts.h3.components.tabs'
local textInput = require 'scripts.h3.components.textInput'
local textRules = require 'scripts.h3.ui.themes.textRules'
local themeModule = require 'scripts.h3.ui.theme'
local token = require 'scripts.h3.ui.token'
local tooltip = require 'scripts.h3.components.tooltip'
local ui = require 'openmw.ui'
local updateQueue = require 'scripts.h3.ui.updateQueue'
local window = require 'scripts.h3.components.window'

local registry = newRegistry {
  button = {
    builder = require 'scripts.h3.components.button',
    runtimeState = true,
    selectable = true,
    slots = { root = { props = 'props', external = 'external' }, label = { props = 'labelProps' } },
  },
  selector = {
    builder = function(options)
      return { events = options.events, props = options.props, content = {} }
    end,
    slots = { root = { props = 'props' }, label = { props = 'labelProps' } },
  },
  toggle = {
    builder = require 'scripts.h3.components.toggle',
    runtimeState = true,
    invalidateOn = 'onChange',
    slots = { root = { props = 'props', external = 'external' }, label = { props = 'labelProps' } },
  },
  text = { builder = function(options) return options end, slots = { root = { props = 'props' } } },
  spacer = {
    builder = require 'scripts.h3.components.spacer',
    slots = { root = { props = 'props' } },
  },
  dialog = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, title = { props = 'titleProps' } },
  },
  bookFrame = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      title = { props = 'titleProps' },
      background = { props = 'backgroundProps' },
    },
  },
  caption = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, text = { props = 'textProps' } },
  },
  window = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      captionText = { props = 'captionTextProps' },
      background = { props = 'backgroundProps' },
    },
  },
  numberInput = { builder = function() return {} end, slots = { root = { props = 'props' } } },
  textInput = { builder = function() return {} end, slots = { root = { props = 'props' } } },
  iconButton = {
    builder = function() return {} end,
    selectable = true,
    slots = {
      root = { props = 'props' },
      label = { props = 'labelProps' },
      selectedChrome = { props = 'selectionProps', retained = true },
    },
  },
  listItem = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      label = { props = 'labelProps' },
      secondary = { props = 'secondaryProps' },
    },
  },
  tabs = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      label = { props = 'labelProps' },
      selectedLabel = { props = 'selectedLabelProps' },
    },
  },
  collapsible = {
    builder = require 'scripts.h3.components.collapsible',
    invalidateOn = 'onToggle',
    slots = { root = { props = 'props' }, headerLabel = { props = 'headerLabelProps' } },
  },
  itemSlot = {
    builder = function() return {} end,
    selectable = true,
    slots = {
      root = { props = 'props' },
      count = { props = 'countProps' },
      selectedChrome = { props = 'selectionProps', retained = true },
    },
  },
  tooltip = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, text = { props = 'textProps' } },
  },
  searchInput = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, input = { props = 'inputProps' } },
  },
}

local sharedRules = {
  {
    selector = { component = 'button', slot = 'label' },
    style = { props = { textColor = token.ref 'color.text' } },
  },
  {
    selector = { component = 'toggle', slot = 'label' },
    style = { props = { textColor = token.ref 'color.text' } },
  },
  {
    selector = { component = 'button', slot = 'label', state = 'hover' },
    style = { props = { textColor = token.ref 'color.textHover' } },
  },
  {
    selector = { component = 'button', slot = 'label', state = 'pressed' },
    style = { props = { textColor = token.ref 'color.textPressed' } },
  },
  {
    selector = { component = 'toggle', slot = 'label', state = 'hover' },
    style = { props = { textColor = token.ref 'color.textHover' } },
  },
  {
    selector = { component = 'toggle', slot = 'label', state = 'pressed' },
    style = { props = { textColor = token.ref 'color.textPressed' } },
  },
  {
    selector = { component = 'button', slot = 'label', selected = true },
    style = { props = { textColor = 'selected-text' } },
  },
  {
    selector = { component = 'button', slot = 'label', selected = true, state = 'hover' },
    style = { props = { textColor = 'selected-hover' } },
  },
}

local function makeTheme(name, colors)
  return themeModule.new({
    name = name,
    tokens = { color = colors },
    rules = sharedRules,
  }, registry)
end

local morrowind = makeTheme('morrowind-test', {
  text = 'morrowind-text',
  textHover = 'morrowind-hover',
  textPressed = 'morrowind-pressed',
})
local starwind = makeTheme('starwind-test', {
  text = 'starwind-text',
  textHover = 'starwind-hover',
  textPressed = 'starwind-pressed',
})
local resolver = newResolver(registry, { 'button', 'text', 'spacer' })

local function build(theme, spec, invalidate)
  return resolver.build({
    invalidate = invalidate,
    resolveTheme = function() return theme end,
    recipes = {},
  }, spec)
end

local function buildWith(theme, spec, recipes, invalidate)
  return resolver.build({
    invalidate = invalidate,
    resolveTheme = function() return theme end,
    recipes = recipes or {},
  }, spec)
end

local function labelProps(layout)
  local result = layout.content[1]
  while result.content do
    result = result.content[1]
  end
  return result.props
end

local function findDescendant(layout, predicate)
  if predicate(layout) then return layout end
  if not layout.content then return nil end

  for index = 1, #layout.content do
    local result = findDescendant(layout.content[index], predicate)
    if result then return result end
  end
end

local function testThemeTokens()
  assert(
    labelProps(build(morrowind, { component = 'button', label = 'Morrowind' })).textColor
      == 'morrowind-text'
  )
  assert(
    labelProps(build(starwind, { component = 'button', label = 'Starwind' })).textColor
      == 'starwind-text'
  )

  local starwindSpec = require 'scripts.h3.ui.themes.starwind'
  local canonicalStarwind = themeModule.new(starwindSpec, registry, morrowind)
  local disabled = canonicalStarwind.token 'color.disabled'
  assert(disabled[1] == 77 / 255 and disabled[2] == 156 / 255 and disabled[3] == 221 / 255)
  local weaponFill = canonicalStarwind.token 'color.weaponFill'
  assert(weaponFill[1] == 182 / 255 and weaponFill[2] == 72 / 255 and weaponFill[3] == 31 / 255)

  local canonicalMorrowind = themeModule.new(require 'scripts.h3.ui.themes.morrowind', registry)
  assert(canonicalMorrowind.token 'transparency.menu' == 0.84)
end

local function testTextRuleSlots()
  local rules = textRules()
  for index = 1, #rules do
    local component = rules[index].selector.component
    if component == 'numberInput' or component == 'textInput' then
      assert(rules[index].selector.slot == 'root')
    end
  end
end

local function testBookFrameBackground()
  local background = { color = 'starwind-background', alpha = 0.84 }
  local layout = bookFrame { backgroundProps = background }
  local frameContent = layout.template.content
  assert(layout.template.type == ui.TYPE.Container)
  assert(frameContent[1].props.color == background.color)
  assert(frameContent[1].props.alpha == background.alpha)
  assert(layout.content[1].props.horizontal == false)
  assert(frameContent.h3ui_content.external.slot)
  local topLeft = frameContent.h3ui_topLeft
  assert(topLeft.props.resource.path == 'textures/h3ui/chrome/coral_fort_wall_02.dds')
  assert(topLeft.props.resource.offset.x == 4)
  assert(topLeft.props.resource.offset.y == 4)
  assert(topLeft.props.resource.size.x == 2 and topLeft.props.resource.size.y == 2)
  assert(topLeft.props.size.x == 2 and topLeft.props.size.y == 2)
  local topRight = frameContent.h3ui_topRight
  assert(topRight.props.position.x == 0 and topRight.props.position.y == 0)
  local right = frameContent.h3ui_right
  assert(right.props.position.x == 0 and right.props.position.y == 2)
  local bottomLeft = frameContent.h3ui_bottomLeft
  assert(bottomLeft.props.position.x == 0 and bottomLeft.props.position.y == 0)
  local bottom = frameContent.h3ui_bottom
  assert(bottom.props.position.x == 2 and bottom.props.position.y == 0)
  local bottomRight = frameContent.h3ui_bottomRight
  assert(bottomRight.props.position.x == 0 and bottomRight.props.position.y == 0)
end

local function testBuiltinPinChromePaths()
  assert(chrome.resolve(nil, 'pin.up').path == 'textures/h3ui/chrome/coral_fort_wall_02.dds')
  assert(chrome.resolve(nil, 'pin.up').offset.x == 328)
  assert(chrome.resolve(nil, 'pin.down').path == 'textures/h3ui/chrome/coral_fort_wall_02.dds')
  assert(chrome.resolve(nil, 'pin.down').offset.x == 400)
  assert(chrome.resolve(nil, 'scroll.left').offset.x == 392)
  assert(chrome.resolve(nil, 'scroll.left').size.x == 16)
  assert(chrome.resolve(nil, 'scroll.left').size.y == 16)

  assert(chromeAssets.morrowind.frame.thin.offset.x == 4)
  assert(chromeAssets.morrowind.frame.thin.offset.y == 4)
  assert(chromeAssets.morrowind.frame.thin.size.x == 504)
  assert(chromeAssets.morrowind.frame.thin.size.y == 504)
  assert(chromeAssets.morrowind.frame.thin.sourceBorder == 2)
  assert(chromeAssets.morrowind.frame.thick.offset.x == 0)
  assert(chromeAssets.morrowind.frame.thick.sourceBorder == 4)
  assert(chromeAssets.morrowind.frame.pinUp.offset.x == 328)
  assert(chromeAssets.morrowind.frame.pinDown.offset.x == 400)
  assert(chromeAssets.morrowind.scroll.left.offset.x == 392)
  assert(chromeAssets.morrowind.scroll.left.size.x == 16)
end

local function testWindowInnerBorder()
  local layout = window { title = 'window', size = { x = 400, y = 300 } }
  local innerBorder = layout.content[3]
  local body = layout.content[4]

  assert(innerBorder.name == 'innerBorder')
  assert(innerBorder.props.position.x == 4 and innerBorder.props.position.y == 24)
  assert(innerBorder.props.size.x == -8 and innerBorder.props.size.y == -28)
  assert(body.props.position.x == 16 and body.props.position.y == 36)
  assert(body.props.size.x == -32 and body.props.size.y == -52)

  local outerOnly = window { innerBorder = false }
  assert(outerOnly.content[2].name == 'body')
end

local function testStateMachineAndEventReturns()
  local returnValue = {}
  local mouseReturn = false
  local callbackCalled = false
  local invalidationCount = 0
  local layout = build(morrowind, {
    component = 'button',
    label = 'Button',
    events = {
      focusGain = function()
        callbackCalled = true
        return returnValue
      end,
      mousePress = function() return mouseReturn end,
    },
  }, function()
    assert(callbackCalled)
    invalidationCount = invalidationCount + 1
  end)
  assert(type(layout.content) == 'userdata')
  local props = labelProps(layout)
  props.unrelated = 'preserved'
  props.textColor = 'changed-before-focus'

  assert(layout.events.focusGain(nil, layout) == returnValue)
  assert(invalidationCount == 1)
  assert(props.textColor == 'morrowind-hover')
  layout.events.focusGain(nil, layout)
  assert(invalidationCount == 1)
  assert(layout.events.mousePress({ button = 1 }, layout) == mouseReturn)
  assert(invalidationCount == 2)
  assert(props.textColor == 'morrowind-pressed')
  assert(layout.events.mouseRelease({ button = 1 }, layout) == nil)
  assert(invalidationCount == 3)
  assert(props.textColor == 'morrowind-hover')
  layout.events.focusLoss(nil, layout)
  assert(invalidationCount == 4)
  assert(props.textColor == 'changed-before-focus')
  assert(props.unrelated == 'preserved')

  local noResurrection = build(morrowind, { component = 'button', label = 'Button' })
  local noResurrectionProps = labelProps(noResurrection)
  noResurrection.events.mousePress({ button = 1 }, noResurrection)
  noResurrection.events.focusLoss(nil, noResurrection)
  noResurrection.events.mouseRelease({ button = 1 }, noResurrection)
  assert(noResurrectionProps.textColor == 'morrowind-text')

  local hoverOnly = themeModule.new({
    name = 'hover-only',
    tokens = {
      color = { text = 'normal', textHover = 'hover' },
    },
    rules = {
      sharedRules[1],
      {
        selector = { component = 'button', slot = 'label', state = 'hover' },
        style = { props = { textColor = token.ref 'color.textHover' } },
      },
    },
  }, registry)
  local hoverOnlyLayout = build(hoverOnly, { component = 'button', label = 'Hover only' })
  local hoverOnlyProps = labelProps(hoverOnlyLayout)
  hoverOnlyLayout.events.focusGain(nil, hoverOnlyLayout)
  assert(hoverOnlyProps.textColor == 'hover')
  assert(hoverOnlyLayout.events.mousePress == nil)
  assert(hoverOnlyLayout.events.mouseRelease == nil)
  hoverOnlyLayout.events.focusLoss(nil, hoverOnlyLayout)
  assert(hoverOnlyProps.textColor == 'normal')

  local pressedOnly = themeModule.new({
    name = 'pressed-only',
    tokens = {
      color = { text = 'normal', textPressed = 'pressed' },
    },
    rules = {
      sharedRules[1],
      {
        selector = { component = 'button', slot = 'label', state = 'pressed' },
        style = { props = { textColor = token.ref 'color.textPressed' } },
      },
    },
  }, registry)
  local pressedOnlyLayout = build(pressedOnly, { component = 'button', label = 'Pressed only' })
  local pressedOnlyProps = labelProps(pressedOnlyLayout)
  assert(pressedOnlyLayout.events.focusGain == nil)
  assert(pressedOnlyProps.textColor == 'normal')
  pressedOnlyLayout.events.mousePress({ button = 1 }, pressedOnlyLayout)
  assert(pressedOnlyProps.textColor == 'pressed')
  pressedOnlyLayout.events.mouseRelease({ button = 1 }, pressedOnlyLayout)
  assert(pressedOnlyProps.textColor == 'normal')

  local recipeLayout = buildWith(morrowind, { recipe = 'buttonRecipe' }, {
    buttonRecipe = function(context) return context.button { label = 'Recipe button' } end,
  }, function() invalidationCount = invalidationCount + 1 end)
  recipeLayout.events.focusGain(nil, recipeLayout)
  assert(invalidationCount == 5)

  local scoped = newScope({
    invalidate = function() invalidationCount = invalidationCount + 1 end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {
      testCard = function(context, spec) return context.text(spec.label) end,
    },
    resolver = resolver,
    publicComponents = { 'button', 'text', 'spacer' },
  })

  local scopeLayout = scoped.button { label = 'Scoped button' }
  scopeLayout.events.focusGain(nil, scopeLayout)
  assert(invalidationCount == 6)

  local ok, err = pcall(function()
    scoped.button {
      label = 'Override button',
      invalidate = function() end,
    }
  end)
  assert(not ok and tostring(err):find('invalidation belongs to the scope', 1, true))
  assert(invalidationCount == 6)

  local shorthandText = scoped.text 'Constructor text'
  assert(shorthandText.text == 'Constructor text')

  local shorthandSpacer = scoped.spacer(8, 4)
  assert(shorthandSpacer.props.size.x == 8 and shorthandSpacer.props.size.y == 4)

  local constructorRecipeLayout = scoped.testCard { label = 'Recipe constructor' }
  assert(constructorRecipeLayout.text == 'Recipe constructor')
end

local function testProtectionAndTraversal()
  local callerOwned = build(morrowind, {
    component = 'button',
    label = 'Button',
    labelProps = { textColor = 'caller' },
  })
  assert(labelProps(callerOwned).textColor == 'caller')
  assert(callerOwned.events == nil)

  local inlineOwned = build(morrowind, {
    component = 'button',
    label = 'Button',
    style = { label = { props = { textColor = 'inline' } } },
  })
  assert(labelProps(inlineOwned).textColor == 'inline')
  assert(inlineOwned.events == nil)

  local customContent = build(morrowind, {
    component = 'button',
    content = { { props = { textColor = 'custom' } } },
  })
  assert(customContent.events == nil)
  assert(customContent.content[1].props.textColor == 'custom')

  local composite = build(morrowind, { component = 'selector' })
  assert(composite.events == nil)

  local selectedSelector = build(morrowind, { component = 'selector', selected = 2 })
  assert(selectedSelector.events == nil)

  local stateOk, stateError = pcall(build, morrowind, {
    component = 'button',
    state = 'disabled',
  })
  assert(not stateOk and tostring(stateError):find('instance state was removed', 1, true))

  local argsOk, argsError = pcall(build, morrowind, {
    component = 'button',
    args = { label = 'legacy' },
  })
  assert(not argsOk and tostring(argsError):find('component args are flat', 1, true))

  local plain = themeModule.new({ name = 'plain' }, registry)
  local plainLayout = build(plain, { component = 'button', label = 'Plain' })
  assert(plainLayout.events == nil)
end

local function testToggleLabelMutation()
  local layout = build(morrowind, { component = 'toggle', value = false })
  local props = labelProps(layout)

  layout.events.focusGain(nil, layout)
  layout.events.mousePress({ button = 1 }, layout)
  layout.events.mouseClick(nil, layout)
  assert(props.text == 'On')
  layout.events.focusLoss(nil, layout)
  assert(props.text == 'On')
end

local function testTabStyleRetention()
  local layout = tabs {
    items = { 'First', 'Second' },
    buttonProps = { marker = 'base' },
    selectedProps = { marker = 'selected' },
    labelProps = { textColor = 'base' },
    selectedLabelProps = { textColor = 'selected' },
  }
  local first = layout.content[1]
  local second = layout.content[2]

  assert(first.props.marker == 'selected')
  assert(labelProps(first).textColor == 'selected')
  assert(second.props.marker == 'base')
  assert(labelProps(second).textColor == 'base')

  second.events.mouseClick(nil, second)
  assert(first.props.marker == 'base')
  assert(labelProps(first).textColor == 'base')
  assert(second.props.marker == 'selected')
  assert(labelProps(second).textColor == 'selected')
end

local function testTabbedWindowControlledSelection()
  local selectedIndex
  local onSelect
  local general = { name = 'general' }
  local advanced = { name = 'advanced' }
  local context = {
    token = function(path)
      assert(path == 'spacing.sm')
      return 4
    end,
    tabs = function(options)
      onSelect = options.onSelect
      return { kind = 'tabs', options = options }
    end,
    column = function(options) return { kind = 'column', options = options } end,
    window = function(options) return { kind = 'window', options = options } end,
  }

  local layout = tabbedWindow(context, {
    selected = 2,
    tabs = {
      { label = 'General', content = general },
      { label = 'Advanced', content = advanced },
    },
    onSelect = function(index) selectedIndex = index end,
  })

  local body = layout.options.children[1]
  assert(body.options.children[1].options.selected == 2)
  assert(body.options.children[2].options.children[1] == advanced)

  onSelect(1)
  assert(selectedIndex == 1)
  assert(body.options.children[2].options.children[1] == advanced)
end

local function testSelectorAlignment()
  local layout = selector { items = { 'First' } }
  local arrow = findDescendant(
    layout.content[1],
    function(child) return child.type == ui.TYPE.Image end
  )
  local value = findDescendant(layout.content[2], function(child) return child.name == 'value' end)

  assert(layout.props.arrange == 'Center')
  assert(arrow and arrow.props.color == 'chrome-border')
  assert(value and value.props.textAlignH == 'Center')
  assert(value.props.textAlignV == 'Center')
end

local function testSearchInputHeight()
  local layout = searchInput { inputProps = { size = { x = 420, y = 28 } } }
  local input = findDescendant(layout, function(child) return child.type == ui.TYPE.TextEdit end)

  assert(input and input.props.size.y == 24)

  local defaultLayout = searchInput {}
  local defaultInput = findDescendant(
    defaultLayout,
    function(child) return child.type == ui.TYPE.TextEdit end
  )
  assert(defaultInput and defaultInput.props.size.y == 20)
end

local function testItemSlotChrome()
  local layout = itemSlot {}
  assert(layout.template == nil)
  assert(layout.content[1].template.content.h3ui_topLeft.props.color == 'chrome-border')

  local customTemplate = {}
  assert(itemSlot({ template = customTemplate }).template == customTemplate)
end

local function testChromeCacheAndSkinSwap()
  local skin = chrome.resolve(nil, 'frame.thin')
  local first = surface.build {
    skin = skin,
    alpha = 0.75,
    backgroundProps = { color = 'background' },
  }
  local second = surface.build {
    skin = skin,
    alpha = 0.75,
    backgroundProps = { color = 'background' },
  }
  assert(first.template == second.template)
  assert(first.template.content.h3ui_topLeft.props.alpha == 0.75)

  local pin = pinButton {}
  local pinTopLeft = pin.content[2]
  assert(pinTopLeft.name == 'h3ui_topLeft')
  assert(pinTopLeft.props.resource.path == 'textures/h3ui/chrome/coral_fort_wall_02.dds')
  assert(pinTopLeft.props.resource.offset.x == 328)
  pin.events.mouseClick(nil, pin)
  assert(pinTopLeft.props.resource.path == 'textures/h3ui/chrome/coral_fort_wall_02.dds')
  assert(pinTopLeft.props.resource.offset.x == 400)

  local defaultMeter = meter {}
  assert(defaultMeter.type == ui.TYPE.Widget)
  assert(defaultMeter.props.size.x == 150 and defaultMeter.props.size.y == 18)
  assert(defaultMeter.content[2].name == 'h3ui_topLeft')
  assert(defaultMeter.content[2].props.color == 'chrome-border')

  local defaultTooltip = tooltip {}
  assert(defaultTooltip.template == nil)
  local tooltipContent = defaultTooltip.content[1]
  assert(tooltipContent.type == ui.TYPE.Widget)
  assert(tooltipContent.props.position.x == 2 and tooltipContent.props.position.y == 2)
  assert(tooltipContent.props.size.x == -4 and tooltipContent.props.size.y == -4)
  assert(tooltipContent.props.relativeSize.x == 1 and tooltipContent.props.relativeSize.y == 1)
  local tooltipText = tooltipContent.content[1]
  assert(tooltipText.type == ui.TYPE.TextEdit)
  assert(tooltipText.props.readOnly == true and tooltipText.props.wordWrap == true)
end

local function testImmediateRecipeConstructors()
  local layout = buildWith(morrowind, {
    recipe = 'immediateButton',
  }, {
    immediateButton = function(context) return context.button { label = 'Immediate' } end,
  })
  assert(layout.component == nil and layout.recipe == nil)
  assert(layout.args == nil and layout.spec == nil)
  local label = findDescendant(
    layout,
    function(child) return child.type == ui.TYPE.Text and child.props.text == 'Immediate' end
  )
  assert(label ~= nil)

  local nested = buildWith(morrowind, {
    recipe = 'outer',
  }, {
    outer = function(context) return context.inner { label = 'Deep' } end,
    inner = function(context, spec) return context.button { label = spec.label } end,
  })
  assert(nested.component == nil and nested.recipe == nil)
  local deepLabel = findDescendant(
    nested,
    function(child) return child.type == ui.TYPE.Text and child.props.text == 'Deep' end
  )
  assert(deepLabel ~= nil)
end

local function testInvalidatorCallbackOrder()
  local order = {}
  local layout = build(morrowind, {
    component = 'toggle',
    label = 'Sound',
    value = false,
    onChange = function(value) order[#order + 1] = 'change:' .. tostring(value) end,
  }, function() order[#order + 1] = 'invalidate' end)
  layout.events.mouseClick(nil, layout)
  assert(#order == 2)
  assert(order[1] == 'change:true')
  assert(order[2] == 'invalidate')
  layout.events.mouseClick(nil, layout)
  assert(#order == 4)
  assert(order[3] == 'change:false')
  assert(order[4] == 'invalidate')
end

local function testExplainTracePreserved()
  local explanation = resolver.explain({
    resolveTheme = function() return morrowind end,
    recipes = {},
  }, {
    component = 'button',
    label = 'Explain',
  })
  assert(#explanation.nodes == 1)
  local node = explanation.nodes[1]
  assert(node.component == 'button')
  assert(type(node.matched) == 'table' and #node.matched > 0)
  assert(type(node.themeStyle) == 'table')
end

local function testSharedRuntimeDispatcher()
  local first = build(morrowind, { component = 'button', label = 'First' })
  local second = build(morrowind, { component = 'button', label = 'Second' })
  assert(first.events.focusGain == second.events.focusGain)
  assert(first.events.focusLoss == second.events.focusLoss)
  assert(first.events.mousePress == second.events.mousePress)
  assert(first.events.mouseRelease == second.events.mouseRelease)

  first.events.focusGain(nil, first)
  assert(labelProps(first).textColor == 'morrowind-hover')
  assert(labelProps(second).textColor == 'morrowind-text')
end

local function testInteractionRedrawCoalescing()
  local updated = 0
  local fakeElement = {
    layout = {},
    update = function() updated = updated + 1 end,
  }
  local scoped = newScope({
    element = function() return fakeElement end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = { 'button' },
  })
  local layout = scoped.button { label = 'Coalesced' }

  layout.events.focusGain(nil, layout)
  layout.events.mousePress({ button = 1 }, layout)
  layout.events.mouseRelease({ button = 1 }, layout)
  assert(updated == 0)
  updateQueue.flush()
  assert(updated == 1)

  layout.events.focusLoss(nil, layout)
  layout.events.focusGain(nil, layout)
  assert(updated == 1)
  updateQueue.flush()
  assert(updated == 2)
end

local function testElementRedrawDeduplicationAndRequeue()
  local updated = 0
  local firstScope
  local holder = { name = 'holder', content = ui.content {} }
  local element = {
    layout = {},
    update = function()
      updated = updated + 1
      if updated == 1 then firstScope.setChildren(holder, { { name = 'queued-during-update' } }) end
    end,
  }
  local environment = {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = {},
  }
  firstScope = newScope({ element = function() return element end }, environment)
  local secondScope = newScope({ element = function() return element end }, environment)

  firstScope.setChildren(holder, { { name = 'first' } })
  secondScope.setChildren(holder, { { name = 'second' } })
  updateQueue.flush()
  assert(updated == 1)
  assert(holder.content[1].name == 'queued-during-update')

  updateQueue.flush()
  assert(updated == 2)
  updateQueue.flush()
  assert(updated == 2)
end

local function testSharedElementRedrawDeduplication()
  local updated = 0
  local fakeElement = {
    layout = {},
    update = function() updated = updated + 1 end,
  }
  local environment = {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = {},
  }
  local first = newScope({ element = function() return fakeElement end }, environment)
  local second = newScope({ element = function() return fakeElement end }, environment)

  first.invalidate()
  second.invalidate()
  first.invalidate()
  updateQueue.flush()
  assert(updated == 1)

  second.invalidate()
  updateQueue.flush()
  assert(updated == 2)
end

local function testRedrawQueueReentrancy()
  local updatesA = 0
  local updatesB = 0
  local updatesC = 0
  local requestA
  local requestC

  local elementA = {
    layout = {},
    update = function()
      updatesA = updatesA + 1
      if updatesA == 1 then
        updateQueue.queue(requestA)
        updateQueue.queue(requestC)
      end
    end,
  }
  local elementB = {
    layout = {},
    update = function() updatesB = updatesB + 1 end,
  }
  local elementC = {
    layout = {},
    update = function() updatesC = updatesC + 1 end,
  }

  requestA = { pending = false, resolveElement = function() return elementA end }
  local requestB = { pending = false, resolveElement = function() return elementB end }
  requestC = { pending = false, resolveElement = function() return elementC end }

  updateQueue.queue(requestA)
  updateQueue.queue(requestB)
  updateQueue.flush()
  assert(updatesA == 1 and updatesB == 1 and updatesC == 0)

  updateQueue.flush()
  assert(updatesA == 2 and updatesB == 1 and updatesC == 1)
end

local function testSetChildren()
  local invalidations = 0
  local scoped = newScope({
    invalidate = function() invalidations = invalidations + 1 end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = {},
  })
  local holder = { name = 'holder', content = ui.content { { name = 'old' } } }
  scoped.setChildren(holder, { { name = 'new' } })
  assert(holder.content[1].name == 'new')
  assert(#holder.content == 1)
  assert(invalidations == 1)
  scoped.setChildren(holder, { { name = 'newer' } })
  assert(holder.content[1].name == 'newer')
  assert(#holder.content == 1)
  assert(invalidations == 2)
end

local function testScopeElementResolver()
  local updated = 0
  local fakeElement = {
    layout = {},
    update = function() updated = updated + 1 end,
  }
  local current = nil
  local scoped = newScope({
    element = function() return current end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = {},
  })
  local holder = { name = 'holder', content = ui.content {} }
  scoped.setChildren(holder, { { name = 'child' } })
  assert(updated == 0)
  updateQueue.flush()
  assert(updated == 0)
  current = fakeElement
  scoped.setChildren(holder, { { name = 'other' } })
  scoped.setChildren(holder, { { name = 'third' } })
  scoped.setChildren(holder, { { name = 'fourth' } })
  assert(updated == 0)
  updateQueue.flush()
  assert(updated == 1)
  current = nil
  scoped.setChildren(holder, { { name = 'again' } })
  updateQueue.flush()
  assert(updated == 1)

  local customCalls = 0
  local resolveCalls = 0
  local explicit = newScope({
    invalidate = function() customCalls = customCalls + 1 end,
    element = function()
      resolveCalls = resolveCalls + 1
      return fakeElement
    end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    publicComponents = {},
  })
  explicit.setChildren(holder, { { name = 'explicit' } })
  assert(customCalls == 1 and resolveCalls == 0)
end

local function testChildScopes()
  local parentInvalidations = 0
  local childInvalidations = 0
  local parent = newScope({
    invalidate = function() parentInvalidations = parentInvalidations + 1 end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {
      card = function(context, spec) return { name = spec.label } end,
    },
    resolver = resolver,
    registry = registry,
    publicComponents = { 'button' },
  })

  local child = parent.child {
    invalidate = function() childInvalidations = childInvalidations + 1 end,
  }
  assert(child.card({ label = 'Inherited' }).name == 'Inherited')

  local override = parent.child {
    recipes = {
      card = function(context, spec) return { name = 'Override:' .. spec.label } end,
    },
  }
  assert(override.card({ label = 'X' }).name == 'Override:X')
  assert(parent.card({ label = 'X' }).name == 'X')

  local button = child.button { label = 'Child button' }
  assert(button ~= nil and button.content ~= nil)
  parent.patch(button, { label = { props = { textColor = 'child-patch' } } })
  assert(labelProps(button).textColor == 'child-patch')
  assert(childInvalidations == 1 and parentInvalidations == 0)

  local holder = { name = 'holder', content = ui.content {} }
  child.setChildren(holder, { { name = 'child' } })
  assert(holder.content[1].name == 'child')
  assert(childInvalidations == 2 and parentInvalidations == 0)

  local updateQueue = require 'scripts.h3.ui.updateQueue'
  local updates = 0
  local fakeElement = { layout = {}, update = function() updates = updates + 1 end }
  local current = fakeElement
  local domain = parent.child {
    element = function() return current end,
  }
  domain.setChildren(holder, { { name = 'domain' } })
  updateQueue.flush()
  assert(updates == 1)
  assert(holder.content[1].name == 'domain')
  current = nil
  domain.setChildren(holder, { { name = 'gone' } })
  updateQueue.flush()
  assert(updates == 1)

  local destroyed = 0
  local owned = parent.child {
    element = function()
      return { destroy = function() destroyed = destroyed + 1 end }
    end,
    _ownsElement = true,
  }
  assert(owned ~= nil)
  parent.destroy()
  assert(destroyed == 1)
end

local function testSemanticPatchAndSelection()
  local invalidations = 0
  local scoped = newScope({
    invalidate = function() invalidations = invalidations + 1 end,
  }, {
    resolveTheme = function() return morrowind end,
    recipes = {},
    resolver = resolver,
    registry = registry,
    publicComponents = { 'button' },
  })

  local layout = scoped.button { label = 'Patch me' }
  scoped.patch(layout, { label = { props = { textColor = 'patched' } } })
  assert(labelProps(layout).textColor == 'patched')
  assert(invalidations == 1)

  scoped.setSelected(layout, true)
  assert(labelProps(layout).textColor == 'selected-text')
  assert(invalidations == 2)
  scoped.setSelected(layout, false)
  assert(labelProps(layout).textColor == 'patched')
  assert(invalidations == 3)

  layout.events.focusGain(nil, layout)
  scoped.setSelected(layout, true)
  assert(labelProps(layout).textColor == 'selected-hover')
  scoped.setSelected(layout, false)
  assert(labelProps(layout).textColor == 'morrowind-hover')
  layout.events.focusLoss(nil, layout)
  assert(labelProps(layout).textColor == 'patched')
end

local function testSelectionFallbackBaseline()
  local fallbackRegistry = newRegistry {
    fallback = {
      builder = require 'scripts.h3.components.button',
      selectable = true,
      slots = {
        root = { props = 'props', external = 'external' },
        label = { props = 'labelProps' },
      },
    },
  }
  local fallbackResolver = newResolver(fallbackRegistry, { 'fallback' })
  local fallbackTheme = themeModule.new({
    name = 'fallback-selection',
    rules = {
      {
        selector = { component = 'fallback', slot = 'label', selected = true },
        style = { props = { textColor = 'selected-only' } },
      },
    },
  }, fallbackRegistry)
  local fallbackScope = newScope({ invalidate = function() end }, {
    resolveTheme = function() return fallbackTheme end,
    recipes = {},
    resolver = fallbackResolver,
    registry = fallbackRegistry,
    publicComponents = { 'fallback' },
  })
  local layout = fallbackScope.fallback { label = 'Fallback' }
  fallbackScope.setSelected(layout, true)
  assert(labelProps(layout).textColor == 'selected-only')
  fallbackScope.setSelected(layout, false)
  assert(labelProps(layout).textColor == 'text-color')
end

local function testSelectionSurfaceTarget()
  local selectionRegistry = newRegistry {
    itemSlot = {
      builder = itemSlot,
      selectable = true,
      slots = {
        root = { props = 'props', external = 'external' },
        icon = { props = 'iconProps' },
        count = { props = 'countProps' },
        selectedChrome = { props = 'selectionProps', retained = true },
      },
    },
  }
  local selectionResolver = newResolver(selectionRegistry, { 'itemSlot' })
  local selectionTheme = themeModule.new({
    name = 'selection-surface',
    rules = {
      {
        selector = { component = 'itemSlot', slot = 'selectedChrome', selected = true },
        style = { props = { visible = true } },
      },
    },
  }, selectionRegistry)
  local selectionScope = newScope({ invalidate = function() end }, {
    resolveTheme = function() return selectionTheme end,
    recipes = {},
    resolver = selectionResolver,
    registry = selectionRegistry,
    publicComponents = { 'itemSlot' },
  })
  local layout = selectionScope.itemSlot { resource = { path = 'white' } }
  assert(layout.template == nil)
  assert(layout.type == 'Container')
  assert(#layout.content == 2)
  local normal = layout.content[1]
  local overlay = layout.content[2]
  assert(normal.template ~= nil)
  assert(overlay.template ~= nil)
  assert(normal.template ~= overlay.template)
  assert(normal.content[1].name == 'icon')
  assert(normal.content[1] ~= overlay)
  assert(normal.content[2] ~= overlay)
  assert(overlay.props.relativeSize.x == 1 and overlay.props.relativeSize.y == 1)
  assert(overlay.props.ignorePointerEvents == true)
  assert(overlay.props.visible == false)
  selectionScope.setSelected(layout, true)
  assert(overlay.props.visible == true, tostring(overlay.props.visible))
  selectionScope.setSelected(layout, false)
  assert(overlay.props.visible == false)

  local secondLayout = selectionScope.itemSlot { resource = { path = 'white' } }
  assert(secondLayout.content[1].template == normal.template)
  assert(secondLayout.content[2].template == overlay.template)
end

local function testSelectionFixedGeometry()
  local selectionRegistry = newRegistry {
    itemSlot = {
      builder = itemSlot,
      selectable = true,
      slots = {
        root = { props = 'props', external = 'external' },
        icon = { props = 'iconProps' },
        count = { props = 'countProps' },
        selectedChrome = { props = 'selectionProps', retained = true },
      },
    },
  }
  local selectionResolver = newResolver(selectionRegistry, { 'itemSlot' })
  local selectionTheme = themeModule.new({
    name = 'selection-fixed',
    rules = {
      {
        selector = { component = 'itemSlot', slot = 'selectedChrome', selected = true },
        style = { props = { visible = true } },
      },
    },
  }, selectionRegistry)
  local selectionScope = newScope({ invalidate = function() end }, {
    resolveTheme = function() return selectionTheme end,
    recipes = {},
    resolver = selectionResolver,
    registry = selectionRegistry,
    publicComponents = { 'itemSlot' },
  })
  local layout = selectionScope.itemSlot {
    resource = { path = 'white' },
    props = { size = { x = 58, y = 58 } },
  }
  assert(layout.template == nil)
  assert(layout.type == 'Widget')
  assert(layout.props.size.x == 58 and layout.props.size.y == 58)
  assert(#layout.content == 2)
  local normal = layout.content[1]
  local overlay = layout.content[2]
  assert(normal.type == 'Widget')
  assert(normal.props.relativeSize.x == 1 and normal.props.relativeSize.y == 1)
  assert(overlay.props.relativeSize.x == 1 and overlay.props.relativeSize.y == 1)
  assert(normal.template ~= overlay.template)
  assert(overlay.props.visible == false)
  selectionScope.setSelected(layout, true)
  assert(overlay.props.visible == true)
  selectionScope.setSelected(layout, false)
  assert(overlay.props.visible == false)

  local secondLayout = selectionScope.itemSlot {
    resource = { path = 'white' },
    props = { size = { x = 58, y = 58 } },
  }
  assert(secondLayout.content[1].template == normal.template)
  assert(secondLayout.content[2].template == overlay.template)
end

local function testCollectionActivationDispatch()
  local layouts = {}
  local activated
  local context = {
    itemSlot = function(options)
      local layout = { events = options.events }
      layouts[#layouts + 1] = layout
      return layout
    end,
    grid = function(options) return options end,
  }
  local items = { { name = 'First' }, { name = 'Second' } }
  local layout = itemGrid(context, {
    items = items,
    onActivate = function(item, index, target)
      activated = { item = item, index = index, layout = target }
    end,
  })

  assert(layout.items[1] == layouts[1] and layout.items[2] == layouts[2])
  assert(layouts[1].events.mouseClick == layouts[2].events.mouseClick)
  layouts[2].events.mouseClick(nil, layouts[2])
  assert(activated.item == items[2] and activated.index == 2 and activated.layout == layouts[2])
end

local function testSearchableListRegion()
  local resultLayout
  local replacements = 0
  local itemLayouts = {}
  local child = {
    listItem = function(options)
      local layout = { events = options.events }
      itemLayouts[#itemLayouts + 1] = layout
      return layout
    end,
    list = function(options)
      resultLayout = options
      return options
    end,
    setChildren = function(_, children)
      replacements = replacements + 1
      resultLayout.items = children
    end,
  }
  local context = {
    child = function() return child end,
    searchInput = function(options) return options end,
    column = function(options) return options end,
    token = function() return 4 end,
  }
  local activated
  local layout = searchableList(context, {
    items = { 'First', 'Second' },
    query = '',
    onActivate = function(item, index) activated = { item = item, index = index } end,
  })

  assert(layout.children[2].layout == resultLayout)
  assert(itemLayouts[1].events.mouseClick == itemLayouts[2].events.mouseClick)
  itemLayouts[2].events.mouseClick(nil, itemLayouts[2])
  assert(activated.item == 'Second' and activated.index == 2)
  layout.children[1].onChange 'second'
  assert(replacements == 1 and #resultLayout.items == 1)
end

local function testCollapsibleReattachment()
  local toggles = 0
  local invalidations = 0
  local layout = build(morrowind, {
    component = 'collapsible',
    title = 'Details',
    children = { { name = 'payload' } },
    onToggle = function() toggles = toggles + 1 end,
  }, function() invalidations = invalidations + 1 end)
  local function bodyCount()
    local count = 0
    for index = 1, #layout.content do
      if layout.content[index].name == 'body' then count = count + 1 end
    end
    return count
  end
  local header = layout.content[1]
  assert(bodyCount() == 0)
  header.events.mouseClick(nil, header)
  assert(bodyCount() == 1)
  header.events.mouseClick(nil, header)
  assert(bodyCount() == 0)
  header.events.mouseClick(nil, header)
  assert(bodyCount() == 1)
  header.events.mouseClick(nil, header)
  assert(bodyCount() == 0)
  assert(toggles == 4)
  assert(invalidations == 4)
end

local function testTextInputDefaults()
  local layout = textInput {}
  assert(layout.type == ui.TYPE.TextEdit)
  assert(layout.template == nil)
  assert(layout.props.size.x == 150 and layout.props.size.y == 0)
  assert(layout.props.autoSize == true)
  assert(layout.props.multiline == false)
  assert(layout.props.textAlignV == 'Center')
  assert(layout.props.textColor == 'text-color')
  assert(layout.props.textSize == 16)
  local enteredLayout = textInput { text = 'typed text', props = { size = { x = 180, y = 24 } } }
  assert(enteredLayout.props.text == 'typed text')
  assert(enteredLayout.props.textAlignV == 'Center')

  local customTemplate = {}
  local customLayout = textInput { template = customTemplate }
  assert(customLayout.template == customTemplate)
  assert(customLayout.props.textColor == 'text-color')
  assert(customLayout.props.textSize == 16)
end

testTextRuleSlots()
testThemeTokens()
testBookFrameBackground()
testBuiltinPinChromePaths()
testWindowInnerBorder()
testStateMachineAndEventReturns()
testProtectionAndTraversal()
testToggleLabelMutation()
testTabStyleRetention()
testTabbedWindowControlledSelection()
testSelectorAlignment()
testSearchInputHeight()
testItemSlotChrome()
testChromeCacheAndSkinSwap()
testTextInputDefaults()
testImmediateRecipeConstructors()
testInvalidatorCallbackOrder()
testExplainTracePreserved()
testSharedRuntimeDispatcher()
testInteractionRedrawCoalescing()
testElementRedrawDeduplicationAndRequeue()
testSetChildren()
testScopeElementResolver()
testChildScopes()
testSemanticPatchAndSelection()
testSelectionFallbackBaseline()
testSelectionSurfaceTarget()
testSelectionFixedGeometry()
testCollectionActivationDispatch()
testSearchableListRegion()
testCollapsibleReattachment()

print 'H3UI runtime state tests passed'
