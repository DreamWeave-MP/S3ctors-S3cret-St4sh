---@meta
---@module 'scripts.h3.types'

-- Central LuaLS type declarations for the complete H3/H3UI subsystem.
-- This file is metadata-only and is intentionally never required at runtime.

---@alias H3.UserData nil|boolean|number|string|userdata|function|thread|table

---@alias H3ComponentTest.DemoName
---| 'magicMenu'
---| 'inventoryPanel'
---| 'applicationForm'
---| 'appearanceCoverage'
---| 'boundaries'
---| 'controlStates'
---| 'eventComposition'
---| 'relativeSizing'
---| 'windowGeometry'

---@alias H3UI.ComponentConstructor fun(options?: table|string|number, height?: number): openmw.ui.Layout

---@alias H3UI.CacheKeyValue nil|boolean|number|string|userdata|table

---@alias H3UI.ChromeResource H3UI.ChromeFrame|string|H3UI.TextureRegion

---@alias H3UI.ChromeTexture H3UI.ChromeFrame|H3UI.TextureRegion|openmw.ui.TextureResource|string

---@alias H3UI.ChromeSource 'auto'|'theme'|'h3ui'

---@alias H3UI.ComponentDefinitions table<string, H3UI.ComponentDefinition>

---@alias H3UI.DialogBody string|number|openmw.ui.Layout|openmw.ui.Layout[]

---@alias H3UI.DocumentInputValue H3.UserData

---@alias H3UI.DocumentValue nil|boolean|number|string|table|userdata

---@alias H3UI.ItemGridItem H3UI.ItemSlotOptions|openmw.ui.Layout

---@alias H3UI.CompiledRuntimeStyles table<string, H3UI.StateDeltaList>

---@alias H3UI.LuaValue H3.UserData

---@alias H3UI.RuntimeEventHandler fun(event?: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?

---@alias H3UI.SelectionDeltaList table

---@alias H3UI.SelectionValueMap table<table, table<string, H3UI.LuaValue>>

---@alias H3UI.StateDeltaList table

---@alias H3UI.Palette table<string, string>

---@alias H3UI.Recipe fun(ctx: H3UI.RecipeContext, spec: table): openmw.ui.Layout

---@alias H3UI.RecipeConstructor fun(options?: table): openmw.ui.Layout

---@alias H3UI.RecipeItem string|number|table|openmw.ui.Layout

---@alias H3UI.SettingValue nil|boolean|number|string|table

---@alias H3UI.SearchableListItem string|number|H3UI.ListItemOptions|openmw.ui.Layout

---@alias H3UI.SettingsField H3UI.SettingsToggleField|H3UI.SettingsSliderField|H3UI.SettingsNumberInputField|H3UI.SettingsSelectorField|H3UI.SettingsTextInputField

---@alias H3UI.Spec table Plain declarative component or recipe spec.

---@alias H3UI.StyleMap table<string, H3UI.Style>

---@alias H3UI.TokenScalar boolean|number|string|openmw.ui.TextureResource|openmw.util.Color|openmw.util.Vector2

---@alias H3UI.TokenDefinition H3UI.TokenReference|H3UI.TokenScalar|table<string, H3UI.TokenDefinition>

---@alias H3UI.TokenResolvable H3UI.TokenReference|H3UI.TokenValue

---@alias H3UI.TokenValue H3UI.TokenScalar|table

---@class H3.BookFrameOptions
---@field backgroundProps? table
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field title? string
---@field titleProps? table
---@field userData? H3.UserData

---@class H3.BoxOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field padding? number
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ButtonOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field label? string
---@field labelProps? table
---@field name? string
---@field onActivate? fun(event: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?
---@field padding? number Uniform slot inset in pixels. Defaults to roomy button padding.
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.CaptionOptions
---@field closable? boolean
---@field closeLabel? string
---@field closeProps? table
---@field events? table
---@field external? table
---@field height? number
---@field name? string
---@field onClose? fun()
---@field onPin? fun(pinned: boolean)
---@field pinnable? boolean
---@field pinned? boolean
---@field pinProps? table
---@field props? table
---@field text? string
---@field textProps? table
---@field userData? H3.UserData

---@class H3.CollapsibleContent: openmw.ui.Content
---@field body? openmw.ui.Layout

---@class H3.CollapsibleOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field collapsedPrefix? string
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field expanded? boolean
---@field expandedPrefix? string
---@field external? table
---@field headerLabelProps? table
---@field headerProps? table
---@field name? string
---@field onToggle? fun(expanded: boolean)
---@field props? table
---@field title string
---@field userData? H3.UserData

---@class H3.ColumnOptions
---@field [integer] openmw.ui.LayoutOrElement
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field gap? number
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ContainerOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.DividerOptions
---@field color? openmw.util.Color Defaults to the active H3UI chrome-border color.
---@field events? table
---@field external? table
---@field length? number Fixed length. Omit to stretch across the parent on the divider axis.
---@field name? string
---@field orientation? 'horizontal'|'vertical' Defaults to `horizontal`.
---@field props? table
---@field thickness? number Defaults to `1`.
---@field userData? H3.UserData

---@class H3.GridOptions
---@field columnGap? number
---@field columns? integer
---@field events? table
---@field external? table
---@field items? openmw.ui.LayoutOrElement[]
---@field name? string
---@field props? table
---@field rowGap? number
---@field rowProps? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.HeadBlockOptions
---@field events? table
---@field external? table
---@field height? number
---@field name? string
---@field props? table
---@field userData? H3.UserData

---@class H3.IconButtonOptions
---@field events? table
---@field external? table
---@field gap? number
---@field iconProps? table
---@field label? string
---@field labelProps? table
---@field name? string
---@field onActivate? fun(event: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?
---@field props? table
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field selected? boolean Highlight the button using the active theme color.
---@field selectionProps? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ImageOptions
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ItemSlotOptions
---@field count? string|number
---@field countProps? table
---@field events? table
---@field external? table
---@field iconProps? table
---@field name? string
---@field onActivate? fun(event: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?
---@field props? table
---@field resource? openmw.ui.TextureResource|openmw.ui.TextureResourceOptions
---@field selected? boolean Highlight the slot using the active theme color.
---@field selectionProps? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ListItemOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field label? string
---@field labelProps? table
---@field name? string
---@field onActivate? fun(event: openmw.ui.MouseEvent, layout: openmw.ui.Layout): boolean?
---@field props? table
---@field secondary? string|number Right-aligned secondary value for list rows.
---@field secondaryProps? table
---@field selected? boolean Use the active theme color and full-row selection semantics.
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.ListOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field items? openmw.ui.LayoutOrElement[]
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.MeterOptions
---@field emptyProps? table
---@field events? table
---@field external? table
---@field fillProps? table
---@field max? number
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData
---@field value? number

---@class H3.NumberInputOptions
---@field events? table
---@field external? table
---@field integer? boolean
---@field max? number
---@field min? number
---@field name? string
---@field onChange? fun(value: number)
---@field onCommit? fun(value: number)
---@field props? table
---@field step? number
---@field template? openmw.ui.Template
---@field userData? H3.UserData
---@field value? number

---@class H3.PinButtonOptions
---@field events? table
---@field external? table
---@field name? string
---@field onToggle? fun(pinned: boolean)
---@field pinned? boolean
---@field props? table
---@field userData? H3.UserData

---@class H3.RowOptions
---@field [integer] openmw.ui.LayoutOrElement
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field gap? number
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.SearchInputOptions
---@field bordered? boolean
---@field clearable? boolean
---@field clearLabel? string
---@field events? table
---@field external? table
---@field gap? number
---@field inputEvents? table
---@field inputExternal? table
---@field inputProps? table
---@field name? string
---@field onChange? fun(value: string, layout: openmw.ui.Layout): boolean?
---@field onCommit? fun(value: string, layout: openmw.ui.Layout): boolean? Runs when editing focus is released.
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData
---@field value? string

---@class H3.SelectorItem
---@field label string
---@field value? H3.UserData

---@class H3.SelectorOptions
---@field buttonProps? table
---@field emptyLabel? string
---@field events? table
---@field external? table
---@field iconProps? table
---@field items? (string|H3.SelectorItem)[]
---@field labelProps? table
---@field labelTemplate? openmw.ui.Template
---@field name? string
---@field onSelect? fun(index: number, item: string|H3.SelectorItem)
---@field props? table
---@field selected? number
---@field userData? H3.UserData

---@class H3.SliderOptions
---@field emptyProps? table
---@field events? table
---@field external? table
---@field fillProps? table
---@field max? number
---@field min? number
---@field name? string
---@field onChange? fun(value: number)
---@field props? table
---@field step? number
---@field template? openmw.ui.Template
---@field trackWidth? number Width used to map pointer offsets when the track is relatively sized.
---@field userData? H3.UserData
---@field value? number

---@class H3.SpacerOptions
---@field events? table Optional event callbacks table.
---@field external? table Optional external properties table. When present, takes precedence over `grow`/`stretch`.
---@field grow? number Convenience: if `external` is nil, sets `external.grow`. Ignored when `external` is provided.
---@field height? number Convenience height used when `props.size` is absent; defaults to `width`.
---@field name? string Optional layout name for lookup from Content.
---@field props? table Optional widget properties (e.g. `size = vector2(8, 8)`).
---@field stretch? number Convenience: if `external` is nil, sets `external.stretch`. Ignored when `external` is provided.
---@field template? openmw.ui.Template Optional widget template.
---@field userData? H3.UserData Arbitrary user data attached to the returned layout.
---@field width? number Convenience width used when `props.size` is absent; defaults to `0` when only `height` is supplied.

---@class H3.TabItem
---@field label string
---@field value? H3.UserData

---@class H3.TabsOptions
---@field buttonProps? table
---@field events? table
---@field external? table
---@field items? (string|H3.TabItem)[]
---@field labelProps? table
---@field name? string
---@field onSelect? fun(index: number, item: string|H3.TabItem)
---@field props? table
---@field selected? number
---@field selectedLabelProps? table
---@field selectedPrefix? string
---@field selectedProps? table
---@field selectedSuffix? string
---@field userData? H3.UserData

---@class H3.TextInputOptions
---@field events? table
---@field external? table
---@field name? string
---@field onChange? fun(value: string, layout: openmw.ui.Layout): boolean?
---@field onCommit? fun(value: string, layout: openmw.ui.Layout): boolean? Runs when editing focus is released.
---@field props? table
---@field template? openmw.ui.Template
---@field text? string
---@field userData? H3.UserData

---@class H3.TextOptions
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field text? string|number
---@field userData? H3.UserData

---@class H3.ToggleOptions
---@field events? table
---@field external? table
---@field label? string
---@field labelProps? table
---@field name? string
---@field offLabel? string
---@field onChange? fun(value: boolean, layout: openmw.ui.Layout)
---@field onLabel? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData
---@field value? boolean

---@class H3.TooltipOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field text? string
---@field textProps? table
---@field userData? H3.UserData

---@class H3.WidgetOptions
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field template? openmw.ui.Template
---@field userData? H3.UserData

---@class H3.WindowOptions
---@field backgroundProps? table
---@field captionHeight? number
---@field captionProps? table
---@field captionTextProps? table
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field clampToScreen? boolean
---@field closable? boolean
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field innerBorder? boolean Adds the vanilla-style inner border below the caption; enabled by default.
---@field layer? string UI layer used when the component owns/creates a window element.
---@field maxSize? openmw.util.Vector2
---@field minSize? openmw.util.Vector2
---@field movable? boolean
---@field name? string
---@field onClose? fun()
---@field onMove? fun(position: openmw.util.Vector2)
---@field onPin? fun(pinned: boolean)
---@field onResize? fun(size: openmw.util.Vector2, position: openmw.util.Vector2)
---@field padding? number Empty space between the frame and the body on all four sides. Defaults to `8`.
---@field pinnable? boolean
---@field pinned? boolean
---@field position? openmw.util.Vector2
---@field props? table
---@field referenceSize? openmw.util.Vector2|fun(layout: openmw.ui.Layout): openmw.util.Vector2 Parent or layer size used for clamping.
---@field resizable? boolean
---@field resizeHandle? number
---@field size? openmw.util.Vector2
---@field template? openmw.ui.Template
---@field title? string
---@field userData? H3.UserData

---@class H3ComponentTest.ApplicationFormState
---@field defaultFilter string
---@field enabled boolean
---@field initialized? boolean
---@field intensity number
---@field pageSize number
---@field searchQuery string
---@field selectedMode integer
---@field selectedPage integer
---@field showExperimental boolean
---@field unsafeMode boolean

---@class H3ComponentTest.InventoryGridItem
---@field count integer
---@field iconProps table
---@field name string
---@field props table
---@field resource openmw.ui.TextureResourceOptions
---@field selected boolean

---@class H3ComponentTest.InventoryItem
---@field category string
---@field color openmw.util.Color
---@field condition? number
---@field count integer
---@field maxCondition? number
---@field name string
---@field value number
---@field weight number

---@class H3ComponentTest.InventoryState
---@field category string
---@field counts table<string, integer>
---@field equipped table<string, boolean?>
---@field query string
---@field selected? string

---@class H3ComponentTest.MagicActivation
---@field callback openmw.async.Callback
---@field targets table<openmw.ui.Layout, H3ComponentTest.MagicEntry>

---@class H3ComponentTest.MagicEntry
---@field name string
---@field secondary? string

---@class H3ComponentTest.MagicState
---@field deleted table<string, boolean>
---@field query string
---@field selected? string

---@class H3ComponentTest.Options
---@field layer? string Root UI layer. Defaults to `Windows` for in-game console use.
---@field position? openmw.util.Vector2 Optional diagnostic-shell position.
---@field replace? boolean Destroy an existing owned root before creating a new one.
---@field shell? 'window'|'box' Use a plain box shell for diagnostic fixtures.
---@field size? openmw.util.Vector2 Optional diagnostic-shell size.

---@class H3UI: H3UI.ConstructorSurface
---@field DOCUMENT_VERSION integer Portable document format version.
---@field UNSET table Explicit style-removal sentinel.
---@field deserialize fun(document: H3UI.Document): H3UI.Spec
---@field document fun(root: H3UI.Spec): H3UI.Document
---@field explain fun(spec: H3UI.Spec|H3UI.Document): table
---@field nineSlice fun(options: H3UI.NineSliceOptions): openmw.ui.Layout
---@field registerTheme fun(spec: H3UI.ThemeRegistration)
---@field resolve fun(spec: H3UI.Spec|H3UI.Document): openmw.ui.Layout
---@field scope fun(options?: H3UI.ScopeOptions): H3UI.Scope
---@field slots fun(component: string): string[]
---@field spec fun(): H3UI.SpecScope Returns the same constructor vocabulary backed by portable specs instead of OpenMW layouts.

---@class H3UI.ActivationBinding
---@field callback? function|openmw.async.Callback
---@field index integer
---@field item H3UI.RecipeItem

---@class H3UI.ActivationState
---@field callback openmw.async.Callback
---@field targets table<openmw.ui.Layout, H3UI.ActivationBinding>

---@class H3UI.AppearanceState
---@field active? H3UI.Theme
---@field customSection openmw.storage.MutableStorageSection
---@field initialized boolean
---@field lastPresetId? string
---@field pendingTheme? H3UI.PendingTheme
---@field registry H3UI.Registry
---@field section openmw.storage.MutableStorageSection
---@field themes table<string, H3UI.ThemeEntry>
---@field themeUpdateScheduled boolean

---@class H3UI.BookFrameOptions: H3.BookFrameOptions, H3UI.ComponentOptions

---@class H3UI.BoxOptions: H3.BoxOptions, H3UI.ComponentOptions

---@class H3UI.BuiltinTheme
---@field id string
---@field spec H3UI.ThemeSpec
---@field theme H3UI.Theme

---@class H3UI.ButtonOptions: H3.ButtonOptions, H3UI.ComponentOptions

---@class H3UI.ChromeAssetFrameSet
---@field button H3UI.ChromeFrame
---@field caption H3UI.ChromeFrame
---@field pinDown H3UI.ChromeFrame
---@field pinUp H3UI.ChromeFrame
---@field thick H3UI.ChromeFrame
---@field thin H3UI.ChromeFrame

---@class H3UI.ChromeFrame
---@field bottom? string
---@field bottomLeft? string
---@field bottomRight? string
---@field center? boolean|string Atlas center flag or legacy center texture path.
---@field left? string
---@field offset? openmw.util.Vector2 Atlas region offset.
---@field parts? table<string, H3UI.TextureRegion>
---@field path? string Atlas texture path.
---@field right? string
---@field size? openmw.util.Vector2 Atlas region size.
---@field sourceBorder? table Atlas source margins, defaulting to thickness.
---@field thickness number
---@field tintable? boolean
---@field top? string
---@field topLeft? string
---@field topRight? string

---@class H3UI.ChromeFrameOptions
---@field alpha? number
---@field backgroundProps? table
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field contentProps? table
---@field events? table
---@field external? table
---@field inset? number
---@field name? string
---@field props? table
---@field skin H3UI.ChromeFrame
---@field tint? openmw.util.Color
---@field type? openmw.ui.WidgetType
---@field userData? H3.UserData

---@class H3UI.ChromeSpec
---@field caption? H3UI.ChromeFrame
---@field frame? table<string, H3UI.ChromeFrame>
---@field pin? table<string, H3UI.ChromeFrame>
---@field preferredSource? 'theme'|'h3ui'
---@field scroll? table<string, string|H3UI.TextureRegion>

---@class H3UI.CollapsibleOptions: H3.CollapsibleOptions, H3UI.ComponentOptions

---@class H3UI.ColorLikeUserdata
---@field __type H3UI.RuntimeTypeDescriptor
---@field asHex fun(self: H3UI.ColorLikeUserdata): string

---@class H3UI.ColorRendererArgument
---@field key string

---@class H3UI.ColumnOptions: H3.ColumnOptions, H3UI.ComponentOptions
---@field gap? number|H3UI.TokenReference

---@class H3UI.CompiledThemeRule: H3UI.ThemeRule
---@field order integer
---@field slot string
---@field specificity integer
---@field tier integer

---@class H3UI.ComponentAdapter: H3UI.ComponentDefinition

---@class H3UI.ComponentDefinition
---@field _styledOptions? table<string, boolean>
---@field _targetMarkers? table<string, boolean>
---@field builder fun(options: table): openmw.ui.Layout
---@field invalidateOn? string|string[]
---@field isPublic? boolean
---@field runtimeState? boolean
---@field selectable? boolean
---@field slots table<string, H3UI.ComponentSlot>

---@class H3UI.ComponentOptions
---@field class? string
---@field classes? string|string[]|table<string, boolean>
---@field role? string
---@field style? H3UI.Style|H3UI.StyleMap
---@field tone? string
---@field variant? string

---@class H3UI.ComponentRecord
---@field classes table<string, boolean>
---@field component string
---@field recipe? string
---@field role? string
---@field selected? boolean
---@field source table
---@field style? H3UI.Style|H3UI.StyleMap
---@field tone? string
---@field variant? string

---@class H3UI.ComponentSlot
---@field external? string
---@field props? string
---@field retained? boolean
---@field template? string

---@class H3UI.ConfirmDialogOptions: H3UI.DialogOptions
---@field actionGap? number
---@field actions? (string|H3UI.DialogAction)[]
---@field cancelLabel? string
---@field confirmLabel? string
---@field confirmTone? string
---@field onCancel? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): boolean?
---@field onConfirm? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): boolean?

---@class H3UI.ConstructorSurface
---@field bookFrame fun(options?: H3UI.BookFrameOptions): openmw.ui.Layout
---@field box fun(options?: H3UI.BoxOptions): openmw.ui.Layout
---@field button fun(options?: H3UI.ButtonOptions): openmw.ui.Layout
---@field collapsible fun(options?: H3UI.CollapsibleOptions): openmw.ui.Layout
---@field column fun(options?: H3UI.ColumnOptions): openmw.ui.Layout
---@field component fun(name: string, spec?: table): openmw.ui.Layout
---@field confirmDialog fun(spec?: H3UI.ConfirmDialogOptions): openmw.ui.Layout
---@field dialog fun(spec?: H3UI.DialogOptions): openmw.ui.Layout
---@field divider fun(options?: H3UI.DividerOptions): openmw.ui.Layout
---@field grid fun(options?: H3UI.GridOptions): openmw.ui.Layout
---@field iconButton fun(options?: H3UI.IconButtonOptions): openmw.ui.Layout
---@field image fun(options?: H3UI.ImageOptions): openmw.ui.Layout
---@field itemGrid fun(spec?: H3UI.ItemGridOptions): openmw.ui.Layout
---@field itemSlot fun(options?: H3UI.ItemSlotOptions): openmw.ui.Layout
---@field list fun(options?: H3UI.ListOptions): openmw.ui.Layout
---@field listItem fun(options?: H3UI.ListItemOptions): openmw.ui.Layout
---@field meter fun(options?: H3UI.MeterOptions): openmw.ui.Layout
---@field numberInput fun(options?: H3UI.NumberInputOptions): openmw.ui.Layout
---@field recipe fun(name: string, spec?: table): openmw.ui.Layout
---@field row fun(options?: H3UI.RowOptions): openmw.ui.Layout
---@field searchableList fun(spec?: H3UI.SearchableListOptions): openmw.ui.Layout
---@field searchInput fun(options?: H3UI.SearchInputOptions): openmw.ui.Layout
---@field section fun(spec?: H3UI.SectionOptions): openmw.ui.Layout
---@field selector fun(options?: H3UI.SelectorOptions): openmw.ui.Layout
---@field settings fun(spec?: H3UI.SettingsOptions): openmw.ui.Layout
---@field slider fun(options?: H3UI.SliderOptions): openmw.ui.Layout
---@field spacer fun(options?: H3UI.SpacerOptions|number, height?: number): openmw.ui.Layout
---@field tabbedWindow fun(spec?: H3UI.TabbedWindowOptions): openmw.ui.Layout
---@field tabs fun(options?: H3UI.TabsOptions): openmw.ui.Layout
---@field text fun(options?: H3UI.TextOptions|string|number): openmw.ui.Layout
---@field textInput fun(options?: H3UI.TextInputOptions): openmw.ui.Layout
---@field toggle fun(options?: H3UI.ToggleOptions): openmw.ui.Layout
---@field token fun(path: string): H3UI.TokenReference
---@field tooltip fun(options?: H3UI.TooltipOptions): openmw.ui.Layout
---@field window fun(options?: H3UI.WindowOptions): openmw.ui.Layout

---@class H3UI.DialogAction
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field component? string
---@field events? table
---@field external? table
---@field label? string
---@field labelProps? table
---@field name? string
---@field onActivate? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): boolean?
---@field props? table
---@field role? string
---@field style? table
---@field template? openmw.ui.Template
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.DialogOptions
---@field body? H3UI.DialogBody
---@field children? openmw.ui.Layout|openmw.ui.Layout[]
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field events? table
---@field external? table
---@field name? string
---@field props? table
---@field style? table
---@field template? openmw.ui.Template
---@field title? string
---@field titleProps? table
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.DividerOptions: H3.DividerOptions, H3UI.ComponentOptions

---@class H3UI.Document
---@field h3ui integer Document format version.
---@field root H3UI.Spec Portable component or recipe spec.

---@class H3UI.Environment
---@field publicComponents string[]
---@field recipes table<string, H3UI.Recipe>
---@field registry H3UI.Registry
---@field resolver H3UI.Resolver
---@field resolveTheme fun(): H3UI.Theme

---@class H3UI.ExplainResult
---@field document H3UI.Document
---@field layout openmw.ui.Layout
---@field nodes H3UI.TraceEntry[]
---@field theme string

---@class H3UI.GridOptions: H3.GridOptions, H3UI.ComponentOptions

---@class H3UI.IconButtonOptions: H3.IconButtonOptions, H3UI.ComponentOptions

---@class H3UI.ImageOptions: H3.ImageOptions, H3UI.ComponentOptions

---@class H3UI.ItemGridOptions
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field columnGap? number
---@field columns? integer
---@field events? table
---@field external? table
---@field items? H3UI.ItemGridItem[]
---@field name? string
---@field onActivate? fun(item: H3UI.ItemGridItem, index: integer, layout: openmw.ui.Layout): boolean?
---@field onLayout? fun(item: H3UI.ItemGridItem, index: integer, layout: openmw.ui.Layout): nil Construction hook
---receiving each produced layout. Fixtures use it to register identity maps for retained
---selection without a second structure walk.
---@field props? table
---@field rowGap? number
---@field rowProps? table
---@field style? table
---@field template? openmw.ui.Template
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.ItemSlotOptions: H3.ItemSlotOptions, H3UI.ComponentOptions

---@class H3UI.ListItemOptions: H3.ListItemOptions, H3UI.ComponentOptions

---@class H3UI.ListOptions: H3.ListOptions, H3UI.ComponentOptions

---@class H3UI.MeterOptions: H3.MeterOptions, H3UI.ComponentOptions

---@class H3UI.NineSliceOptions
---@field alpha? number
---@field backgroundProps? table
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field contentProps? table
---@field events? table
---@field external? table
---@field inset? number Fixed inset for content inside the nine-slice frame.
---@field name? string
---@field props? table
---@field source H3UI.ChromeFrame
---@field tint? openmw.util.Color
---@field userData? H3.UserData

---@class H3UI.NumberInputOptions: H3.NumberInputOptions, H3UI.ComponentOptions

---@class H3UI.PendingTheme
---@field expectedTheme string
---@field id string

---@class H3UI.RecipeContext: H3UI.ConstructorSurface
---@field _isChildScope boolean Whether this context belongs to a disposable child scope.
---@field child fun(options?: H3UI.ScopeOptions): H3UI.RecipeContext Create a child recipe context with a separate invalidation target.
---@field invalidate? fun(): nil
---@field patch? fun(layout: openmw.ui.Layout, styles: table<string, H3UI.Style>)
---@field recipe string
---@field setChildren fun(layout: openmw.ui.Layout, children: openmw.ui.LayoutOrElement[])
---@field setSelected? fun(layout: openmw.ui.Layout, selected: boolean)
---@field theme H3UI.Theme

---@class H3UI.Registry
---@field build fun(name: string, args: table, themeStyles: table, inlineStyles: table, stateStyles: table?, invalidate: fun()?, selectionStyles: table?, selected: boolean?): openmw.ui.Layout
---@field get fun(name: string): H3UI.ComponentAdapter
---@field has fun(name: string): boolean
---@field patch fun(layout: openmw.ui.Layout, styles: table)
---@field publicComponents fun(): string[]
---@field setSelected fun(layout: openmw.ui.Layout, selected: boolean): boolean
---@field slots fun(name: string): string[]
---@field supportsRuntimeState fun(name: string): boolean
---@field supportsSelection fun(name: string): boolean
---@field validateSlot fun(name: string, slot: string): boolean

---@class H3UI.ResolveContext
---@field invalidate? fun(): nil
---@field recipe? string
---@field theme H3UI.Theme

---@class H3UI.Resolver
---@field build fun(scope: H3UI.Scope, input: H3UI.Spec|H3UI.Document, trace?: H3UI.TraceEntry[]): openmw.ui.Layout
---@field component fun(scope: H3UI.Scope, name: string, input?: table, trace?: H3UI.TraceEntry[]): openmw.ui.Layout
---@field explain fun(scope: H3UI.Scope, input: H3UI.Spec|H3UI.Document): H3UI.ExplainResult
---@field recipe fun(scope: H3UI.Scope, name: string, input?: table, trace?: H3UI.TraceEntry[]): openmw.ui.Layout

---@class H3UI.RowOptions: H3.RowOptions, H3UI.ComponentOptions
---@field gap? number|H3UI.TokenReference

---@class H3UI.RuntimeState
---@field ["protected"]? H3UI.StyleProtection
---@field active H3UI.SelectionDeltaList
---@field adapter H3UI.ComponentAdapter
---@field baseState? string
---@field compiled H3UI.CompiledRuntimeStyles
---@field currentState? string
---@field focused? boolean
---@field focusGain? H3UI.RuntimeEventHandler
---@field focusLoss? H3UI.RuntimeEventHandler
---@field invalidate? fun(): nil
---@field mousePress? H3UI.RuntimeEventHandler
---@field mouseRelease? H3UI.RuntimeEventHandler
---@field pressed? boolean
---@field targets table<H3UI.StyleTargetMarker, table>

---@class H3UI.RuntimeStyleSet
---@field baseState? string
---@field hover? H3UI.StyleMap
---@field pressed? H3UI.StyleMap

---@class H3UI.RuntimeTypeDescriptor
---@field name string

---@class H3UI.Scope: H3UI.ConstructorSurface
---@field _isChildScope boolean Whether this scope is a disposable child of another scope.
---@field child fun(options?: H3UI.ScopeOptions): H3UI.Scope Create a child scope sharing theme, recipes, and tokens with separate invalidation.
---@field destroy fun() Destroy Elements created and owned by this scope and its children.
---@field explain fun(spec: H3UI.Spec|H3UI.Document): table
---@field invalidate? fun(): nil
---@field patch fun(layout: openmw.ui.Layout, styles: table<string, H3UI.Style>) Patch retained semantic slot targets and invalidate this scope.
---@field recipes table<string, H3UI.Recipe>
---@field resolve fun(spec: H3UI.Spec|H3UI.Document): openmw.ui.Layout
---@field resolveTheme fun(): H3UI.Theme
---@field setChildren fun(layout: openmw.ui.Layout, children: openmw.ui.LayoutOrElement[]) Replace a mounted layout's content with fresh children and invalidate the owning scope.
---@field setSelected fun(layout: openmw.ui.Layout, selected: boolean) Change retained selection state and invalidate this scope.
---@field spec fun(): H3UI.SpecScope Returns the same constructor vocabulary backed by portable specs instead of OpenMW layouts.

---@class H3UI.ScopeOptions
---@field _ownsElement? boolean Internal ownership flag used by child scopes.
---@field element? fun(): openmw.ui.Element? Returns the mounted Element targeted by this scope's invalidation. Caller-owned unless explicitly internal to a child update domain.
---@field invalidate? fun(): nil Called when H3UI-owned interaction or recipe state needs a mounted Element update.
---@field recipes? table<string, H3UI.Recipe>

---@class H3UI.ScreenPositionArgument
---@field l10n? string
---@field name? string
---@field title? string

---@class H3UI.ScreenPositionPopup
---@field alive boolean
---@field element? openmw.ui.Element
---@field generation integer

---@class H3UI.SearchableListOptions
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field clearable? boolean
---@field clearLabel? string
---@field events? table
---@field external? table
---@field gap? number
---@field inputProps? table
---@field items? H3UI.SearchableListItem[]
---@field listProps? table
---@field listStyle? table
---@field name? string
---@field onActivate? fun(item: H3UI.SearchableListItem, index: integer, layout: openmw.ui.Layout): boolean?
---@field onQueryChange? fun(value: string, layout: openmw.ui.Layout): nil
---@field props? table
---@field query? string
---@field searchProps? table
---@field searchStyle? table
---@field style? table
---@field template? openmw.ui.Template
---@field text? fun(item: H3UI.SearchableListItem, index: integer): string Text used for construction-time matching.
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.SearchInputOptions: H3.SearchInputOptions, H3UI.ComponentOptions

---@class H3UI.SectionOptions
---@field bodyExternal? table
---@field bodyProps? table
---@field children? openmw.ui.Layout|openmw.ui.Layout[]
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field dividerProps? table
---@field events? table
---@field external? table
---@field gap? number
---@field headerGap? number
---@field name? string
---@field props? table
---@field secondary? string|number
---@field secondaryProps? table
---@field style? table
---@field template? openmw.ui.Template
---@field title? string
---@field titleProps? table
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.SelectionState
---@field deltas table<string, H3UI.SelectionDeltaList>
---@field runtime? H3UI.RuntimeState
---@field runtimeCompiled? table<string, H3UI.CompiledRuntimeStyles>
---@field runtimeCounts? table<string, integer>
---@field selected boolean

---@class H3UI.SelectionStyles
---@field base H3UI.StyleMap
---@field baseRuntime? H3UI.RuntimeStyleSet
---@field selected H3UI.StyleMap
---@field selectedRuntime? H3UI.RuntimeStyleSet

---@class H3UI.SelectorOptions: H3.SelectorOptions, H3UI.ComponentOptions

---@class H3UI.SerializableUserdata
---@field __type H3UI.RuntimeTypeDescriptor
---@field a? number
---@field b? number
---@field g? number
---@field r? number
---@field w? number
---@field x? number
---@field y? number
---@field z? number

---@class H3UI.SettingsFieldBase
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field gap? number
---@field label? string
---@field labelClass? string
---@field labelClasses? string[]|table<string, boolean>
---@field labelProps? table
---@field labelStyle? table
---@field role? string
---@field rowClass? string
---@field rowClasses? string[]|table<string, boolean>
---@field rowExternal? table
---@field rowName? string
---@field rowProps? table
---@field rowRole? string
---@field rowStyle? table
---@field style? table
---@field tone? string
---@field variant? string

---@class H3UI.SettingsNumberInputField: H3UI.SettingsFieldBase
---@field integer? boolean
---@field kind 'numberInput'
---@field max? number
---@field min? number
---@field onChange? fun(value: number, layout: openmw.ui.Layout): boolean?
---@field onCommit? fun(value: number, layout: openmw.ui.Layout): boolean?
---@field step? number
---@field value? number

---@class H3UI.SettingsOptions
---@field children? openmw.ui.Layout[]
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field events? table
---@field external? table
---@field fieldGap? number
---@field fields? H3UI.SettingsField[]
---@field gap? number
---@field name? string
---@field props? table
---@field style? table
---@field template? openmw.ui.Template
---@field title? string
---@field titleStyle? table
---@field tone? string
---@field userData? H3.UserData
---@field variant? string

---@class H3UI.SettingsSelectorField: H3UI.SettingsFieldBase
---@field buttonProps? table
---@field emptyLabel? string
---@field iconProps? table
---@field items? (string|H3.SelectorItem)[]
---@field kind 'selector'
---@field labelProps? table
---@field labelTemplate? openmw.ui.Template
---@field onSelect? fun(index: integer, item: string|H3.SelectorItem): nil
---@field selected? integer

---@class H3UI.SettingsSliderField: H3UI.SettingsFieldBase
---@field emptyProps? table
---@field fillProps? table
---@field kind 'slider'
---@field max? number
---@field min? number
---@field onChange? fun(value: number, layout: openmw.ui.Layout): boolean?
---@field step? number
---@field value? number

---@class H3UI.SettingsTextInputField: H3UI.SettingsFieldBase
---@field kind 'textInput'
---@field onChange? fun(value: string, layout: openmw.ui.Layout): boolean?
---@field text? string

---@class H3UI.SettingsToggleField: H3UI.SettingsFieldBase
---@field kind 'toggle'
---@field offLabel? string
---@field onChange? fun(value: boolean, layout: openmw.ui.Layout): boolean?
---@field onLabel? string
---@field value? boolean

---@class H3UI.SliderOptions: H3.SliderOptions, H3UI.ComponentOptions

---@class H3UI.SpacerOptions: H3.SpacerOptions, H3UI.ComponentOptions

---@class H3UI.SpecScope
---@field bookFrame fun(options?: H3UI.BookFrameOptions): H3UI.Spec
---@field box fun(options?: H3UI.BoxOptions): H3UI.Spec
---@field button fun(options?: H3UI.ButtonOptions): H3UI.Spec
---@field collapsible fun(options?: H3UI.CollapsibleOptions): H3UI.Spec
---@field column fun(options?: H3UI.ColumnOptions): H3UI.Spec
---@field component fun(name: string, spec?: table): H3UI.Spec
---@field confirmDialog fun(spec?: H3UI.ConfirmDialogOptions): H3UI.Spec
---@field dialog fun(spec?: H3UI.DialogOptions): H3UI.Spec
---@field divider fun(options?: H3UI.DividerOptions): H3UI.Spec
---@field grid fun(options?: H3UI.GridOptions): H3UI.Spec
---@field iconButton fun(options?: H3UI.IconButtonOptions): H3UI.Spec
---@field image fun(options?: H3UI.ImageOptions): H3UI.Spec
---@field itemGrid fun(spec?: H3UI.ItemGridOptions): H3UI.Spec
---@field itemSlot fun(options?: H3UI.ItemSlotOptions): H3UI.Spec
---@field list fun(options?: H3UI.ListOptions): H3UI.Spec
---@field listItem fun(options?: H3UI.ListItemOptions): H3UI.Spec
---@field meter fun(options?: H3UI.MeterOptions): H3UI.Spec
---@field numberInput fun(options?: H3UI.NumberInputOptions): H3UI.Spec
---@field recipe fun(name: string, spec?: table): H3UI.Spec
---@field row fun(options?: H3UI.RowOptions): H3UI.Spec
---@field searchableList fun(spec?: H3UI.SearchableListOptions): H3UI.Spec
---@field searchInput fun(options?: H3UI.SearchInputOptions): H3UI.Spec
---@field section fun(spec?: H3UI.SectionOptions): H3UI.Spec
---@field selector fun(options?: H3UI.SelectorOptions): H3UI.Spec
---@field settings fun(spec?: H3UI.SettingsOptions): H3UI.Spec
---@field slider fun(options?: H3UI.SliderOptions): H3UI.Spec
---@field spacer fun(options?: H3UI.SpacerOptions|number, height?: number): H3UI.Spec
---@field tabbedWindow fun(spec?: H3UI.TabbedWindowOptions): H3UI.Spec
---@field tabs fun(options?: H3UI.TabsOptions): H3UI.Spec
---@field text fun(options?: H3UI.TextOptions|string|number): H3UI.Spec
---@field textInput fun(options?: H3UI.TextInputOptions): H3UI.Spec
---@field toggle fun(options?: H3UI.ToggleOptions): H3UI.Spec
---@field token fun(path: string): H3UI.TokenReference
---@field tooltip fun(options?: H3UI.TooltipOptions): H3UI.Spec
---@field window fun(options?: H3UI.WindowOptions): H3UI.Spec

---@class H3UI.StringSelectorItem
---@field label string
---@field value string

---@class H3UI.Style
---@field external? table
---@field props? table
---@field template? openmw.ui.Template

---@class H3UI.StylePlan
---@field dynamicStyles? H3UI.RuntimeStyleSet
---@field themeStyles H3UI.StyleMap

---@class H3UI.StyleProtection
---@field [string] table<string, true|table<string, boolean>>

---@class H3UI.StyleTargetMarker
---@field kind 'external'|'props'
---@field option string
---@field slot string

---@class H3UI.SurfaceOptions
---@field alpha? number
---@field backgroundProps? table
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field events? table
---@field external? table
---@field name? string
---@field padding? number Empty space between the frame and the content on all four sides.
---@field props? table Fixed `size` or `relativeSize` makes a fixed surface; omit both for auto sizing.
---@field selected? H3UI.SurfaceSelectedOptions State chrome layer sharing the wrapper
---geometry and rendered after the normal border. Its visibility is the retained
---`selectedChrome` semantic target.
---@field skin table Chrome frame skin. Must define a positive `thickness`.
---@field tint? openmw.util.Color
---@field userData? H3.UserData

---@class H3UI.SurfaceSelectedOptions
---@field alpha? number Defaults to the surface alpha.
---@field backgroundProps? table
---@field props? table Retained control props for the selected chrome layer. Surface copies
---the table, defaults `visible` to false, `relativeSize` to full size, and
---`ignorePointerEvents` to true, then retains the copy as the layer props.
---@field skin? table Alternate chrome skin for the selected layer. Defaults to the surface skin.
---@field tint? openmw.util.Color

---@class H3UI.TabbedWindowOptions: H3UI.WindowOptions
---@field bodyExternal? table
---@field bodyProps? table
---@field bodyStyle? table
---@field gap? number
---@field items? (string|H3UI.TabbedWindowTab)[]
---@field onSelect? fun(index: integer, item: string|H3UI.TabbedWindowTab): nil
---@field selected? integer
---@field tabProps? table
---@field tabs? (string|H3UI.TabbedWindowTab)[]
---@field tabsStyle? table

---@class H3UI.TabbedWindowTab
---@field children? openmw.ui.Layout|openmw.ui.Layout[]
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field label string

---@class H3UI.TabsOptions: H3.TabsOptions, H3UI.ComponentOptions

---@class H3UI.TextInputOptions: H3.TextInputOptions, H3UI.ComponentOptions

---@class H3UI.TextOptions: H3.TextOptions, H3UI.ComponentOptions

---@class H3UI.TextureRegion
---@field offset openmw.util.Vector2
---@field path string
---@field size openmw.util.Vector2

---@class H3UI.Theme
---@field _index H3UI.ThemeRuleIndex
---@field _rawChrome H3UI.ChromeSpec
---@field _rawRules H3UI.ThemeRule[]
---@field _rawTokens table<string, H3UI.TokenDefinition>
---@field _rules H3UI.CompiledThemeRule[]
---@field _tokens table<string, H3UI.TokenValue>
---@field chrome fun(): H3UI.ChromeSpec
---@field findToken fun(path: string): H3UI.TokenValue?, boolean
---@field hasChrome fun(): boolean
---@field id integer
---@field name string
---@field parent? H3UI.Theme
---@field resolve fun(value: H3UI.TokenResolvable): H3UI.TokenValue
---@field token fun(path: string): H3UI.TokenValue

---@class H3UI.ThemeEntry
---@field author? string
---@field description? string
---@field hasChrome boolean
---@field id string
---@field name string
---@field theme H3UI.Theme

---@class H3UI.ThemeEntrySummary
---@field author? string
---@field description? string
---@field id string
---@field name string

---@class H3UI.ThemeRegistration: H3UI.ThemeSpec
---@field author? string
---@field description? string
---@field id string Stable namespaced identifier.
---@field name string Human-readable name shown in H3UI settings.

---@class H3UI.ThemeRule
---@field selector? H3UI.ThemeSelector
---@field source? string
---@field style H3UI.Style

---@class H3UI.ThemeRuleIndex
---@field component table<string, H3UI.CompiledThemeRule[]>
---@field generic H3UI.CompiledThemeRule[]
---@field state table<string, H3UI.ThemeRuleIndex>

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

---@class H3UI.ThemeSpec
---@field author? string
---@field chrome? H3UI.ChromeSpec
---@field description? string
---@field extends? string
---@field name? string
---@field rules? H3UI.ThemeRule[]
---@field tokens? table<string, H3UI.TokenDefinition>

---@class H3UI.ToggleOptions: H3.ToggleOptions, H3UI.ComponentOptions

---@class H3UI.TokenReference
---@field path string

---@class H3UI.TooltipOptions: H3.TooltipOptions, H3UI.ComponentOptions

---@class H3UI.TraceEntry
---@field classes string[]
---@field component string
---@field inlineStyle H3UI.DocumentValue
---@field matched H3UI.TraceRule[]
---@field recipe? string
---@field role? string
---@field selected? boolean
---@field themeStyle H3UI.DocumentValue
---@field tone? string
---@field variant? string

---@class H3UI.TraceRule
---@field order integer
---@field selector H3UI.ThemeSelector
---@field slot string
---@field source? string
---@field specificity integer
---@field tier integer

---@class H3UI.UpdateRequest
---@field pending boolean
---@field resolveElement fun(): openmw.ui.Element?

---@class H3UI.WindowOptions: H3.WindowOptions, H3UI.ComponentOptions

---@class openmw.interfaces
---@field H3ComponentTest? openmw.interfaces.H3ComponentTest
---@field H3UI? openmw.interfaces.H3UI

---@class openmw.interfaces.H3ComponentTest
---@field appearanceCoverage fun(invalidate?: fun()): openmw.ui.Layout
---@field applicationForm fun(invalidate?: fun(), rebuild?: fun(), state?: table): openmw.ui.Layout
---@field boundaries fun(): openmw.ui.Layout
---@field controlStates fun(): openmw.ui.Layout
---@field create fun(options?: H3ComponentTest.Options): openmw.ui.Element
---@field createDemo fun(name: H3ComponentTest.DemoName, options?: H3ComponentTest.Options): openmw.ui.Element
---@field destroy fun(): boolean
---@field eventComposition fun(): openmw.ui.Layout
---@field inventoryPanel fun(invalidate?: fun(), rebuild?: fun(), state?: table): openmw.ui.Layout
---@field isOpen fun(): boolean
---@field magicMenu fun(invalidate?: fun(), rebuild?: fun(), state?: table): openmw.ui.Layout
---@field makeLayout fun(options?: H3ComponentTest.Options): openmw.ui.Layout
---@field refresh fun()
---@field relativeSizing fun(): openmw.ui.Layout
---@field toggle fun(options?: H3ComponentTest.Options): boolean
---@field windowGeometry fun(): openmw.ui.Layout

---@class openmw.interfaces.H3UI: H3UI
