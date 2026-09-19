---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local caption = require 'scripts.h3.components.caption'
local chrome = require 'scripts.h3.ui.chrome'
local column = require 'scripts.h3.components.column'
local eventHandlers = require 'scripts.h3.components.eventHandlers'

local Assert, MathHuge, MathMax, MathMin, Next, Type =
  assert, math.huge, math.max, math.min, next, type

local ScreenSize, UiContent, UiLayers, UiLayersIndexOf, UiType, UtilClamp, UtilVector2 =
  ui.screenSize, ui.content, ui.layers, ui.layers.indexOf, ui.TYPE, util.clamp, util.vector2

local EmptyOptions, EmptyContent = {}, {}

local DefaultMinimumSize, DefaultPosition, DefaultSize, FullSize, RelativeWidth =
  UtilVector2(64, 64),
  UtilVector2(80, 80),
  UtilVector2(400, 300),
  UtilVector2(1, 1),
  UtilVector2(1, 0)

---@param layout openmw.ui.Layout
---@param referenceSize? openmw.util.Vector2|fun(layout: openmw.ui.Layout): openmw.util.Vector2
---@return openmw.util.Vector2
local function getReferenceSize(layout, referenceSize)
  local size = referenceSize
  if Type(size) == 'function' then size = size(layout) end

  if not size and layout.layer and UiLayers then
    local index = UiLayersIndexOf(layout.layer)
    local layer = index and UiLayers[index]
    size = layer and layer.size
  end

  return size or ScreenSize()
end

---@param options? H3.WindowOptions
---@return openmw.ui.Layout
local function window(options)
  options = options or EmptyOptions

  local minimumSize = options.minSize or DefaultMinimumSize
  local maximumSize = options.maxSize
  local minimumWidth = minimumSize.x
  local minimumHeight = minimumSize.y
  local maximumWidth = maximumSize and maximumSize.x or MathHuge
  local maximumHeight = maximumSize and maximumSize.y or MathHuge

  Assert(minimumWidth > 0 and minimumHeight > 0, 'Window minSize must be positive')
  Assert(
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
    for key, propValue in Next, options.props do
      props[key] = propValue
    end
  end

  props.position = options.position or props.position or DefaultPosition
  local initialSize = options.size or props.size or DefaultSize
  props.size = UtilVector2(
    UtilClamp(initialSize.x, minimumWidth, maximumWidth),
    UtilClamp(initialSize.y, minimumHeight, maximumHeight)
  )

  local captionHeight = options.captionHeight or 20
  local hasCaption = options.title or options.pinnable or options.closable
  local innerBorder = options.innerBorder ~= false
  local canMove = movable and hasCaption
  local frameSkin = appearance.chrome 'frame.thick'
  local border = frameSkin.thickness
  Assert(Type(border) == 'number' and border > 0, 'Window frame skin requires thickness')
  local padding = appearance.token 'spacing.padding'
  local contentInset = border + padding
  local captionTop = border
  local captionBottom = captionTop + captionHeight
  local resizeHandle = options.resizeHandle or 4
  Assert(resizeHandle > 0, 'Window resizeHandle must be positive')

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

  ---@return nil
  local function finishInteraction()
    moving = false
    resizing = false
  end

  local events = {}
  if options.events then
    for name, callback in Next, options.events do
      events[name] = callback
    end
  end

  if canMove or resizable then
    eventHandlers.add(events, 'mousePress',
      ---@param event openmw.ui.MouseEvent?
      ---@param layout openmw.ui.Layout
      ---@return boolean?
      function(event, layout)
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

    eventHandlers.add(events, 'mouseMove',
      ---@param event openmw.ui.MouseEvent?
      ---@param layout openmw.ui.Layout
      ---@return boolean?
      function(event, layout)
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

    eventHandlers.add(events, 'mouseRelease',
      ---@param event openmw.ui.MouseEvent?
      ---@return boolean?
      function(event)
      if not event or event.button ~= 1 or (not moving and not resizing) then return end

      finishInteraction()
      return true
    end)

    eventHandlers.add(events, 'focusLoss',
      ---@return boolean?
      function()
      if not moving and not resizing then return end

      finishInteraction()
      return true
    end)
  end

  local content = {
    {
      type = UiType.Image,
      props = {
        resource = appearance.token 'texture.white',
        ignorePointerEvents = true,
        color = appearance.token 'color.background',
        alpha = appearance.token 'transparency.menu',
        relativeSize = FullSize,
      },
    },
  }
  local background = content[1]

  if options.backgroundProps then
    for key, value in Next, options.backgroundProps do
      background.props[key] = value
    end
  end

  if hasCaption then
    local captionProps = {
      position = UtilVector2(border, border),
      size = UtilVector2(-2 * border, captionHeight),
      relativeSize = RelativeWidth,
    }

    if options.captionProps then
      for key, value in Next, options.captionProps do
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
      textProps = options.captionTextProps,
      props = captionProps,
    }
  end

  local innerBorderTop = border + (hasCaption and captionHeight or 0)
  local bodyPadding = options.padding or 8
  Assert(Type(bodyPadding) == 'number' and bodyPadding >= 0, 'Window padding must be non-negative')
  local bodyInset = (innerBorder and 2 * border or contentInset) + bodyPadding
  local bodyOffset = innerBorderTop + (innerBorder and border or padding) + bodyPadding

  if innerBorder then
    content[#content + 1] = chrome.frame {
      name = 'innerBorder',
      skin = frameSkin,
      props = {
        position = UtilVector2(border, innerBorderTop),
        size = UtilVector2(-2 * border, -(innerBorderTop + border)),
        relativeSize = FullSize,
      },
      tint = appearance.token 'color.chromeBorder',
      alpha = appearance.token 'transparency.chrome',
    }
  end

  local body = options.content or options.children
  if #options > 0 then
    Assert(not body, 'H3 window accepts array children or children/content, not both')
    body = options
  end
  body = body or EmptyContent
  content[#content + 1] = {
    name = 'body',
    type = UiType.Widget,
    props = {
      position = UtilVector2(bodyInset, bodyOffset),
      size = UtilVector2(-2 * bodyInset, -(bodyInset + bodyOffset)),
      relativeSize = FullSize,
    },
    content = UiContent {
      column {
        props = {
          autoSize = false,
          relativeSize = FullSize,
        },
        children = body,
      },
    },
  }

  if options.template then
    return {
      layer = options.layer,
      type = UiType.Widget,
      name = options.name,
      props = props,
      external = options.external,
      events = events,
      userData = options.userData,
      template = options.template,
      content = UiContent(content),
    }
  end

  local borderColor = appearance.token 'color.chromeBorder'
  local result = chrome.frame {
    skin = frameSkin,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    tint = borderColor,
    alpha = appearance.token 'transparency.chrome',
    content = content,
  }
  result.layer = options.layer
  return result
end

return window
