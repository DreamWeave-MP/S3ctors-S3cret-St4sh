local I = require('openmw.interfaces')

local MODE = I.UI.MODE
local WINDOW = I.UI.WINDOW

local M = {}

M.mode = nil
M.selectedOption = nil

local function isWindowAllowed(window)
    return I.UI.getWindowsForMode(MODE.Interface)[window]
end

function M.toggleJournal()
    if I.UI.getMode() == MODE.Journal then
        I.UI.removeMode(MODE.Journal)
        M.mode = nil
    elseif isWindowAllowed(WINDOW.Magic) then
        I.UI.removeMode(MODE.Interface)
        I.UI.addMode(MODE.Journal)
        M.mode = 'journal'
    end
end

function M.toggleMap()
    if I.UI.getMode() == MODE.Interface and M.mode == 'map' then
        I.UI.removeMode(MODE.Interface)
        M.mode = nil
    elseif isWindowAllowed(WINDOW.Map) then
        I.UI.setMode(MODE.Interface, { windows = { WINDOW.Map } })
        M.mode = 'map'
    end
end

function M.toggleMagic()
    if I.UI.getMode() == MODE.Interface and M.mode == 'magic' then
        I.UI.removeMode(MODE.Interface)
        M.mode = nil
    elseif isWindowAllowed(WINDOW.Magic) then
        I.UI.setMode(MODE.Interface, { windows = { WINDOW.Magic } })
        M.mode = 'magic'
    end
end

function M.toggleStats()
    if I.UI.getMode() == MODE.Interface and M.mode == 'stats' then
        I.UI.removeMode(MODE.Interface)
        M.mode = nil
    elseif isWindowAllowed(WINDOW.Inventory) or isWindowAllowed(WINDOW.Stats) then
        I.UI.setMode(MODE.Interface, { windows = { WINDOW.Stats } })
        M.mode = 'stats'
    end
end

function M.toggleInventory()
    if I.UI.getMode() == MODE.Interface and M.mode == 'inventory' then
        I.UI.removeMode(MODE.Interface)
        M.mode = nil
    elseif isWindowAllowed(WINDOW.Inventory) then
        I.UI.setMode(MODE.Interface, { windows = { WINDOW.Inventory } })
        M.mode = 'inventory'
    end
end

return M
