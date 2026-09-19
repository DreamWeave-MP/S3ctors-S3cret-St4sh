---@omw-context menu|player

local constructors = require 'scripts.h3.ui.constructors'
local merge = require 'scripts.h3.ui.merge'
local mutation = require 'scripts.h3.ui.mutation'
local specModule = require 'scripts.h3.ui.spec'
local token = require 'scripts.h3.ui.token'
local updateQueue = require 'scripts.h3.ui.updateQueue'

local Assert, Error, Next, StrFormat, ToString, Type =
  assert, error, next, string.format, tostring, type

---@param options? H3UI.ScopeOptions
---@param environment H3UI.Environment
---@param inheritedRecipes? table<string, H3UI.Recipe>
---@param inheritedResolveTheme? fun(): H3UI.Theme
---@return H3UI.Scope
local function new(options, environment, inheritedRecipes, inheritedResolveTheme)
  options = options or {}

  Assert(merge.isPlainTable(options), 'H3 UI scope options must be a plain table')

  if options.invalidate ~= nil then
    Assert(Type(options.invalidate) == 'function', 'H3 UI invalidate must be a function')
  end

  if options.element ~= nil then
    Assert(Type(options.element) == 'function', 'H3 UI element must be a function')
  end

  local invalidate = options.invalidate
  if not invalidate and options.element then
    local updateRequest = {
      pending = false,
      resolveElement = options.element,
    }
    ---@return nil
    invalidate = function() updateQueue.queue(updateRequest) end
  end

  local recipes = inheritedRecipes or environment.recipes
  if options.recipes ~= nil then
    Assert(merge.isPlainTable(options.recipes), 'H3 UI scope recipes must be a plain table')

    recipes = merge.shallowCopy(recipes)

    for name, recipe in Next, options.recipes do
      Assert(Type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')

      if Type(recipe) ~= 'function' then
        Error(StrFormat('H3 UI recipe must be a function: %s', ToString(name)))
      end

      recipes[name] = recipe
    end
  end

  local childScopes = {}
  local destroyed = false
  local scope = {
    invalidate = invalidate,
    recipes = recipes,
    resolveTheme = inheritedResolveTheme or environment.resolveTheme,
  }

  ---Build a component by dynamic name. Prefer the named constructors such as `ui.button` in normal code.
  ---@param name string
  ---@param spec? table
  ---@return openmw.ui.Layout
  function scope.component(name, spec)
    Assert(Type(name) == 'string' and name ~= '', 'H3 UI component name must be a string')
    return environment.resolver.component(scope, name, spec or {})
  end

  ---Build a recipe by dynamic name. Prefer named recipe constructors such as `ui.settings` in normal code.
  ---@param name string
  ---@param spec? table
  ---@return openmw.ui.Layout
  function scope.recipe(name, spec)
    Assert(Type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')
    return environment.resolver.recipe(scope, name, spec or {})
  end

  local portableScope
  ---@param spec H3UI.Spec|H3UI.Document
  ---@return table
  function scope.explain(spec) return environment.resolver.explain(scope, spec) end
  ---@param spec H3UI.Spec|H3UI.Document
  ---@return openmw.ui.Layout
  function scope.resolve(spec) return environment.resolver.build(scope, spec) end
  ---@return H3UI.SpecScope
  function scope.spec()
    if not portableScope then
      portableScope = specModule.newScope(environment.publicComponents, recipes)
    end
    return portableScope
  end
  ---@param path string
  ---@return H3UI.TokenReference
  function scope.token(path) return token.ref(path) end

  ---Replace a mounted layout's content with fresh child layouts and invalidate the owning scope.
  ---Allocates one Content object. The layout keeps its identity; child layouts are rebuilt by the
  ---caller. Removed layouts leave the rendered subtree on update; explicitly supplied Elements
  ---remain caller-owned. Safe to call from event handlers, including handlers on widgets outside
  ---the replaced subtree.
  ---@param layout openmw.ui.Layout Mounted layout whose content is replaced.
  ---@param children openmw.ui.LayoutOrElement[] Fresh child layouts.
  ---@return nil
  function scope.setChildren(layout, children)
    mutation.setChildren(layout, children, scope.invalidate)
  end

  ---Patch a retained component slot and invalidate its owning scope.
  ---@param layout openmw.ui.Layout H3 component layout returned by this scope or one of its children.
  ---@param styles table<string, H3UI.Style> Slot styles containing props or external values.
  ---@return nil
  function scope.patch(layout, styles) environment.registry.patch(layout, styles) end

  ---Change a selectable component's retained selected state and invalidate this scope.
  ---@param layout openmw.ui.Layout H3 selectable component layout.
  ---@param selected boolean
  ---@return nil
  function scope.setSelected(layout, selected) environment.registry.setSelected(layout, selected) end

  ---Destroy Elements created by this scope and its child scopes.
  ---@return nil
  function scope.destroy()
    if destroyed then return end

    destroyed = true

    for index = #childScopes, 1, -1 do
      childScopes[index].destroy()
    end

    if not options._ownsElement or not options.element then return end

    local element = options.element()
    if element then element:destroy() end
  end

  ---Create a child scope sharing this scope's theme, recipes, and tokens while owning a
  ---separate invalidation target. Local recipes are inherited and may be overridden. Element
  ---lifetime stays with the application. Destroy child Elements explicitly when tearing down
  ---the owning surface; OpenMW detaches nested Elements rather than destroying them.
  ---@param childOptions? H3UI.ScopeOptions
  ---@return H3UI.Scope
  function scope.child(childOptions)
    childOptions = childOptions or {}

    Assert(merge.isPlainTable(childOptions), 'H3 UI child scope options must be a plain table')

    local child = new({
      invalidate = childOptions.invalidate,
      element = childOptions.element,
      recipes = childOptions.recipes,
      _ownsElement = childOptions._ownsElement,
    }, environment, scope.recipes, scope.resolveTheme)

    childScopes[#childScopes + 1] = child

    return child
  end

  constructors(
    scope,
    environment.publicComponents,
    recipes,
    ---@param name string
    ---@param spec table
    ---@return openmw.ui.Layout
    function(name, spec) return scope.component(name, spec) end,
    ---@param name string
    ---@param spec table
    ---@return openmw.ui.Layout
    function(name, spec) return scope.recipe(name, spec) end
  )

  return scope
end

return new
