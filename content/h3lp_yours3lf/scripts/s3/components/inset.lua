---@omw-context menu|player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Internal H3 padding boundary. Components use this instead of depending directly on MWUI padding.
---@param child openmw.ui.LayoutOrElement
---@param ignorePointerEvents? boolean
---@return openmw.ui.Layout
local function inset(child, ignorePointerEvents)
  return {
    template = I.MWUI.templates.padding,
    props = { ignorePointerEvents = ignorePointerEvents == true },
    content = ui.content { child },
  }
end

return inset
