---@omw-context menu|player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local caption = require 'scripts.s3.components.caption'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'

local clamp = util.clamp
local vector2 = util.vector2

---@class H3.WindowOptions
---@field title? string
---@field position? openmw.util.Vector2
---@field size? openmw.util.Vector2
---@field minSize? openmw.util.Vector2
---@field maxSize? openmw.util.Vector2
---@field movable? boolean
---@field resizable? boolean
---@field closable? boolean
---@field pinnable? boolean
---@field pinned? boolean
---@field onMove? fun(position: openmw.util.Vector2)
---@field onResize? fun(size: openmw.util.Vector2, position: openmw.util.Vector2)
---@field onClose? fun()
---@field onPin? fun(pinned: boolean)
---@field clampToScreen? boolean
---@field referenceSize? openmw.util.Vector2|fun(layout: openmw.ui.Layout): openmw.util.Vector2 Parent or layer size used for clamping.
---@field captionHeight? number
---@field resizeHandle? number
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field content? openmw.ui.Content|openmw.ui.Layout[]
---@field children? openmw.ui.Content|openmw.ui.Layout[]
---@field captionProps? table
---@field template? openmw.ui.Template

local function copyEvents(events)
  local copied = {}
  for key, event in pairs(events or {}) do
    copied[key] = event
  end
  return copied
end

local function addHandler(events, name, handler)
  local previous = events[name]
  events[name] = async:callback(function(event, layout)
    local handlerResult = handler(event, layout)
    if previous then return previous(event, layout) end
    return handlerResult
  end)
end

local function getReferenceSize(layout, referenceSize)
  local size = referenceSize
  if type(size) == 'function' then size = size(layout) end

  if not size and layout.layer and ui.layers then
    local index = ui.layers.indexOf(layout.layer)
    local layer = index and ui.layers[index]
    size = layer and layer.size
  end

  return size or ui.screenSize()
end

---@param options? H3.WindowOptions
---@return openmw.ui.Layout
local function window(options)
  options = options or {}
  local minimumSize = options.minSize or vector2(64, 64)
  local maximumSize = options.maxSize
  assert(minimumSize.x > 0 and minimumSize.y > 0, 'Window minSize must be positive')
  if maximumSize then
    assert(
      maximumSize.x >= minimumSize.x and maximumSize.y >= minimumSize.y,
      'Window maxSize is too small'
    )
  end

  local props = {}
  for key, propValue in pairs(options.props or {}) do
    props[key] = propValue
  end
  props.position = options.position or props.position or vector2(80, 80)
  local initialSize = options.size or props.size or vector2(400, 300)
  props.size = vector2(
    clamp(initialSize.x, minimumSize.x, maximumSize and maximumSize.x or math.huge),
    clamp(initialSize.y, minimumSize.y, maximumSize and maximumSize.y or math.huge)
  )

  local captionHeight = options.captionHeight or 20
  local hasCaption = options.title ~= nil or options.pinnable or options.closable
  local border = constants.thickBorder
  local padding = constants.padding
  local contentInset = border + padding
  local captionTop = border
  local captionBottom = captionTop + captionHeight
  local resizeHandle = options.resizeHandle or 4
  assert(resizeHandle > 0, 'Window resizeHandle must be positive')
  local moving = false
  local resizing = false
  local resizeLeft, resizeRight, resizeTop, resizeBottom = false, false, false, false
  local startMouseX, startMouseY
  local startPosition, startSize
  local interactionReferenceSize

  local function finishInteraction()
    moving = false
    resizing = false
    resizeLeft, resizeRight, resizeTop, resizeBottom = false, false, false, false
    startMouseX, startMouseY = nil, nil
    startPosition, startSize = nil, nil
    interactionReferenceSize = nil
  end

  local events = copyEvents(options.events)

  addHandler(events, 'mousePress', function(event, layout)
    if not event or event.button ~= 1 then return end
    local width = layout.props.size.x
    local height = layout.props.size.y
    local handle = resizeHandle
    local horizontalHandle = math.min(handle, width / 2)
    local verticalHandle = math.min(handle, height / 2)
    resizeLeft = event.offset.x <= horizontalHandle
    resizeRight = not resizeLeft and event.offset.x >= width - horizontalHandle
    resizeTop = event.offset.y <= verticalHandle
    resizeBottom = not resizeTop and event.offset.y >= height - verticalHandle

    if options.resizable ~= false and (resizeLeft or resizeRight or resizeTop or resizeBottom) then
      resizing = true
    elseif
      options.movable ~= false
      and hasCaption
      and event.offset.y >= captionTop
      and event.offset.y <= captionBottom
    then
      moving = true
    else
      return
    end

    startMouseX, startMouseY = event.position.x, event.position.y
    startPosition = layout.props.position
    startSize = layout.props.size
    if options.clampToScreen ~= false then
      interactionReferenceSize = getReferenceSize(layout, options.referenceSize)
    end
    return true
  end)

  addHandler(events, 'mouseMove', function(event, layout)
    if not event or (not moving and not resizing) then return end
    if event.button ~= 1 then
      finishInteraction()
      return
    end
    local deltaX = event.position.x - startMouseX
    local deltaY = event.position.y - startMouseY
    local positionX, positionY = startPosition.x, startPosition.y
    local width, height = startSize.x, startSize.y

    if moving then
      positionX = positionX + deltaX
      positionY = positionY + deltaY
    else
      if resizeLeft then width = startSize.x - deltaX end
      if resizeRight then width = startSize.x + deltaX end
      if resizeTop then height = startSize.y - deltaY end
      if resizeBottom then height = startSize.y + deltaY end
      width = clamp(width, minimumSize.x, maximumSize and maximumSize.x or math.huge)
      height = clamp(height, minimumSize.y, maximumSize and maximumSize.y or math.huge)
      if resizeLeft then positionX = startPosition.x + startSize.x - width end
      if resizeTop then positionY = startPosition.y + startSize.y - height end
    end

    if options.clampToScreen ~= false then
      local screenSize = interactionReferenceSize or getReferenceSize(layout, options.referenceSize)
      if moving then
        positionX = clamp(positionX, 0, math.max(0, screenSize.x - width))
        positionY = clamp(positionY, 0, math.max(0, screenSize.y - height))
      else
        if resizeLeft then
          positionX =
            clamp(positionX, 0, math.max(0, startPosition.x + startSize.x - minimumSize.x))
          width = startPosition.x + startSize.x - positionX
        else
          width = math.min(width, math.max(0, screenSize.x - positionX))
        end
        if resizeTop then
          positionY =
            clamp(positionY, 0, math.max(0, startPosition.y + startSize.y - minimumSize.y))
          height = startPosition.y + startSize.y - positionY
        else
          height = math.min(height, math.max(0, screenSize.y - positionY))
        end
        width = clamp(width, minimumSize.x, maximumSize and maximumSize.x or math.huge)
        height = clamp(height, minimumSize.y, maximumSize and maximumSize.y or math.huge)
      end
    end

    if moving then
      layout.props.position = vector2(positionX, positionY)
      if options.onMove then options.onMove(layout.props.position) end
    else
      layout.props.position = vector2(positionX, positionY)
      layout.props.size = vector2(width, height)
      if options.onResize then options.onResize(layout.props.size, layout.props.position) end
    end

    return true
  end)

  addHandler(events, 'mouseRelease', function(event)
    if not event or event.button ~= 1 or (not moving and not resizing) then return end
    finishInteraction()
    return true
  end)

  addHandler(events, 'focusLoss', function()
    if not moving and not resizing then return end
    finishInteraction()
    return true
  end)

  local content = {}
  content[#content + 1] = {
    type = ui.TYPE.Image,
    props = {
      resource = constants.whiteTexture,
      color = util.color.rgb(0, 0, 0),
      alpha = 0.75,
      relativeSize = vector2(1, 1),
    },
  }
  if hasCaption then
    local captionProps = {
      position = vector2(border, border),
      size = vector2(-2 * border, captionHeight),
      relativeSize = vector2(1, 0),
    }
    for key, value in pairs(options.captionProps or {}) do
      captionProps[key] = value
    end

    content[#content + 1] = caption {
      text = options.title,
      height = captionHeight,
      pinnable = options.pinnable,
      pinned = options.pinned,
      onPin = options.onPin,
      closable = options.closable,
      onClose = options.onClose,
      props = captionProps,
    }
  end
  local body = options.content or options.children or {}
  local bodyLayout = {
    name = 'body',
    type = ui.TYPE.Widget,
    props = {
      position = vector2(contentInset, border + padding + (hasCaption and captionHeight or 0)),
      size = vector2(
        -2 * contentInset,
        -(2 * border + 2 * padding + (hasCaption and captionHeight or 0))
      ),
      relativeSize = vector2(1, 1),
    },
    content = ui.content {
      column {
        props = {
          autoSize = false,
          relativeSize = vector2(1, 1),
        },
        children = body,
      },
    },
  }
  content[#content + 1] = bodyLayout

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template or I.MWUI.templates.bordersThick,
    content = ui.content(content),
  }
end

return window
