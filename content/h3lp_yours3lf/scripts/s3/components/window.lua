---@omw-context menu|player

local emptyOptions = {}
local emptyContent = {}

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local caption = require 'scripts.s3.components.caption'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'

local UtilClamp = util.clamp
local UtilVector2 = util.vector2
local MathHuge = math.huge
local MathMax = math.max
local MathMin = math.min

local defaultMinimumSize = UtilVector2(64, 64)
local defaultPosition = UtilVector2(80, 80)
local defaultSize = UtilVector2(400, 300)
local fullSize = UtilVector2(1, 1)
local relativeWidth = UtilVector2(1, 0)
local backgroundColor = util.color.rgb(0, 0, 0)

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
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field captionProps? table
---@field template? openmw.ui.Template

local function addHandler(events, name, handler)
  local previous = events[name]

  if not previous then
    events[name] = async:callback(handler)
    return
  end

  events[name] = async:callback(function(event, layout)
    handler(event, layout)
    return previous(event, layout)
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
  options = options or emptyOptions

  local minimumSize = options.minSize or defaultMinimumSize
  local maximumSize = options.maxSize
  local minimumWidth = minimumSize.x
  local minimumHeight = minimumSize.y
  local maximumWidth = maximumSize and maximumSize.x or MathHuge
  local maximumHeight = maximumSize and maximumSize.y or MathHuge

  assert(minimumWidth > 0 and minimumHeight > 0, 'Window minSize must be positive')
  assert(
    maximumWidth >= minimumWidth and maximumHeight >= minimumHeight,
    'Window maxSize is too small'
  )

  local movable = options.movable ~= false
  local resizable = options.resizable ~= false
  local clampToScreen = options.clampToScreen ~= false
  local referenceSize = options.referenceSize
  local onMove = options.onMove
  local onResize = options.onResize

  local props = {}
  if options.props then
    for key, propValue in next, options.props do
      props[key] = propValue
    end
  end

  props.position = options.position or props.position or defaultPosition
  local initialSize = options.size or props.size or defaultSize
  props.size = UtilVector2(
    UtilClamp(initialSize.x, minimumWidth, maximumWidth),
    UtilClamp(initialSize.y, minimumHeight, maximumHeight)
  )

  local captionHeight = options.captionHeight or 20
  local hasCaption = options.title ~= nil or options.pinnable or options.closable
  local canMove = movable and hasCaption
  local border = constants.thickBorder
  local padding = constants.padding
  local contentInset = border + padding
  local captionTop = border
  local captionBottom = captionTop + captionHeight
  local resizeHandle = options.resizeHandle or 4
  assert(resizeHandle > 0, 'Window resizeHandle must be positive')

  local moving = false
  local resizing = false
  local resizeLeft = false
  local resizeRight = false
  local resizeTop = false
  local resizeBottom = false
  local startMouseX
  local startMouseY
  local startPositionX
  local startPositionY
  local startWidth
  local startHeight
  local interactionReferenceWidth
  local interactionReferenceHeight
  local currentPositionX
  local currentPositionY
  local currentWidth
  local currentHeight

  local function finishInteraction()
    moving = false
    resizing = false
  end

  local events = {}
  if options.events then
    for name, callback in next, options.events do
      events[name] = callback
    end
  end

  if canMove or resizable then
    addHandler(events, 'mousePress', function(event, layout)
      if not event or event.button ~= 1 then return end

      local size = layout.props.size
      local width = size.x
      local height = size.y
      local horizontalHandle = MathMin(resizeHandle, width * 0.5)
      local verticalHandle = MathMin(resizeHandle, height * 0.5)
      local offset = event.offset

      resizeLeft = offset.x <= horizontalHandle
      resizeRight = not resizeLeft and offset.x >= width - horizontalHandle
      resizeTop = offset.y <= verticalHandle
      resizeBottom = not resizeTop and offset.y >= height - verticalHandle

      if resizable and (resizeLeft or resizeRight or resizeTop or resizeBottom) then
        resizing = true
      elseif canMove and offset.y >= captionTop and offset.y <= captionBottom then
        moving = true
      else
        return
      end

      local mousePosition = event.position
      local position = layout.props.position
      startMouseX = mousePosition.x
      startMouseY = mousePosition.y
      startPositionX = position.x
      startPositionY = position.y
      startWidth = width
      startHeight = height
      currentPositionX = startPositionX
      currentPositionY = startPositionY
      currentWidth = width
      currentHeight = height

      if clampToScreen then
        local sizeReference = getReferenceSize(layout, referenceSize)
        interactionReferenceWidth = sizeReference.x
        interactionReferenceHeight = sizeReference.y
      end

      return true
    end)

    addHandler(events, 'mouseMove', function(event, layout)
      if not event or (not moving and not resizing) then return end
      if event.button ~= 1 then
        finishInteraction()
        return
      end

      local mousePosition = event.position
      local deltaX = mousePosition.x - startMouseX
      local deltaY = mousePosition.y - startMouseY
      local positionX = startPositionX
      local positionY = startPositionY
      local width = startWidth
      local height = startHeight

      if moving then
        positionX = positionX + deltaX
        positionY = positionY + deltaY
      else
        if resizeLeft then
          width = startWidth - deltaX
        elseif resizeRight then
          width = startWidth + deltaX
        end

        if resizeTop then
          height = startHeight - deltaY
        elseif resizeBottom then
          height = startHeight + deltaY
        end

        width = UtilClamp(width, minimumWidth, maximumWidth)
        height = UtilClamp(height, minimumHeight, maximumHeight)

        if resizeLeft then positionX = startPositionX + startWidth - width end
        if resizeTop then positionY = startPositionY + startHeight - height end
      end

      if clampToScreen then
        local referenceWidth = interactionReferenceWidth
        local referenceHeight = interactionReferenceHeight
        if not referenceWidth then
          local sizeReference = getReferenceSize(layout, referenceSize)
          referenceWidth = sizeReference.x
          referenceHeight = sizeReference.y
        end

        if moving then
          positionX = UtilClamp(positionX, 0, MathMax(0, referenceWidth - width))
          positionY = UtilClamp(positionY, 0, MathMax(0, referenceHeight - height))
        else
          if resizeLeft then
            positionX =
              UtilClamp(positionX, 0, MathMax(0, startPositionX + startWidth - minimumWidth))
            width = startPositionX + startWidth - positionX
          else
            width = MathMin(width, MathMax(0, referenceWidth - positionX))
          end

          if resizeTop then
            positionY =
              UtilClamp(positionY, 0, MathMax(0, startPositionY + startHeight - minimumHeight))
            height = startPositionY + startHeight - positionY
          else
            height = MathMin(height, MathMax(0, referenceHeight - positionY))
          end

          width = UtilClamp(width, minimumWidth, maximumWidth)
          height = UtilClamp(height, minimumHeight, maximumHeight)
        end
      end

      local props = layout.props
      if moving then
        if currentPositionX == positionX and currentPositionY == positionY then return true end

        currentPositionX = positionX
        currentPositionY = positionY
        props.position = UtilVector2(positionX, positionY)

        if onMove then onMove(props.position) end
        return true
      end

      local positionChanged = currentPositionX ~= positionX or currentPositionY ~= positionY
      local sizeChanged = currentWidth ~= width or currentHeight ~= height
      if not positionChanged and not sizeChanged then return true end

      if positionChanged then
        currentPositionX = positionX
        currentPositionY = positionY
        props.position = UtilVector2(positionX, positionY)
      end

      if sizeChanged then
        currentWidth = width
        currentHeight = height
        props.size = UtilVector2(width, height)
      end

      if onResize then onResize(props.size, props.position) end
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
  end

  local content = {
    {
      type = ui.TYPE.Image,
      props = {
        resource = constants.whiteTexture,
        ignorePointerEvents = true,
        color = backgroundColor,
        alpha = 0.75,
        relativeSize = fullSize,
      },
    },
  }

  if hasCaption then
    local captionProps = {
      position = UtilVector2(border, border),
      size = UtilVector2(-2 * border, captionHeight),
      relativeSize = relativeWidth,
    }

    if options.captionProps then
      for key, value in next, options.captionProps do
        captionProps[key] = value
      end
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

  local bodyOffset = border + padding + (hasCaption and captionHeight or 0)
  local body = options.content or options.children
  body = body or emptyContent
  content[#content + 1] = {
    name = 'body',
    type = ui.TYPE.Widget,
    props = {
      position = UtilVector2(contentInset, bodyOffset),
      size = UtilVector2(-2 * contentInset, -(contentInset + bodyOffset)),
      relativeSize = fullSize,
    },
    content = ui.content {
      column {
        props = {
          autoSize = false,
          relativeSize = fullSize,
        },
        children = body,
      },
    },
  }

  return {
    layer = options.layer,
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
