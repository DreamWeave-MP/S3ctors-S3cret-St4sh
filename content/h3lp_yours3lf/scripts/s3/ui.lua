---@omw-context menu|player
---@module 'scripts.s3.ui'

local appearance = require 'scripts.s3.ui.appearance'
local builtinRecipes = require 'scripts.s3.ui.recipes.init'
local chrome = require 'scripts.s3.ui.chrome'
local componentDefinitions = require 'scripts.s3.ui.components'
local constants = require 'scripts.s3.ui.constants'
local newRegistry = require 'scripts.s3.ui.registry'
local newResolver = require 'scripts.s3.ui.resolver'
local newScope = require 'scripts.s3.ui.scope'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

local registry = newRegistry(componentDefinitions)
local morrowindTheme = themeModule.new(require 'scripts.s3.ui.themes.morrowind', registry)
local starwindTheme =
  themeModule.new(require 'scripts.s3.ui.themes.starwind', registry, morrowindTheme)
appearance.initialize(registry, {
  {
    id = 'morrowind',
    spec = require 'scripts.s3.ui.themes.morrowind',
    theme = morrowindTheme,
  },
  {
    id = 'starwind',
    spec = require 'scripts.s3.ui.themes.starwind',
    theme = starwindTheme,
  },
})
local resolver = newResolver(registry, builtinRecipes)

local environment = {
  resolveTheme = appearance.activeTheme,
  recipes = builtinRecipes,
  resolver = resolver,
}

---@class H3UI.Style
---@field props? table
---@field external? table
---@field template? openmw.ui.Template

---@class H3UI.ThemeSelector
---@field class? string
---@field component? string
---@field density? string
---@field recipe? string
---@field role? string
---@field slot? string
---@field state? string
---@field tone? string
---@field variant? string

---@class H3UI.ThemeRule
---@field selector? H3UI.ThemeSelector
---@field style H3UI.Style
---@field source? string

---@class H3UI.ChromeFrame
---@field thickness number
---@field path? string Atlas texture path.
---@field offset? openmw.util.Vector2 Atlas region offset.
---@field size? openmw.util.Vector2 Atlas region size.
---@field sourceBorder? table Atlas source margins, defaulting to thickness.
---@field center? boolean|string Atlas center flag or legacy center texture path.
---@field parts? table<string, H3UI.TextureRegion>
---@field top? string
---@field bottom? string
---@field left? string
---@field right? string
---@field topLeft? string
---@field topRight? string
---@field bottomLeft? string
---@field bottomRight? string
---@field tintable? boolean

---@class H3UI.TextureRegion
---@field path string
---@field offset openmw.util.Vector2
---@field size openmw.util.Vector2

---@class H3UI.ChromeSpec
---@field preferredSource? 'theme'|'h3ui'
---@field frame? table<string, H3UI.ChromeFrame>
---@field caption? H3UI.ChromeFrame
---@field pin? table<string, H3UI.ChromeFrame>
---@field scroll? table<string, string|H3UI.TextureRegion>

---@class H3UI.NineSliceOptions
---@field source H3UI.ChromeFrame
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field tint? openmw.util.Color
---@field alpha? number
---@field backgroundProps? table
---@field contentProps? table
---@field inset? number Fixed inset for content inside the nine-slice frame.
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]

---@class H3UI.ThemeSpec
---@field name? string
---@field extends? string
---@field tokens? table<string, any>
---@field rules? H3UI.ThemeRule[]
---@field chrome? H3UI.ChromeSpec

---@class H3UI.Theme
---@field name string
---@field token fun(path: string): any
---@field resolve fun(value: any): any
---@field chrome fun(): H3UI.ChromeSpec
---@field hasChrome fun(): boolean

---@class H3UI.ThemeRegistration: H3UI.ThemeSpec
---@field id string Stable namespaced identifier.
---@field name string Human-readable name shown in H3UI settings.
---@field description? string
---@field author? string

---@class H3UI.TokenReference
---@field path string

---@class H3UI.BuildSpec
---@field recipe? string
---@field component? string
---@field invalidate? fun() Called after a runtime state change that needs a mounted Element update.

---@class H3UI.Scope
---@field density? string
---@field invalidate? fun()
---@field build fun(spec: H3UI.BuildSpec): openmw.ui.Layout
---@field explain fun(spec: H3UI.BuildSpec): table
---@field token fun(path: string): H3UI.TokenReference

---@class H3UI
---@field UNSET table Explicit style-removal sentinel.
---@field registerTheme fun(spec: H3UI.ThemeRegistration)
---@field build fun(spec: H3UI.BuildSpec): openmw.ui.Layout
---@field explain fun(spec: H3UI.BuildSpec): table
---@field scope fun(options?: H3UI.ScopeOptions): H3UI.Scope
---@field token fun(path: string): H3UI.TokenReference
---@field slots fun(component: string): string[]
---@field nineSlice fun(options: H3UI.NineSliceOptions): openmw.ui.Layout
local H3UI = {
  UNSET = constants.UNSET,
}

---@param spec H3UI.ThemeRegistration
function H3UI.registerTheme(spec) return appearance.registerTheme(spec) end

---@param path string
---@return H3UI.TokenReference
function H3UI.token(path) return token.ref(path) end

---@param component string
---@return string[]
function H3UI.slots(component) return registry.slots(component) end

---@param options H3UI.NineSliceOptions
---@return openmw.ui.Layout
function H3UI.nineSlice(options) return chrome.nineSlice(options) end

---@param options? H3UI.ScopeOptions
---@return H3UI.Scope
function H3UI.scope(options) return newScope(options, environment) end

local defaultScope = H3UI.scope()

---@param spec H3UI.BuildSpec
---@return openmw.ui.Layout
function H3UI.build(spec) return defaultScope.build(spec) end

---@param spec H3UI.BuildSpec
---@return table
function H3UI.explain(spec) return defaultScope.explain(spec) end

return H3UI
