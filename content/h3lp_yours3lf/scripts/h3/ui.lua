---@omw-context menu|player
---@module 'scripts.h3.ui'

local MorrowindSpec = require 'scripts.h3.ui.themes.morrowind'
local StarwindSpec = require 'scripts.h3.ui.themes.starwind'

local appearance = require 'scripts.h3.ui.appearance'
local builtinRecipes = require 'scripts.h3.ui.recipes.init'
local chrome = require 'scripts.h3.ui.chrome'
local componentDefinitions = require 'scripts.h3.ui.components'
local constants = require 'scripts.h3.ui.constants'
local newRegistry = require 'scripts.h3.ui.registry'
local newResolver = require 'scripts.h3.ui.resolver'
local newScope = require 'scripts.h3.ui.scope'
local specModule = require 'scripts.h3.ui.spec'
local themeModule = require 'scripts.h3.ui.theme'
local token = require 'scripts.h3.ui.token'

local Error, Next, StrFormat = error, next, string.format

local Registry = newRegistry(componentDefinitions)
local PublicComponents = Registry.publicComponents()

local MorrowindTheme = themeModule.new(MorrowindSpec, Registry)
local StarwindTheme = themeModule.new(StarwindSpec, Registry, MorrowindTheme)

appearance.initialize(Registry, {
  { id = 'morrowind', spec = MorrowindSpec, theme = MorrowindTheme },
  { id = 'starwind', spec = StarwindSpec, theme = StarwindTheme },
})

local Resolver = newResolver(Registry, PublicComponents)

local Environment = {
  resolveTheme = appearance.activeTheme,
  recipes = builtinRecipes,
  resolver = Resolver,
  registry = Registry,
  publicComponents = PublicComponents,
}

local H3UI = {
  DOCUMENT_VERSION = specModule.DOCUMENT_VERSION,
  UNSET = constants.UNSET,
}

---@param spec H3UI.ThemeRegistration
---@return nil
function H3UI.registerTheme(spec) return appearance.registerTheme(spec) end

---@param path string
---@return H3UI.TokenReference
function H3UI.token(path) return token.ref(path) end

---@param component string
---@return string[]
function H3UI.slots(component) return Registry.slots(component) end

---@param options H3UI.NineSliceOptions
---@return openmw.ui.Layout
function H3UI.nineSlice(options) return chrome.nineSlice(options) end

---@param options? H3UI.ScopeOptions
---@return H3UI.Scope
function H3UI.scope(options) return newScope(options, Environment, nil, nil, false) end

local DefaultScope = newScope(nil, Environment, nil, nil, false)

---@return H3UI.SpecScope
function H3UI.spec() return DefaultScope.spec() end

---@param root H3UI.Spec
---@return H3UI.Document
function H3UI.document(root) return specModule.document(root) end

---@param document H3UI.Document
---@return H3UI.Spec
function H3UI.deserialize(document) return specModule.deserialize(document) end

---@param spec H3UI.Spec|H3UI.Document
---@return openmw.ui.Layout
function H3UI.resolve(spec) return DefaultScope.resolve(spec) end

---@param spec H3UI.Spec|H3UI.Document
---@return table
function H3UI.explain(spec) return DefaultScope.explain(spec) end

H3UI.component = DefaultScope.component
H3UI.recipe = DefaultScope.recipe

for index = 1, #PublicComponents do
  local name = PublicComponents[index]
  local existing = H3UI[name]

  if existing then Error(StrFormat('H3 UI component collides with interface API: %s', name)) end

  H3UI[name] = DefaultScope[name]
end

for name in Next, builtinRecipes do
  local existing = H3UI[name]
  if existing then Error(StrFormat('H3 UI recipe collides with interface API: %s', name)) end

  H3UI[name] = DefaultScope[name]
end

return H3UI
