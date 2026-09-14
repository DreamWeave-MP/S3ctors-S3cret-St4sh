---@omw-context menu|player

local async = require 'openmw.async'
local merge = require 'scripts.s3.ui.merge'

local controlKeys = {
  toggle = { 'value', 'onChange', 'onLabel', 'offLabel', 'label' },
  slider = { 'value', 'min', 'max', 'step', 'trackWidth', 'onChange' },
  numberInput = { 'value', 'min', 'max', 'step', 'integer', 'onChange', 'onCommit' },
  selector = { 'items', 'selected', 'onSelect', 'emptyLabel' },
  textInput = { 'text' },
}

local kindToComponent = {
  toggle = 'toggle',
  slider = 'slider',
  number = 'numberInput',
  numberInput = 'numberInput',
  select = 'selector',
  selector = 'selector',
  text = 'textInput',
  textInput = 'textInput',
}

local function copyKnown(args, field, keys)
  for index = 1, #keys do
    local key = keys[index]
    if field[key] ~= nil then args[key] = field[key] end
  end
end

local function buildControl(ctx, field, index)
  local kind = field.kind or field.control or 'text'
  local component = field.component or kindToComponent[kind]
  assert(component, 'Unknown H3 UI settings field kind: ' .. tostring(kind))

  local args = merge.shallowCopy(field.args or {})
  local keys = controlKeys[component]
  if keys then copyKnown(args, field, keys) end

  if field.name ~= nil then args.name = field.name end
  if field.props ~= nil then args.props = field.props end
  if field.external ~= nil then args.external = field.external end
  if field.events ~= nil then args.events = field.events end
  if field.userData ~= nil then args.userData = field.userData end
  if field.template ~= nil then args.template = field.template end

  if component == 'textInput' then
    if field.value ~= nil and args.text == nil then args.text = tostring(field.value) end
    if field.onChange then
      local events = merge.copy(args.events or {})
      local previousTextChanged = events.textChanged
      events.textChanged = async:callback(function(value, layout)
        layout.props.text = value
        field.onChange(value)
        if previousTextChanged then return previousTextChanged(value, layout) end
        return true
      end)
      args.events = events
    end
  end

  return ctx.component(component, {
    role = field.role or 'control',
    variant = field.variant,
    tone = field.tone,
    density = field.density,
    class = field.class,
    classes = field.classes,
    style = field.style,
    args = args,
  })
end

local function settings(ctx, spec)
  local children = {}

  if spec.title ~= nil then
    children[#children + 1] = ctx.component('text', {
      role = 'title',
      args = { text = spec.title },
      style = spec.titleStyle,
    })
  end

  local fields = spec.fields or spec.entries or {}
  for index = 1, #fields do
    local field = fields[index]
    assert(type(field) == 'table', 'H3 UI settings fields must be tables')

    local rowChildren = {}
    if field.label ~= nil then
      rowChildren[#rowChildren + 1] = ctx.component('text', {
        role = 'label',
        class = field.labelClass,
        classes = field.labelClasses,
        style = field.labelStyle,
        args = {
          text = field.label,
          props = field.labelProps,
        },
      })
    end
    rowChildren[#rowChildren + 1] = buildControl(ctx, field, index)

    children[#children + 1] = ctx.component('row', {
      role = field.rowRole or 'field',
      class = field.rowClass,
      classes = field.rowClasses,
      style = field.rowStyle,
      args = {
        name = field.rowName or ('field_' .. tostring(index)),
        props = field.rowProps,
        external = field.rowExternal,
        children = rowChildren,
      },
    })
  end

  if spec.children then
    for index = 1, #spec.children do children[#children + 1] = spec.children[index] end
  end

  local args = merge.shallowCopy(spec.args or {})
  if spec.name ~= nil then args.name = spec.name end
  if spec.props ~= nil then args.props = spec.props end
  if spec.external ~= nil then args.external = spec.external end
  if spec.events ~= nil then args.events = spec.events end
  if spec.userData ~= nil then args.userData = spec.userData end
  if spec.template ~= nil then args.template = spec.template end
  args.children = children

  return ctx.component('column', {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    density = spec.density,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    args = args,
  })
end

return settings
