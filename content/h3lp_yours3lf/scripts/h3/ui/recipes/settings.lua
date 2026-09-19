---@omw-context menu|player

local Assert, Error, Next, StrFormat, ToString, Type =
  assert, error, next, string.format, tostring, type

local FieldMetadata = {
  kind = true,
  gap = true,
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

local SupportedKinds = {
  toggle = true,
  slider = true,
  numberInput = true,
  selector = true,
  textInput = true,
}

---@param ctx H3UI.RecipeContext
---@param field H3UI.SettingsField
---@return openmw.ui.Layout
local function buildControl(ctx, field)
  if not SupportedKinds[field.kind] then
    Error(StrFormat('Unknown H3 UI settings field kind: %s', ToString(field.kind)))
  end
  local control = {}
  for key, value in Next, field do
    if not FieldMetadata[key] then control[key] = value end
  end
  control.role = field.role or 'control'
  control.variant = field.variant
  control.tone = field.tone
  control.class = field.class
  control.classes = field.classes
  control.style = field.style
  return ctx.component(field.kind, control)
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.SettingsOptions
---@return openmw.ui.Layout
local function settings(ctx, spec)
  local children = {}
  if spec.title then
    children[#children + 1] =
      ctx.text { role = 'title', text = spec.title, style = spec.titleStyle }
  end

  local fields = spec.fields or {}
  Assert(Type(fields) == 'table', 'H3 UI settings fields must be a table')
  for index = 1, #fields do
    local field = fields[index]
    Assert(Type(field) == 'table', 'H3 UI settings fields must be tables')
    local rowChildren = {}
    if field.label then
      rowChildren[#rowChildren + 1] = ctx.text {
        role = 'label',
        class = field.labelClass,
        classes = field.labelClasses,
        style = field.labelStyle,
        text = field.label,
        props = field.labelProps,
      }
    end
    rowChildren[#rowChildren + 1] = buildControl(ctx, field)
    children[#children + 1] = ctx.row {
      role = field.rowRole or 'field',
      class = field.rowClass,
      classes = field.rowClasses,
      style = field.rowStyle,
      name = field.rowName or StrFormat('field_%s', ToString(index)),
      props = field.rowProps,
      external = field.rowExternal,
      gap = field.gap or spec.fieldGap or ctx.token 'spacing.sm',
      children = rowChildren,
    }
  end
  local extraChildren = spec.children or {}
  for index = 1, #extraChildren do
    children[#children + 1] = extraChildren[index]
  end

  return ctx.column {
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
    gap = spec.gap or ctx.token 'spacing.sm',
    children = children,
  }
end

return settings
