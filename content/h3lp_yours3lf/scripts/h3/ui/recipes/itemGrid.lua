---@omw-context menu|player

local activation = require 'scripts.h3.ui.recipes.activation'

local Assert, Next, RawGet, StrFormat, ToString, Type = assert, next, rawget, string.format, tostring, type

local Metadata = {
  role = true,
  variant = true,
  tone = true,
  class = true,
  classes = true,
  style = true,
  name = true,
}

---@param ctx H3UI.Scope
---@param item H3UI.ItemGridItem
---@param index integer
---@param activate? H3UI.ActivationState
---@return openmw.ui.Layout
local function itemLayout(ctx, item, index, activate)
  Assert(
    not RawGet(item, 'component') and not RawGet(item, 'recipe'),
    'H3 UI itemGrid items must be descriptors or constructed layouts'
  )

  -- Constructed layouts always carry content; selectable surfaces are template-less
  -- wrappers, so template alone no longer identifies them.
  if item.type or item.content or item.template and not item.resource then
    ---@cast item openmw.ui.Layout
    return activation.bind(activate, item, item, index, true)
  end

  ---@cast item H3UI.ItemSlotOptions

  local spec = {
    role = item.role or 'item',
    variant = item.variant,
    tone = item.tone,
    class = item.class,
    classes = item.classes,
    style = item.style,
    name = item.name or StrFormat('item_%s', ToString(index)),
  }

  for key, value in Next, item do
    if not Metadata[key] then spec[key] = value end
  end

  return activation.bind(activate, ctx.itemSlot(spec), item, index)
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.ItemGridOptions
---@return openmw.ui.Layout
local function itemGrid(ctx, spec)
  local activate, children, items, onLayout =
    activation.new(spec.onActivate), {}, spec.items or {}, spec.onLayout

  for index = 1, #items do
    local item = items[index]
    local child = itemLayout(ctx, item, index, activate)

    children[index] = child

    if onLayout and child and Type(child) == 'table' then onLayout(item, index, child) end
  end

  return ctx.grid {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    items = children,
    columns = spec.columns,
    name = spec.name,
    props = spec.props,
    columnGap = spec.columnGap,
    rowGap = spec.rowGap,
    rowProps = spec.rowProps,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
  }
end

return itemGrid
