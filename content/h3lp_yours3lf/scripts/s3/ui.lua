---@omw-context menu|player
---@module 'scripts.s3.ui'

local builtinRecipes = require 'scripts.s3.ui.recipes.init'
local componentDefinitions = require 'scripts.s3.ui.components'
local constants = require 'scripts.s3.ui.constants'
local newRegistry = require 'scripts.s3.ui.registry'
local newResolver = require 'scripts.s3.ui.resolver'
local newScope = require 'scripts.s3.ui.scope'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

local registry = newRegistry(componentDefinitions)
local morrowindTheme = themeModule.new(require 'scripts.s3.ui.themes.morrowind', registry)
local resolver = newResolver(registry, builtinRecipes)

local environment = {
  defaultTheme = morrowindTheme,
  recipes = builtinRecipes,
  resolver = resolver,
}

---@class H3UI.Scope
---@field theme table
---@field density? string
---@field build fun(spec: table): openmw.ui.Layout
---@field explain fun(spec: table): table
---@field token fun(path: string): table

---@class H3UI
---@field UNSET table Explicit style-removal sentinel.
---@field themes table<string, table>
---@field build fun(spec: table): openmw.ui.Layout
---@field explain fun(spec: table): table
---@field scope fun(options?: table): H3UI.Scope
---@field theme fun(spec: table): table
---@field token fun(path: string): table
---@field slots fun(component: string): string[]
local H3UI = {
  UNSET = constants.UNSET,
  themes = {
    morrowind = morrowindTheme,
  },
}

function H3UI.theme(spec) return themeModule.new(spec, registry) end
function H3UI.token(path) return token.ref(path) end
function H3UI.slots(component) return registry.slots(component) end
function H3UI.scope(options) return newScope(options, environment) end

local defaultScope = H3UI.scope()

function H3UI.build(spec) return defaultScope.build(spec) end
function H3UI.explain(spec) return defaultScope.explain(spec) end

return H3UI
