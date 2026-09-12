---@omw-context menu|player

---Mutates the supplied layout during drag and resize interactions.
---Callbacks receive already-updated properties; callers must call
---`openmw.ui.Element:update()` to apply those properties to a live element.
---Resize converts fixed and relative size contributions to `relativeSize` at
---interaction start. Optional storage is read on install and written only
---when `save` is called.

local async = require 'openmw.async'
local input = require 'openmw.input'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local clamp = util.clamp
local vector2 = util.vector2
local min, max, huge = math.min, math.max, math.huge
local DRAG_STATE_KEY = '__h3DragEvents'
local MODULE_MARKER = {}
local DEFAULT_EDGE_THRESHOLD = 0.025

local KEY_RELATIVE_POSITION = 'relativePosition'
local KEY_RELATIVE_SIZE = 'relativeSize'
local KEY_ANCHOR = 'anchor'

---@alias H3.DragEventsReferenceSize openmw.util.Vector2|fun(layout: openmw.ui.Layout): openmw.util.Vector2
---@alias H3.DragEventsHandler fun(event: openmw.ui.MouseEvent?, layout: openmw.ui.Layout): boolean?

---@class H3.DragEventsOptions
---@field userData? table Caller-provided data merged into `layout.userData`.
---@field onDragStart? fun(layout: openmw.ui.Layout)
---@field onDrag fun(layout: openmw.ui.Layout, newRelativePosition: openmw.util.Vector2)
---@field onDragEnd? fun(layout: openmw.ui.Layout)
---@field onResizeStart? fun(layout: openmw.ui.Layout, newAnchor: openmw.util.Vector2, newRelativePosition: openmw.util.Vector2)
---@field onResize? fun(layout: openmw.ui.Layout, newRelativeSize: openmw.util.Vector2)
---@field onResizeEnd? fun(layout: openmw.ui.Layout)
---@field resolveResize? fun(layout: openmw.ui.Layout, proposedSize: openmw.util.Vector2, absoluteDelta: openmw.util.Vector2, startSize: openmw.util.Vector2, referenceSize: openmw.util.Vector2): openmw.util.Vector2?
---@field edgeThreshold? number
---@field shiftToResize? boolean
---@field section? openmw.storage.MutableStorageSection
---@field clampToScreen? boolean Keep effective bounds inside the reference coordinate space.
---@field referenceSize? H3.DragEventsReferenceSize

---@class H3.DragEventsCallbacks
---@field onDrag fun(layout: openmw.ui.Layout, newRelativePosition: openmw.util.Vector2)
---@field onDragStart? fun(layout: openmw.ui.Layout)
---@field onDragEnd? fun(layout: openmw.ui.Layout)
---@field onResizeStart? fun(layout: openmw.ui.Layout, newAnchor: openmw.util.Vector2, newRelativePosition: openmw.util.Vector2)
---@field onResize? fun(layout: openmw.ui.Layout, newRelativeSize: openmw.util.Vector2)
---@field onResizeEnd? fun(layout: openmw.ui.Layout)
---@field resolveResize? fun(layout: openmw.ui.Layout, proposedSize: openmw.util.Vector2, absoluteDelta: openmw.util.Vector2, startSize: openmw.util.Vector2, referenceSize: openmw.util.Vector2): openmw.util.Vector2?

---@class H3.DragEventsState
---@field marker table
---@field callbacks H3.DragEventsCallbacks
---@field edgeThreshold number
---@field shiftToResize boolean
---@field clampToScreen boolean
---@field canResize boolean
---@field referenceSize H3.DragEventsReferenceSize?
---@field storageSection openmw.storage.MutableStorageSection?
---@field dragging boolean
---@field resizing boolean
---@field interactionReferenceSize openmw.util.Vector2?
---@field inverseReferenceWidth number?
---@field inverseReferenceHeight number?
---@field lastMouseX number?
---@field lastMouseY number?
---@field startMouseX number?
---@field startMouseY number?
---@field startSize openmw.util.Vector2?

---@param layout openmw.ui.Layout
---@param dragState H3.DragEventsState
---@return openmw.util.Vector2
local function getReferenceSize(layout, dragState)
  local size = dragState.referenceSize

  if type(size) == 'function' then size = size(layout) end

  if not size and layout.layer and ui.layers then
    local index = ui.layers.indexOf(layout.layer)
    local layer = index and ui.layers[index]
    size = layer and layer.size
  end

  size = size or ui.screenSize()
  assert(size and size.x > 0 and size.y > 0, 'DragEvents requires a positive reference size')

  return size
end

---@param layout openmw.ui.Layout
---@param dragState H3.DragEventsState
---@return number?
---@return number?
local function getRelativeSize(layout, dragState)
  local properties = layout.props
  local relativeSize = properties.relativeSize
  local relativeWidth = relativeSize and relativeSize.x
  local relativeHeight = relativeSize and relativeSize.y

  if properties.size then
    local referenceSize = dragState.interactionReferenceSize or getReferenceSize(layout, dragState)
    local fixedWidth = properties.size.x / referenceSize.x
    local fixedHeight = properties.size.y / referenceSize.y

    if relativeWidth then
      relativeWidth = relativeWidth + fixedWidth
      relativeHeight = relativeHeight + fixedHeight
    else
      relativeWidth = fixedWidth
      relativeHeight = fixedHeight
    end
  end

  return relativeWidth, relativeHeight
end

---@param offsetPosition openmw.util.Vector2
---@param layout openmw.ui.Layout
---@param dragState H3.DragEventsState
---@return number
---@return number
local function getRelativeClickPosition(offsetPosition, layout, dragState)
  local relativeWidth, relativeHeight = getRelativeSize(layout, dragState)
  assert(relativeWidth and relativeHeight, 'DragEvents: missing relative size')
  local referenceSize = dragState.interactionReferenceSize or getReferenceSize(layout, dragState)

  return offsetPosition.x / (relativeWidth * referenceSize.x),
    offsetPosition.y / (relativeHeight * referenceSize.y)
end

---@param position number
---@param size number
---@param anchor number
---@return number
local function clampPositionAxis(position, size, anchor)
  local minimum = anchor * size
  local maximum = 1 - (1 - anchor) * size

  if minimum > maximum then return (minimum + maximum) * 0.5 end

  return clamp(position, minimum, maximum)
end

---@param position number
---@param anchor number
---@return number
local function getMaximumSize(position, anchor)
  local maximum = huge

  if anchor > 0 then maximum = min(maximum, position / anchor) end

  if anchor < 1 then maximum = min(maximum, (1 - position) / (1 - anchor)) end

  return max(0, maximum)
end

---@param dragState H3.DragEventsState
---@param layout openmw.ui.Layout
---@param mousePosition openmw.util.Vector2
local function beginInteraction(dragState, layout, mousePosition)
  local interactionReferenceSize = getReferenceSize(layout, dragState)

  dragState.interactionReferenceSize = interactionReferenceSize
  dragState.inverseReferenceWidth = 1 / interactionReferenceSize.x
  dragState.inverseReferenceHeight = 1 / interactionReferenceSize.y
  dragState.lastMouseX = mousePosition.x
  dragState.lastMouseY = mousePosition.y
end

---@param layout openmw.ui.Layout
local function endInteraction(layout)
  local userData = layout.userData
  local dragState = assert(userData and userData[DRAG_STATE_KEY], 'DragEvents: missing drag state')
  ---@cast dragState H3.DragEventsState

  local callbacks = dragState.callbacks

  if dragState.resizing then
    dragState.resizing = false

    if callbacks.onResizeEnd then callbacks.onResizeEnd(layout) end
  elseif dragState.dragging then
    dragState.dragging = false

    if callbacks.onDragEnd then callbacks.onDragEnd(layout) end
  end

  dragState.interactionReferenceSize = nil
  dragState.inverseReferenceWidth = nil
  dragState.inverseReferenceHeight = nil
  dragState.lastMouseX = nil
  dragState.lastMouseY = nil
  dragState.startMouseX = nil
  dragState.startMouseY = nil
  dragState.startSize = nil
end

---@param mouseEvent openmw.ui.MouseEvent?
---@param layout openmw.ui.Layout
---@return boolean?
local function onMousePress(mouseEvent, layout)
  if not mouseEvent or mouseEvent.button ~= 1 then return end

  local userData = layout.userData
  local dragState = assert(userData and userData[DRAG_STATE_KEY], 'DragEvents: missing drag state')
  ---@cast dragState H3.DragEventsState

  local callbacks = dragState.callbacks

  beginInteraction(dragState, layout, mouseEvent.position)

  local shouldResize = false
  local clickX, clickY

  if dragState.canResize then
    clickX, clickY = getRelativeClickPosition(mouseEvent.offset, layout, dragState)
    local clickedEdge = clickX < dragState.edgeThreshold
      or clickX > (1 - dragState.edgeThreshold)
      or clickY < dragState.edgeThreshold
      or clickY > (1 - dragState.edgeThreshold)
    local shiftPressed = dragState.shiftToResize and input.isShiftPressed()
    shouldResize = clickedEdge or shiftPressed
  end

  if shouldResize then
    local newAnchor = vector2(clamp(1 - clickX, 0, 1), clamp(1 - clickY, 0, 1))
    local properties = layout.props
    local relativeWidth, relativeHeight = getRelativeSize(layout, dragState)
    assert(relativeWidth and relativeHeight, 'DragEvents: missing relative size')
    local relativeSize = vector2(relativeWidth, relativeHeight)

    properties.relativeSize = relativeSize
    properties.size = nil

    local positionX = properties.relativePosition.x
      + (newAnchor.x - properties.anchor.x) * relativeWidth
    local positionY = properties.relativePosition.y
      + (newAnchor.y - properties.anchor.y) * relativeHeight

    if dragState.clampToScreen then
      positionX = clampPositionAxis(positionX, relativeWidth, newAnchor.x)
      positionY = clampPositionAxis(positionY, relativeHeight, newAnchor.y)
    end

    local newPosition = vector2(positionX, positionY)
    properties.anchor = newAnchor
    properties.relativePosition = newPosition

    dragState.resizing = true
    dragState.startMouseX = mouseEvent.position.x
    dragState.startMouseY = mouseEvent.position.y
    dragState.startSize = relativeSize

    if callbacks.onResizeStart then callbacks.onResizeStart(layout, newAnchor, newPosition) end

    return true
  end

  dragState.dragging = true

  if callbacks.onDragStart then callbacks.onDragStart(layout) end

  return true
end

---@param mouseEvent openmw.ui.MouseEvent?
---@param layout openmw.ui.Layout
---@return boolean?
local function onMouseMove(mouseEvent, layout)
  local userData = layout.userData
  local dragState = assert(userData and userData[DRAG_STATE_KEY], 'DragEvents: missing drag state')
  ---@cast dragState H3.DragEventsState

  if not dragState.dragging and not dragState.resizing then return end

  if not mouseEvent then return end

  local callbacks = dragState.callbacks

  local lastMouseX = dragState.lastMouseX
  local lastMouseY = dragState.lastMouseY
  local inverseReferenceWidth = dragState.inverseReferenceWidth
  local inverseReferenceHeight = dragState.inverseReferenceHeight
  ---@cast lastMouseX number
  ---@cast lastMouseY number
  ---@cast inverseReferenceWidth number
  ---@cast inverseReferenceHeight number
  local mouseX = mouseEvent.position.x
  local mouseY = mouseEvent.position.y
  local relativeDeltaX = (lastMouseX - mouseX) * inverseReferenceWidth
  local relativeDeltaY = (lastMouseY - mouseY) * inverseReferenceHeight
  local interactionReferenceSize = dragState.interactionReferenceSize
  ---@cast interactionReferenceSize openmw.util.Vector2
  local properties = layout.props

  if dragState.resizing then
    local relativeSize =
      assert(properties.relativeSize, 'DragEvents: missing relativeSize during resize')

    local sizeDeltaX = relativeDeltaX
    local sizeDeltaY = relativeDeltaY

    if properties.anchor.x <= 0.5 then sizeDeltaX = -sizeDeltaX end

    if properties.anchor.y <= 0.5 then sizeDeltaY = -sizeDeltaY end

    local newWidth = relativeSize.x + sizeDeltaX
    local newHeight = relativeSize.y + sizeDeltaY

    if callbacks.resolveResize then
      local proposedSize = vector2(newWidth, newHeight)
      local startMouseX = dragState.startMouseX
      local startMouseY = dragState.startMouseY
      local startSize = dragState.startSize
      ---@cast startMouseX number
      ---@cast startMouseY number
      ---@cast startSize openmw.util.Vector2
      local absoluteDelta = vector2(mouseX - startMouseX, mouseY - startMouseY)
      local resolvedSize = callbacks.resolveResize(
        layout,
        proposedSize,
        absoluteDelta,
        startSize,
        interactionReferenceSize
      )

      if resolvedSize then
        newWidth = resolvedSize.x
        newHeight = resolvedSize.y
      end
    end

    if dragState.clampToScreen then
      newWidth =
        clamp(newWidth, 0, getMaximumSize(properties.relativePosition.x, properties.anchor.x))
      newHeight =
        clamp(newHeight, 0, getMaximumSize(properties.relativePosition.y, properties.anchor.y))
    end

    local newSize = vector2(newWidth, newHeight)
    properties.relativeSize = newSize
    properties.size = nil
    callbacks.onResize(layout, newSize)
    dragState.lastMouseX = mouseX
    dragState.lastMouseY = mouseY

    return true
  end

  local relativePosition =
    assert(properties.relativePosition, 'DragEvents: missing relativePosition during drag')
  local positionX = relativePosition.x - relativeDeltaX
  local positionY = relativePosition.y - relativeDeltaY

  if dragState.clampToScreen then
    local relativeWidth, relativeHeight = getRelativeSize(layout, dragState)

    if relativeWidth and relativeHeight then
      positionX = clampPositionAxis(positionX, relativeWidth, properties.anchor.x)
      positionY = clampPositionAxis(positionY, relativeHeight, properties.anchor.y)
    else
      positionX = clamp(positionX, 0, 1)
      positionY = clamp(positionY, 0, 1)
    end
  end

  local newPosition = vector2(positionX, positionY)
  properties.relativePosition = newPosition
  callbacks.onDrag(layout, newPosition)
  dragState.lastMouseX = mouseX
  dragState.lastMouseY = mouseY

  return true
end

---@param mouseEvent openmw.ui.MouseEvent?
---@param layout openmw.ui.Layout
---@return boolean?
local function onMouseRelease(mouseEvent, layout)
  if not mouseEvent or mouseEvent.button ~= 1 then return end

  local userData = layout.userData
  local dragState = assert(userData and userData[DRAG_STATE_KEY], 'DragEvents: missing drag state')
  ---@cast dragState H3.DragEventsState

  if not dragState.dragging and not dragState.resizing then return end

  endInteraction(layout)

  return true
end

---@param _ nil
---@param layout openmw.ui.Layout
---@return boolean?
local function onFocusLoss(_, layout)
  local userData = layout.userData
  local dragState = assert(userData and userData[DRAG_STATE_KEY], 'DragEvents: missing drag state')
  ---@cast dragState H3.DragEventsState

  if not dragState.dragging and not dragState.resizing then return end

  endInteraction(layout)

  return true
end

---@param previousHandler H3.DragEventsHandler?
---@param dragHandler H3.DragEventsHandler
---@return H3.DragEventsHandler
local function composeEventHandler(previousHandler, dragHandler)
  return async:callback(function(event, layout)
    local previousResult

    if previousHandler then previousResult = previousHandler(event, layout) end

    local dragResult = dragHandler(event, layout)

    if previousResult ~= nil then return previousResult end

    return dragResult
  end)
end

---@param layout openmw.ui.Layout
---@param section openmw.storage.MutableStorageSection
local function load(layout, section)
  local properties = layout.props
  local savedPosition = section:get(KEY_RELATIVE_POSITION)

  if savedPosition then properties.relativePosition = savedPosition end

  local savedSize = section:get(KEY_RELATIVE_SIZE)

  if savedSize then
    properties.relativeSize = savedSize
    properties.size = nil
  end

  local savedAnchor = section:get(KEY_ANCHOR)

  if savedAnchor then properties.anchor = savedAnchor end
end

---@param layout openmw.ui.Layout
---@param options H3.DragEventsOptions
local function install(layout, options)
  assert(type(layout) == 'table', 'DragEvents.install: layout must be a table')
  assert(type(options) == 'table', 'DragEvents.install: options must be a table')
  assert(type(options.onDrag) == 'function', 'DragEvents.install: onDrag callback is required')

  if options.onResize ~= nil then
    assert(type(options.onResize) == 'function', 'DragEvents.install: onResize must be a function')
  end

  if options.resolveResize ~= nil then
    assert(
      type(options.resolveResize) == 'function',
      'DragEvents.install: resolveResize must be a function'
    )
  end

  local properties = layout.props or {}
  properties.anchor = properties.anchor or vector2(0, 0)
  properties.relativePosition = properties.relativePosition or vector2(0, 0)
  layout.props = properties

  local userData = layout.userData or {}
  assert(type(userData) == 'table', 'DragEvents.install: layout.userData must be a table')

  if options.userData then
    assert(type(options.userData) == 'table', 'DragEvents.install: userData must be a table')
    assert(options.userData[DRAG_STATE_KEY] == nil, 'DragEvents.install: reserved userData key')

    for key, value in pairs(options.userData) do
      userData[key] = value
    end
  end

  local existingState = userData[DRAG_STATE_KEY]

  if existingState ~= nil then
    assert(
      type(existingState) == 'table' and existingState.marker == MODULE_MARKER,
      'DragEvents.install: reserved userData key is already in use'
    )
  end

  local dragState = existingState or { marker = MODULE_MARKER }
  ---@cast dragState H3.DragEventsState
  dragState.callbacks = {
    onDrag = options.onDrag,
    onDragStart = options.onDragStart,
    onDragEnd = options.onDragEnd,
    onResize = options.onResize,
    onResizeStart = options.onResizeStart,
    onResizeEnd = options.onResizeEnd,
    resolveResize = options.resolveResize,
  }
  dragState.edgeThreshold = options.edgeThreshold or DEFAULT_EDGE_THRESHOLD
  dragState.shiftToResize = options.shiftToResize ~= false
  dragState.clampToScreen = options.clampToScreen ~= false
  dragState.canResize = type(options.onResize) == 'function'
  dragState.referenceSize = options.referenceSize
  dragState.storageSection = options.section

  if options.section ~= nil then load(layout, options.section) end

  if dragState.canResize then
    assert(
      getRelativeSize(layout, dragState),
      'DragEvents.install: resizing requires props.size or props.relativeSize'
    )
  end

  dragState.dragging = false
  dragState.resizing = false
  dragState.interactionReferenceSize = nil
  dragState.inverseReferenceWidth = nil
  dragState.inverseReferenceHeight = nil
  dragState.lastMouseX = nil
  dragState.lastMouseY = nil
  dragState.startMouseX = nil
  dragState.startMouseY = nil
  dragState.startSize = nil
  userData[DRAG_STATE_KEY] = dragState
  layout.userData = userData

  if existingState == nil then
    local events = layout.events or {}
    events.mousePress = composeEventHandler(events.mousePress, onMousePress)
    events.mouseMove = composeEventHandler(events.mouseMove, onMouseMove)
    events.mouseRelease = composeEventHandler(events.mouseRelease, onMouseRelease)
    events.focusLoss = composeEventHandler(events.focusLoss, onFocusLoss)
    layout.events = events
  end
end

---@param layout openmw.ui.Layout
---@param section? openmw.storage.MutableStorageSection
local function save(layout, section)
  local userData = layout.userData
  local dragState = userData and userData[DRAG_STATE_KEY]
  section = section or (dragState and dragState.storageSection)

  if not section then
    error(
      'DragEvents.save: no storage section provided and none stashed on layout.userData.__h3DragEvents',
      2
    )
  end

  local properties = layout.props
  section:set(KEY_RELATIVE_POSITION, properties.relativePosition)
  section:set(KEY_RELATIVE_SIZE, properties.relativeSize)
  section:set(KEY_ANCHOR, properties.anchor)
end

return {
  install = install,
  load = load,
  save = save,
}
