---@omw-context menu|player

local constructors = require 'scripts.s3.ui.constructors'
local merge = require 'scripts.s3.ui.merge'
local mutation = require 'scripts.s3.ui.mutation'
local specModule = require 'scripts.s3.ui.spec'
local token = require 'scripts.s3.ui.token'
local updateQueue = require 'scripts.s3.ui.updateQueue'

---@class H3UI.ScopeOptions
---@field invalidate? fun() Called when H3UI-owned interaction or recipe state needs a mounted Element update.
---@field element? fun(): openmw.ui.Element? Returns the currently mounted OpenMW UI element owned by this scope.
---@field recipes? table<string, function>

---@param options? H3UI.ScopeOptions
---@param environment table
---@return H3UI.Scope
local function new(options, environment)
  options = options or {}
  assert(merge.isPlainTable(options), 'H3 UI scope options must be a plain table')
  assert(options.density == nil, 'H3 UI density was removed')

  if options.invalidate ~= nil then
    assert(type(options.invalidate) == 'function', 'H3 UI invalidate must be a function')
  end
  if options.element ~= nil then
    assert(type(options.element) == 'function', 'H3 UI element must be a function')
  end

  local invalidate = options.invalidate
  if invalidate == nil and options.element then
    local updateRequest = {
      pending = false,
      resolveElement = options.element,
    }
    invalidate = function() updateQueue.queue(updateRequest) end
  end

  local recipes = environment.recipes
  if options.recipes ~= nil then
    assert(merge.isPlainTable(options.recipes), 'H3 UI scope recipes must be a plain table')
    recipes = merge.shallowCopy(environment.recipes)
    for name, recipe in next, options.recipes do
      assert(type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')
      assert(type(recipe) == 'function', 'H3 UI recipe must be a function: ' .. tostring(name))
      recipes[name] = recipe
    end
  end

  local scope = {
    invalidate = invalidate,
    recipes = recipes,
    resolveTheme = environment.resolveTheme,
  }

  ---Build a component by dynamic name. Prefer the named constructors such as `ui.button` in normal code.
  function scope.component(name, spec)
    assert(type(name) == 'string' and name ~= '', 'H3 UI component name must be a string')
    return environment.resolver.component(scope, name, spec or {})
  end

  ---Build a recipe by dynamic name. Prefer named recipe constructors such as `ui.settings` in normal code.
  function scope.recipe(name, spec)
    assert(type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')
    return environment.resolver.recipe(scope, name, spec or {})
  end

  local portableScope
  function scope.explain(spec) return environment.resolver.explain(scope, spec) end
  function scope.resolve(spec) return environment.resolver.build(scope, spec) end
  function scope.spec()
    if portableScope == nil then
      portableScope = specModule.newScope(environment.publicComponents, recipes)
    end
    return portableScope
  end
  function scope.token(path) return token.ref(path) end

  ---Replace a mounted layout's content with fresh child layouts and invalidate the owning scope.
  ---Allocates one Content object. The layout keeps its identity; child layouts are rebuilt by the
  ---caller. Removed layouts leave the rendered subtree on update; explicitly supplied Elements
  ---remain caller-owned. Safe to call from event handlers, including handlers on widgets outside
  ---the replaced subtree.
  ---@param layout openmw.ui.Layout Mounted layout whose content is replaced.
  ---@param children openmw.ui.LayoutOrElement[] Fresh child layouts.
  function scope.setChildren(layout, children)
    mutation.setChildren(layout, children, scope.invalidate)
  end

  ---Create a child scope sharing this scope's theme, recipes, and tokens while owning a
  ---separate invalidation target. Local recipes are inherited and may be overridden. Element
  ---lifetime stays with the application; destroy nested Elements with their owning root.
  ---@param childOptions? H3UI.ScopeOptions
  ---@return H3UI.Scope
  function scope.child(childOptions)
    childOptions = childOptions or {}
    assert(merge.isPlainTable(childOptions), 'H3 UI child scope options must be a plain table')
    local childRecipes = {}
    for name, recipe in next, scope.recipes do
      childRecipes[name] = recipe
    end
    if childOptions.recipes ~= nil then
      assert(merge.isPlainTable(childOptions.recipes), 'H3 UI scope recipes must be a plain table')
      for name, recipe in next, childOptions.recipes do
        childRecipes[name] = recipe
      end
    end
    return new({
      invalidate = childOptions.invalidate,
      element = childOptions.element,
      recipes = childRecipes,
    }, environment)
  end

  constructors(
    scope,
    environment.publicComponents,
    recipes,
    function(name, spec) return scope.component(name, spec) end,
    function(name, spec) return scope.recipe(name, spec) end
  )

  return scope
end

return new
