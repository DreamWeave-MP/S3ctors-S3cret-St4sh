---@meta
---@omw-context player|menu

---Utility functions for OpenMW UI layouts and elements.
---@class openmw_aux.ui
local ui = {}

---Deep-copies a UI layout table, preserving non-plain-table values.
---@param layout openmw.ui.Layout|table
---@return openmw.ui.Layout|table copiedLayout
function ui.deepLayoutCopy(layout) end

---Recursively updates all elements in the passed layout or element.
---@param elementOrLayout openmw.ui.Element|openmw.ui.Layout|table
function ui.deepUpdate(elementOrLayout) end

---Recursively destroys all elements in the passed layout or element.
---@param elementOrLayout openmw.ui.Element|openmw.ui.Layout|table
function ui.deepDestroy(elementOrLayout) end

return ui
