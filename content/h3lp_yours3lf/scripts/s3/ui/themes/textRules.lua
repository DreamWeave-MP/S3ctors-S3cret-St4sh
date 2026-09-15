---@omw-context menu|player

local token = require 'scripts.s3.ui.token'

local function textStyle(color, size)
  return {
    props = {
      textColor = token.ref(color),
      textSize = token.ref(size),
    },
  }
end

local function addTextRule(rules, component, slot, color, size)
  rules[#rules + 1] = {
    selector = { component = component, slot = slot },
    style = textStyle(color, size),
  }
end

local function addRootTextRule(rules, component, color, size)
  addTextRule(rules, component, 'root', color, size)
end

local function addSlotTextRule(rules, component, slot, color, size)
  addTextRule(rules, component, slot, color, size)
end

local function addStateTextRule(rules, component, slot, state, color)
  rules[#rules + 1] = {
    selector = { component = component, slot = slot, state = state },
    style = { props = { textColor = token.ref(color) } },
  }
end

---@return H3UI.ThemeRule[]
local function new()
  local rules = {
    {
      selector = { component = 'text' },
      style = textStyle('color.text', 'textSize.normal'),
    },
    {
      selector = { component = 'text', role = 'title' },
      style = textStyle('color.header', 'textSize.header'),
    },
    {
      selector = { component = 'dialog', slot = 'title' },
      style = textStyle('color.header', 'textSize.header'),
    },
    {
      selector = { component = 'bookFrame', slot = 'title' },
      style = textStyle('color.header', 'textSize.header'),
    },
    {
      selector = { component = 'caption', slot = 'text' },
      style = textStyle('color.header', 'textSize.header'),
    },
    {
      selector = { component = 'window', slot = 'captionText' },
      style = textStyle('color.header', 'textSize.header'),
    },
    {
      selector = { component = 'window', slot = 'background' },
      style = {
        props = {
          color = token.ref 'color.background',
          alpha = token.ref 'transparency.menu',
        },
      },
    },
  }

  local rootTextTargets = { 'numberInput', 'textInput' }
  for index = 1, #rootTextTargets do
    addRootTextRule(rules, rootTextTargets[index], 'color.text', 'textSize.normal')
  end

  local slotTextTargets = {
    { 'button', 'label' },
    { 'iconButton', 'label' },
    { 'listItem', 'label' },
    { 'selector', 'label' },
    { 'tabs', 'label' },
    { 'tabs', 'selectedLabel' },
    { 'toggle', 'label' },
    { 'collapsible', 'headerLabel' },
    { 'itemSlot', 'count' },
    { 'tooltip', 'text' },
    { 'searchInput', 'input' },
  }
  for index = 1, #slotTextTargets do
    local target = slotTextTargets[index]
    addSlotTextRule(rules, target[1], target[2], 'color.text', 'textSize.normal')
  end

  local stateComponents = { 'button', 'iconButton', 'listItem', 'toggle' }
  for index = 1, #stateComponents do
    local component = stateComponents[index]
    addStateTextRule(rules, component, 'label', 'hover', 'color.textHover')
    addStateTextRule(rules, component, 'label', 'pressed', 'color.textPressed')
  end

  return rules
end

return new
