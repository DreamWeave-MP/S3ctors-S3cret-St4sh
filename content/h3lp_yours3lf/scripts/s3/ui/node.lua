---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local selector = require 'scripts.s3.ui.selector'

local componentMarker = {}
local recipeMarker = {}

local reserved = {
  component = true,
  recipe = true,
  role = true,
  variant = true,
  tone = true,
  class = true,
  classes = true,
  style = true,
  invalidate = true,
}

local function component(name, spec, defaults)
  spec = spec or {}
  defaults = defaults or {}
  assert(type(name) == 'string' and name ~= '', 'H3 UI component node requires a component name')
  assert(merge.isPlainTable(spec), 'H3 UI component spec must be a plain table')
  assert(spec.args == nil, 'H3 UI component args are flat; move fields out of args')
  assert(
    spec.density == nil,
    'H3 UI density was removed; style spacing explicitly or through theme rules'
  )
  assert(
    spec.state == nil,
    'H3 UI instance state was removed; interactive state is component-owned'
  )
  local args = {}
  for key, value in next, spec do
    if not reserved[key] then args[key] = value end
  end

  return {
    [componentMarker] = true,
    component = name,
    recipe = spec.recipe ~= nil and spec.recipe or defaults.recipe,
    role = spec.role,
    selected = type(spec.selected) == 'boolean' and spec.selected or nil,
    variant = spec.variant,
    tone = spec.tone,
    classes = selector.classes(spec.classes, spec.class),
    args = args,
    style = spec.style,
    invalidate = spec.invalidate ~= nil and spec.invalidate or defaults.invalidate,
  }
end

local function recipe(spec)
  assert(merge.isPlainTable(spec), 'H3 UI recipe spec must be a plain table')
  assert(type(spec.recipe) == 'string' and spec.recipe ~= '', 'H3 UI recipe spec requires recipe')
  assert(spec.args == nil, 'H3 UI recipe args are flat; move fields out of args')
  assert(spec.density == nil, 'H3 UI density was removed')
  assert(spec.state == nil, 'H3 UI instance state was removed')
  return {
    [recipeMarker] = true,
    spec = merge.shallowCopy(spec),
  }
end

local function isComponent(value)
  return type(value) == 'table' and rawget(value, componentMarker) == true
end

local function isRecipe(value) return type(value) == 'table' and rawget(value, recipeMarker) == true end

return {
  component = component,
  isComponent = isComponent,
  isRecipe = isRecipe,
  recipe = recipe,
}
