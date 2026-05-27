---@omw-context none

---@alias S3UI.InventoryTab 'inventory'|'equipment'

---@class S3UI.CountModalOptions
---@field min? integer
---@field max? integer
---@field initial? integer
---@field title? string
---@field onOk? fun(count: integer)
---@field onCancel? fun()

---@class S3UI.CountModalLayoutContext
---@field async openmw.async
---@field generation integer
---@field title string
---@field inputText string
---@field maxValue integer
---@field value integer
---@field hoverTextColor fun(name: string): openmw.util.Color|nil
---@field setHoveredControl fun(name: string, hovering: boolean, generation: integer)
---@field setTextEditFocused fun(layout: table|nil, focused: boolean, generation: integer)
---@field isAlive fun(generation: integer): boolean
---@field setInputText fun(text: string)
---@field commitInputText fun()
---@field sliderRatio fun(): number
---@field setValue fun(value: integer)
---@field setValueFromTrack fun(offsetX: number, trackWidth: number)
---@field beginDrag fun(name: string)
---@field isDragging fun(name: string): boolean
---@field endDrag fun()
---@field confirm fun()
---@field cancel fun()

---@class S3UI.InventoryBuilderContext
---@field controlsCtx S3UI.InventoryControlContext
---@field details S3UI.InventoryDetailsController
---@field equipmentCtx S3UI.EquipmentContext
---@field entries S3UI.InventoryDisplayEntry[]
---@field firstIndex integer
---@field metrics S3UI.InventoryMetrics
---@field rootLayer string
---@field state S3UI.InventoryState
---@field viewCtx S3UI.InventoryViewContext
---@field windowRelativePosition? openmw.util.Vector2

---@class S3UI.InventoryControlContext
---@field async openmw.async
---@field clearSelection fun()
---@field metrics fun(): S3UI.InventoryMetrics
---@field queueRebuild fun()
---@field state S3UI.InventoryState

---@class S3UI.InventoryViewContext: S3UI.InventoryControlContext
---@field closeInventoryForRepair fun(onClosed?: fun())
---@field selectSlot fun(slotIndex: integer, itemData: S3UI.InventoryItemData|nil)

---@class S3UI.InventoryNavigationContext
---@field actionCtx fun(): table
---@field activateEquipmentSlot fun(slot: S3UI.EquipmentSlot)
---@field clearSelection fun()
---@field layoutMetrics fun(): S3UI.InventoryMetrics
---@field openEquipmentCategory fun(slot: S3UI.EquipmentSlot)
---@field queueRebuild fun()
---@field selectEquipmentSlot fun(slot: S3UI.EquipmentSlot|nil)
---@field selectVisibleSlot fun(slotIndex: integer, itemData: S3UI.InventoryItemData|nil)
---@field state S3UI.InventoryState

---@class S3UI.InventoryDetailsController
---@field createSideTooltip fun()
---@field destroy fun()
---@field hide fun()
---@field update fun(itemData: S3UI.InventoryItemData|nil)
---@field makeCompactDetailBar fun(): table

---@class S3UI.InventoryDetailsContext
---@field metrics fun(): S3UI.InventoryMetrics
---@field root fun(): table|nil
---@field rootLayer string

---@class S3UI.InventoryDetailField
---@field key string
---@field label string
---@field value string
---@field icon any

---@class S3UI.InventoryDetailModel
---@field name string
---@field icon any
---@field fields S3UI.InventoryDetailField[]

---@class S3UI.EquipmentSlot
---@field key string
---@field label string
---@field slot? any
---@field itemData? S3UI.InventoryItemData
---@field inventoryCategoryKey? string
---@field summary? string

---@class S3UI.EquipmentGroup
---@field key string
---@field title string
---@field layout? table<string, { x: integer, y: integer }>
---@field navOrder? string[]
---@field slots S3UI.EquipmentSlot[]

---@class S3UI.EquipmentContext
---@field async openmw.async
---@field detailElement? table
---@field leftElement? table
---@field groups S3UI.EquipmentGroup[]
---@field metrics fun(): S3UI.InventoryMetrics
---@field queueRebuild fun()
---@field activateEquipmentSlot fun(slot: S3UI.EquipmentSlot)
---@field openEquipmentCategory fun(slot: S3UI.EquipmentSlot)
---@field selectEquipmentSlot fun(slot: S3UI.EquipmentSlot|nil)
---@field state S3UI.InventoryState

---@class S3UI.TravelDestination
---@field cellId string
---@field label? string
---@field position openmw.util.Vector3
---@field rotation? number|openmw.util.Vector3
---@field hours? number

---@class S3UI.TravelRow
---@field index integer
---@field sourceIndex? integer
---@field label string
---@field price integer
---@field enabled boolean
---@field destination? S3UI.TravelDestination
---@field cellId? string
---@field position? openmw.util.Vector3
---@field rotation? number|openmw.util.Vector3
---@field hours? number

---@class S3UI.TravelLayoutContext
---@field async openmw.async
---@field cancel fun()
---@field confirm fun()
---@field activate fun(index: integer)
---@field select fun(index: integer)
---@field setHovered fun(name: string)
---@field clearHovered fun(name: string)
---@field hovered string|nil
---@field playerGold number
---@field rows S3UI.TravelRow[]
---@field scrollOffset integer
---@field selectedIndex integer
---@field serviceName string
---@field target openmw.Object|nil

---@class S3UI.TravelExecutePayload
---@field player openmw.Object
---@field target openmw.Object
---@field cellId string
---@field position openmw.util.Vector3
---@field rotation? number|openmw.util.Vector3
---@field price integer
---@field followers openmw.Object[]
---@field sourceExterior boolean
---@field hours number

---@class S3UI.TravelInterface
---@field getElement fun(): table|nil
---@field getTarget fun(): openmw.Object|nil
---@field getDestinations fun(): S3UI.TravelRow[]
---@field getFollowers fun(): openmw.Object[]
---@field show fun(target: openmw.Object)
---@field hide fun()
---@field rebuild fun()
---@field updateElement fun()
---@field activateSelection fun()
---@field setCellDisplayNames fun(names: table<string, string>)
---@field setHook fun(name: string, fn: function|nil)
---@field setRenderer fun(fn: function|nil)
---@field resetOverrides fun()
---@field defaultRenderer fun(ctx: S3UI.TravelLayoutContext): table
---@field getBarterOffer fun(target: openmw.Object|nil, basePrice: number, buying: boolean): number

return {}
