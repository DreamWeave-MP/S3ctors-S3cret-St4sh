---@omw-context menu|player

local MathFloor, MathMax, MathMin, Next, StrFormat, ToString, Type =
  math.floor, math.max, math.min, next, string.format, tostring, type

---@param page? openmw.ui.Layout|openmw.ui.Layout[]
---@return openmw.ui.Layout[]
local function pageChildren(page)
  if not page then return {} end

  if Type(page) == 'table' and page[1] then return page end

  return { page }
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.TabbedWindowOptions
---@return openmw.ui.Layout
local function tabbedWindow(ctx, spec)
  local tabs = spec.tabs or spec.items or {}
  local selected = MathMax(1, MathMin(MathFloor(spec.selected or 1), MathMax(#tabs, 1)))
  local tabItems = {}

  for index = 1, #tabs do
    local tab = tabs[index]
    tabItems[index] = Type(tab) == 'table' and (tab.label or ToString(index)) or ToString(tab)
  end

  local selectedContent, selectedTab = nil, tabs[selected]

  if Type(selectedTab) == 'table' then
    selectedContent = selectedTab.content or selectedTab.children
  elseif not Next(tabs) then
    selectedContent = spec.content or spec.children
  end

  local bodyChildren = {
    ctx.tabs {
      role = 'tabs',
      style = spec.tabsStyle,
      items = tabItems,
      selected = selected,
      onSelect = spec.onSelect,
      props = spec.tabProps,
    },
  }

  if selectedContent then
    bodyChildren[#bodyChildren + 1] = ctx.column {
      role = 'page',
      name = StrFormat('page_%s', ToString(selected)),
      children = pageChildren(selectedContent),
    }
  end

  local body = ctx.column {
    role = 'body',
    style = spec.bodyStyle,
    props = spec.bodyProps,
    external = spec.bodyExternal,
    gap = spec.gap or ctx.token 'spacing.sm',
    children = bodyChildren,
  }

  return ctx.window {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    title = spec.title,
    position = spec.position,
    size = spec.size,
    minSize = spec.minSize,
    maxSize = spec.maxSize,
    movable = spec.movable,
    resizable = spec.resizable,
    closable = spec.closable,
    pinnable = spec.pinnable,
    pinned = spec.pinned,
    innerBorder = spec.innerBorder,
    padding = spec.padding,
    onMove = spec.onMove,
    onResize = spec.onResize,
    onClose = spec.onClose,
    onPin = spec.onPin,
    clampToScreen = spec.clampToScreen,
    referenceSize = spec.referenceSize,
    captionHeight = spec.captionHeight,
    resizeHandle = spec.resizeHandle,
    name = spec.name,
    props = spec.props,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    captionProps = spec.captionProps,
    captionTextProps = spec.captionTextProps,
    template = spec.template,
    children = { body },
  }
end

return tabbedWindow
