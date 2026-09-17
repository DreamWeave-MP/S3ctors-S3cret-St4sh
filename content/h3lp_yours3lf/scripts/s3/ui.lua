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
local publicComponents = registry.publicComponents()
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
local resolver = newResolver(registry, publicComponents)

local environment = {
  resolveTheme = appearance.activeTheme,
  recipes = builtinRecipes,
  resolver = resolver,
  publicComponents = publicComponents,
}

---@class H3UI.Style
---@field props? table
---@field external? table
---@field template? openmw.ui.Template

---@class H3UI.ThemeSelector
---@field class? string
---@field component? string
---@field recipe? string
---@field role? string
---@field selected? boolean
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

---@class H3UI.ExplainSpec
---@field recipe? string
---@field component? string
---@field invalidate? fun() Called when H3UI-owned interaction or recipe state needs a mounted Element update.

---@class H3UI.Scope
---@field invalidate? fun()
---@field bookFrame fun(options?: table): openmw.ui.Layout
---@field box fun(options?: table): openmw.ui.Layout
---@field button fun(options?: H3.ButtonOptions): openmw.ui.Layout
---@field collapsible fun(options?: H3.CollapsibleOptions): openmw.ui.Layout
---@field column fun(options?: table): openmw.ui.Layout
---@field divider fun(options?: H3.DividerOptions): openmw.ui.Layout
---@field grid fun(options?: table): openmw.ui.Layout
---@field iconButton fun(options?: H3.IconButtonOptions): openmw.ui.Layout
---@field image fun(options?: table): openmw.ui.Layout
---@field itemSlot fun(options?: H3.ItemSlotOptions): openmw.ui.Layout
---@field list fun(options?: table): openmw.ui.Layout
---@field listItem fun(options?: H3.ListItemOptions): openmw.ui.Layout
---@field meter fun(options?: table): openmw.ui.Layout
---@field numberInput fun(options?: H3.NumberInputOptions): openmw.ui.Layout
---@field row fun(options?: table): openmw.ui.Layout
---@field searchInput fun(options?: H3.SearchInputOptions): openmw.ui.Layout
---@field selector fun(options?: H3.SelectorOptions): openmw.ui.Layout
---@field slider fun(options?: H3.SliderOptions): openmw.ui.Layout
---@field spacer fun(options?: H3.SpacerOptions|number, height?: number): openmw.ui.Layout
---@field tabs fun(options?: H3.TabsOptions): openmw.ui.Layout
---@field text fun(options?: table|string|number): openmw.ui.Layout
---@field textInput fun(options?: H3.TextInputOptions): openmw.ui.Layout
---@field toggle fun(options?: H3.ToggleOptions): openmw.ui.Layout
---@field tooltip fun(options?: table): openmw.ui.Layout
---@field window fun(options?: H3.WindowOptions): openmw.ui.Layout
---@field confirmDialog fun(spec?: H3UI.ConfirmDialogOptions): openmw.ui.Layout
---@field dialog fun(spec?: H3UI.DialogOptions): openmw.ui.Layout
---@field itemGrid fun(spec?: H3UI.ItemGridOptions): openmw.ui.Layout
---@field searchableList fun(spec?: H3UI.SearchableListOptions): openmw.ui.Layout
---@field settings fun(spec?: H3UI.SettingsOptions): openmw.ui.Layout
---@field tabbedWindow fun(spec?: H3UI.TabbedWindowOptions): openmw.ui.Layout
---@field section fun(spec?: H3UI.SectionOptions): openmw.ui.Layout
---@field component fun(name: string, spec?: table): openmw.ui.Layout Advanced dynamic component construction.
---@field recipe fun(name: string, spec?: table): openmw.ui.Layout Advanced dynamic recipe construction.
---@field explain fun(spec: H3UI.ExplainSpec): table
---@field token fun(path: string): H3UI.TokenReference

---@class H3UI: H3UI.Scope
---@field UNSET table Explicit style-removal sentinel.
---@field registerTheme fun(spec: H3UI.ThemeRegistration)
---@field explain fun(spec: H3UI.ExplainSpec): table
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

---@param spec H3UI.ExplainSpec
---@return table
function H3UI.explain(spec) return defaultScope.explain(spec) end

H3UI.component = defaultScope.component
H3UI.recipe = defaultScope.recipe
for index = 1, #publicComponents do
  local name = publicComponents[index]
  H3UI[name] = defaultScope[name]
end
for name in next, builtinRecipes do
  H3UI[name] = defaultScope[name]
end

return H3UI
