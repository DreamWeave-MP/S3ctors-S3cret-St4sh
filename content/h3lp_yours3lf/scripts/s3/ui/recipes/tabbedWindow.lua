---@omw-context menu|player

local function tabbedWindow(ctx, spec)
  local tabs = spec.tabs or spec.items or {}
  local selected = math.max(1, math.min(math.floor(spec.selected or 1), math.max(#tabs, 1)))
  local tabItems = {}
  for index = 1, #tabs do
    local tab = tabs[index]
    tabItems[index] = type(tab) == 'table' and (tab.label or tostring(index)) or tostring(tab)
  end

  local selectedTab = tabs[selected]
  local page = type(selectedTab) == 'table' and (selectedTab.content or selectedTab.children) or nil
  if page == nil then page = spec.content or spec.children end

  local bodyChildren = {
    ctx.component('tabs', {
      role = 'tabs',
      style = spec.tabsStyle,
      items = tabItems,
      selected = selected,
      onSelect = spec.onSelect,
      props = spec.tabProps,
    }),
  }
  if page ~= nil then
    if type(page) == 'table' and page[1] ~= nil then
      for i = 1, #page do
        bodyChildren[#bodyChildren + 1] = page[i]
      end
    else
      bodyChildren[#bodyChildren + 1] = page
    end
  end

  local body = ctx.component('column', {
    role = 'body',
    style = spec.bodyStyle,
    props = spec.bodyProps,
    external = spec.bodyExternal,
    gap = spec.gap or 4,
    children = bodyChildren,
  })

  return ctx.component('window', {
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
  })
end
return tabbedWindow
