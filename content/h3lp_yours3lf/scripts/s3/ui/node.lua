---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local selector = require 'scripts.s3.ui.selector'

local componentMarker = {}
local recipeMarker = {}

local function component(name, spec, defaults)
  spec = spec or {}
  defaults = defaults or {}
  assert(type(name) == 'string' and name ~= '', 'H3 UI component node requires a component name')
  assert(merge.isPlainTable(spec), 'H3 UI component spec must be a plain table')

  local args = merge.shallowCopy(spec.args or {})
  if spec.children ~= nil and args.children == nil and args.content == nil then
    args.children = spec.children
  end
  if spec.content ~= nil and args.content == nil and args.children == nil then
    args.content = spec.content
  end
  if spec.items ~= nil and args.items == nil then args.items = spec.items end

  return {
    [componentMarker] = true,
    component = name,
    recipe = spec.recipe ~= nil and spec.recipe or defaults.recipe,
    role = spec.role,
    variant = spec.variant,
    tone = spec.tone,
    density = spec.density ~= nil and spec.density or defaults.density,
    state = spec.state,
    classes = selector.classes(spec.classes, spec.class),
    args = args,
    style = spec.style,
  }
end

local function recipe(spec)
  assert(merge.isPlainTable(spec), 'H3 UI recipe spec must be a plain table')
  assert(type(spec.recipe) == 'string' and spec.recipe ~= '', 'H3 UI recipe spec requires recipe')
  return {
    [recipeMarker] = true,
    spec = merge.shallowCopy(spec),
  }
end

local function isComponent(value)
  return type(value) == 'table' and rawget(value, componentMarker) == true
end

local function isRecipe(value)
  return type(value) == 'table' and rawget(value, recipeMarker) == true
end

return {
  component = component,
  isComponent = isComponent,
  isRecipe = isRecipe,
  recipe = recipe,
}
