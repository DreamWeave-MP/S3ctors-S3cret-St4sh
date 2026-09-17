---@omw-context menu|player

---@class H3UI.TabbedWindowTab
---@field label string
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field children? openmw.ui.Layout|openmw.ui.Layout[]

---@class H3UI.TabbedWindowOptions: H3.WindowOptions
---@field tabs? (string|H3UI.TabbedWindowTab)[]
---@field items? (string|H3UI.TabbedWindowTab)[]
---@field selected? integer
---@field onSelect? fun(index: integer, item: string|H3UI.TabbedWindowTab): any
---@field gap? number
---@field tabsStyle? table
---@field tabProps? table
---@field bodyStyle? table
---@field bodyProps? table
---@field bodyExternal? table

local function pageChildren(page)
  if page == nil then return {} end
  if type(page) == 'table' and page[1] ~= nil then return page end
  return { page }
end

local function tabbedWindow(ctx, spec)
  local tabs = spec.tabs or spec.items or {}
  local selected = math.max(1, math.min(math.floor(spec.selected or 1), math.max(#tabs, 1)))
  local tabItems = {}

  for index = 1, #tabs do
    local tab = tabs[index]
    tabItems[index] = type(tab) == 'table' and (tab.label or tostring(index)) or tostring(tab)
  end

  local selectedTab = tabs[selected]
  local selectedContent = type(selectedTab) == 'table'
      and (selectedTab.content or selectedTab.children)
    or (#tabs == 0 and (spec.content or spec.children))

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
  if selectedContent ~= nil then
    bodyChildren[#bodyChildren + 1] = ctx.column {
      role = 'page',
      name = 'page_' .. tostring(selected),
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
