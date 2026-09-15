---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local token = require 'scripts.s3.ui.token'

---@class H3UI.ScopeOptions
---@field density? string
---@field invalidate? fun() Called after a runtime state change that needs a mounted Element update.
---@field recipes? table<string, function>

---@param options? H3UI.ScopeOptions
---@param environment table
---@return H3UI.Scope
local function new(options, environment)
  options = options or {}
  assert(merge.isPlainTable(options), 'H3 UI scope options must be a plain table')

  if options.invalidate ~= nil then
    assert(type(options.invalidate) == 'function', 'H3 UI invalidate must be a function')
  end

  local recipes = {}
  for name, recipe in next, environment.recipes do
    recipes[name] = recipe
  end

  if options.recipes ~= nil then
    assert(merge.isPlainTable(options.recipes), 'H3 UI scope recipes must be a plain table')
    for name, recipe in next, options.recipes do
      assert(type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')
      assert(type(recipe) == 'function', 'H3 UI recipe must be a function: ' .. tostring(name))
      recipes[name] = recipe
    end
  end

  local scope = {
    density = options.density,
    invalidate = options.invalidate,
    recipes = recipes,
    resolveTheme = environment.resolveTheme,
  }

  function scope.build(spec) return environment.resolver.build(scope, spec) end
  function scope.explain(spec) return environment.resolver.explain(scope, spec) end
  function scope.token(path) return token.ref(path) end

  return scope
end

return new
