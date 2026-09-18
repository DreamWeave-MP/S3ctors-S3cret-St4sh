---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local FullSize = UtilVector2(1, 1)

-- H3-owned padding templates. Same structure as the old MWUI padding dependency (a slot
-- inset on every side), but built from H3 values so no component inherits third-party template
-- overrides. The default 2px matches both H3 themes and MWUI; components that need breathing
-- room (buttons) request a roomier size.
local DefaultPadding = 2

local paddingTemplates = {}

local function templateFor(paddingX, paddingY)
  paddingX = paddingX or DefaultPadding
  paddingY = paddingY == nil and paddingX or paddingY
  assert(
    type(paddingX) == 'number' and paddingX >= 0 and type(paddingY) == 'number' and paddingY >= 0,
    'H3 inset padding must be non-negative'
  )

  local row = paddingTemplates[paddingX]
  local found = row and row[paddingY]
  if found then return found end

  local size = UtilVector2(paddingX, paddingY)
  local position = UtilVector2(paddingX, paddingY)
  found = {
    type = ui.TYPE.Container,
    content = ui.content {
      { props = { size = size } },
      {
        external = { slot = true },
        props = { position = position, relativeSize = FullSize },
      },
      {
        props = { position = position, relativePosition = FullSize, size = size },
      },
    },
  }
  if not row then
    row = {}
    paddingTemplates[paddingX] = row
  end
  row[paddingY] = found
  return found
end

---Internal H3 padding boundary. Components use this instead of depending directly on MWUI padding.
---@param child openmw.ui.LayoutOrElement
---@param ignorePointerEvents? boolean
---@param paddingX? number Horizontal slot inset in pixels. Defaults to the 2px H3 border.
---@param paddingY? number Vertical slot inset in pixels. Defaults to `paddingX`.
---@return openmw.ui.Layout
local function buildInset(child, ignorePointerEvents, paddingX, paddingY)
  return {
    template = templateFor(paddingX, paddingY),
    props = { ignorePointerEvents = ignorePointerEvents == true },
    content = ui.content { child },
  }
end

local inset = setmetatable({ template = templateFor(DefaultPadding) }, {
  __call = function(_, child, ignorePointerEvents, paddingX, paddingY)
    return buildInset(child, ignorePointerEvents, paddingX, paddingY)
  end,
})

return inset
