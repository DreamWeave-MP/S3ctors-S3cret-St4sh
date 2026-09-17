---@omw-context menu|player

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

local metadata = {
  kind = true,
  control = true,
  component = true,
  role = true,
  variant = true,
  tone = true,
  class = true,
  classes = true,
  style = true,
  label = true,
  labelClass = true,
  labelClasses = true,
  labelStyle = true,
  labelProps = true,
  rowRole = true,
  rowClass = true,
  rowClasses = true,
  rowStyle = true,
  rowName = true,
  rowProps = true,
  rowExternal = true,
}

local function buildControl(ctx, field)
  local kind = field.kind or field.control or 'text'
  local component = field.component or kindToComponent[kind]
  assert(component, 'Unknown H3 UI settings field kind: ' .. tostring(kind))
  local spec = {
    component = component,
    role = field.role or 'control',
    variant = field.variant,
    tone = field.tone,
    class = field.class,
    classes = field.classes,
    style = field.style,
  }
  for key, value in next, field do
    if not metadata[key] then spec[key] = value end
  end
  if component == 'textInput' and field.value ~= nil and spec.text == nil then
    spec.text = tostring(field.value)
  end
  return ctx.component(component, spec)
end

local function settings(ctx, spec)
  local children = {}
  if spec.title ~= nil then
    children[#children + 1] =
      ctx.component('text', { role = 'title', text = spec.title, style = spec.titleStyle })
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
        text = field.label,
        props = field.labelProps,
      })
    end
    rowChildren[#rowChildren + 1] = buildControl(ctx, field)
    children[#children + 1] = ctx.component('row', {
      role = field.rowRole or 'field',
      class = field.rowClass,
      classes = field.rowClasses,
      style = field.rowStyle,
      name = field.rowName or ('field_' .. tostring(index)),
      props = field.rowProps,
      external = field.rowExternal,
      gap = field.gap or spec.fieldGap or 4,
      children = rowChildren,
    })
  end
  for index = 1, #(spec.children or {}) do
    children[#children + 1] = spec.children[index]
  end

  return ctx.component('column', {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    name = spec.name,
    props = spec.props,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    gap = spec.gap or 4,
    children = children,
  })
end

return settings
