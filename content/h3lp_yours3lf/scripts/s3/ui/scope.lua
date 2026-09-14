---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

local function new(options, environment)
  options = options or {}
  assert(merge.isPlainTable(options), 'H3 UI scope options must be a plain table')

  local activeTheme = options.theme or environment.defaultTheme
  assert(themeModule.isTheme(activeTheme), 'H3 UI scope theme must be a compiled theme')

  local recipes = {}
  for name, recipe in next, environment.recipes do recipes[name] = recipe end

  if options.recipes ~= nil then
    assert(merge.isPlainTable(options.recipes), 'H3 UI scope recipes must be a plain table')
    for name, recipe in next, options.recipes do
      assert(type(name) == 'string' and name ~= '', 'H3 UI recipe name must be a string')
      assert(type(recipe) == 'function', 'H3 UI recipe must be a function: ' .. tostring(name))
      recipes[name] = recipe
    end
  end

  local scope = {
    theme = activeTheme,
    density = options.density,
    recipes = recipes,
  }

  function scope.build(spec) return environment.resolver.build(scope, spec) end
  function scope.explain(spec) return environment.resolver.explain(scope, spec) end
  function scope.token(path) return token.ref(path) end

  return scope
end

return new
