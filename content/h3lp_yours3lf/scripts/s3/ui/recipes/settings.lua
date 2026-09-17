---@omw-context menu|player

---@class H3UI.SettingsFieldBase
---@field label? string
---@field gap? number
---@field role? string
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field labelClass? string
---@field labelClasses? string[]|table<string, boolean>
---@field labelStyle? table
---@field labelProps? table
---@field rowRole? string
---@field rowClass? string
---@field rowClasses? string[]|table<string, boolean>
---@field rowStyle? table
---@field rowName? string
---@field rowProps? table
---@field rowExternal? table

---@class H3UI.SettingsToggleField: H3UI.SettingsFieldBase
---@field kind 'toggle'
---@field value? boolean
---@field onChange? fun(value: boolean, layout: openmw.ui.Layout): any
---@field onLabel? string
---@field offLabel? string

---@class H3UI.SettingsSliderField: H3UI.SettingsFieldBase
---@field kind 'slider'
---@field value? number
---@field min? number
---@field max? number
---@field step? number
---@field onChange? fun(value: number, layout: openmw.ui.Layout): any
---@field fillProps? table
---@field emptyProps? table

---@class H3UI.SettingsNumberInputField: H3UI.SettingsFieldBase
---@field kind 'numberInput'
---@field value? number
---@field min? number
---@field max? number
---@field step? number
---@field integer? boolean
---@field onChange? fun(value: number, layout: openmw.ui.Layout): any
---@field onCommit? fun(value: number, layout: openmw.ui.Layout): any

---@class H3UI.SettingsSelectorField: H3UI.SettingsFieldBase
---@field kind 'selector'
---@field items? (string|H3.SelectorItem)[]
---@field selected? integer
---@field onSelect? fun(index: integer, item: string|H3.SelectorItem): any
---@field emptyLabel? string
---@field buttonProps? table
---@field iconProps? table
---@field labelProps? table
---@field labelTemplate? openmw.ui.Template

---@class H3UI.SettingsTextInputField: H3UI.SettingsFieldBase
---@field kind 'textInput'
---@field text? string
---@field onChange? fun(value: string, layout: openmw.ui.Layout): any

---@alias H3UI.SettingsField H3UI.SettingsToggleField|H3UI.SettingsSliderField|H3UI.SettingsNumberInputField|H3UI.SettingsSelectorField|H3UI.SettingsTextInputField

---@class H3UI.SettingsOptions
---@field title? string
---@field fields? H3UI.SettingsField[]
---@field fieldGap? number
---@field gap? number
---@field titleStyle? table
---@field children? openmw.ui.Layout[]
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

local fieldMetadata = {
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

local supportedKinds = {
  toggle = true,
  slider = true,
  numberInput = true,
  selector = true,
  textInput = true,
}

local function buildControl(ctx, field)
  assert(supportedKinds[field.kind], 'Unknown H3 UI settings field kind: ' .. tostring(field.kind))
  local control = {}
  for key, value in next, field do
    if not fieldMetadata[key] then control[key] = value end
  end
  control.role = field.role or 'control'
  control.variant = field.variant
  control.tone = field.tone
  control.class = field.class
  control.classes = field.classes
  control.style = field.style
  return ctx.component(field.kind, control)
end

local function settings(ctx, spec)
  local children = {}
  if spec.title ~= nil then
    children[#children + 1] =
      ctx.text { role = 'title', text = spec.title, style = spec.titleStyle }
  end

  local fields = spec.fields or {}
  assert(type(fields) == 'table', 'H3 UI settings fields must be a table')
  for index = 1, #fields do
    local field = fields[index]
    assert(type(field) == 'table', 'H3 UI settings fields must be tables')
    local rowChildren = {}
    if field.label ~= nil then
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
      name = field.rowName or ('field_' .. tostring(index)),
      props = field.rowProps,
      external = field.rowExternal,
      gap = field.gap or spec.fieldGap or ctx.token 'spacing.sm',
      children = rowChildren,
    }
  end
  for index = 1, #(spec.children or {}) do
    children[#children + 1] = spec.children[index]
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
