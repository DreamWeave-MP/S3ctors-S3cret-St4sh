---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local Assert, SetMetatable, Type = assert, setmetatable, type

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2

local FullSize = UtilVector2(1, 1)

-- H3-owned padding templates keep component spacing independent from external template tables.
-- The default 2px is the standard inset; components that need breathing room request more.
local DefaultPadding = 2

local PaddingTemplates = {}

---@param paddingX? number
---@param paddingY? number
---@return openmw.ui.Template
local function templateFor(paddingX, paddingY)
  paddingX = paddingX or DefaultPadding
  paddingY = paddingY or paddingX
  Assert(
    Type(paddingX) == 'number' and paddingX >= 0 and Type(paddingY) == 'number' and paddingY >= 0,
    'H3 inset padding must be non-negative'
  )

  local row = PaddingTemplates[paddingX]
  local found = row and row[paddingY]
  if found then return found end

  local size = UtilVector2(paddingX, paddingY)
  local position = UtilVector2(paddingX, paddingY)
  found = {
    type = UiType.Container,
    content = UiContent {
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
    PaddingTemplates[paddingX] = row
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
    content = UiContent { child },
  }
end

local Inset = SetMetatable({ template = templateFor(DefaultPadding) }, {
  ---@param _ table
  ---@param child openmw.ui.LayoutOrElement
  ---@param ignorePointerEvents? boolean
  ---@param paddingX? number
  ---@param paddingY? number
  ---@return openmw.ui.Layout
  __call = function(_, child, ignorePointerEvents, paddingX, paddingY)
    return buildInset(child, ignorePointerEvents, paddingX, paddingY)
  end,
})

return Inset
