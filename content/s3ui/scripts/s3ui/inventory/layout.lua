---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v2 = util.vector2

local LAYOUT = {
    windowWidthFraction = 0.52,
    windowHeightFraction = 0.72,
    windowMinSize = v2(640, 500),
    windowMaxSize = v2(960, 820),
    windowMarginFraction = 0.03,
    windowTopFraction = 0.075,
    gridMinColumns = 3,
    gridMaxColumns = 10,
    gridMinRows = 3,
    gridMaxRows = 8,
    gridMinCellSize = v2(76, 82),
    listMinRows = 5,
    listMaxRows = 18,
    listMinRowHeight = 48,
    toolbarHeightFraction = 0.1,
    toolbarMinHeight = 40,
    toolbarMaxHeight = 64,
    categoryRailWidthFraction = 0.13,
    categoryRailMinWidth = 64,
    categoryRailMaxWidth = 110,
    controlButtonSizeFraction = 0.78,
    viewButtonSizeFraction = 0.72,
    controlButtonMinSize = 32,
    controlButtonMaxSize = 56,
    tooltipWidthFraction = 0.18,
    tooltipMinWidth = 220,
    tooltipMaxWidth = 360,
    tooltipFieldRowHeightFraction = 0.026,
    tooltipFieldRowMinHeight = 22,
    tooltipFieldRowMaxHeight = 32,
    tooltipHeaderRowMultiplier = 2.55,
    tooltipPaddingFraction = 0.013,
    tooltipMinPadding = 8,
    tooltipMaxPadding = 18,
    tooltipMarginFraction = 0.02,
    tooltipMinMargin = 12,
    tooltipMaxMargin = 32,
    tooltipFieldIconFraction = 0.82,
    tooltipHeaderIconFraction = 0.68,
    tooltipTextSizeFraction = 0.015,
    tooltipValueTextMinSize = 14,
    tooltipValueTextMaxSize = 18,
}

local function clamp(value, minValue, maxValue)
    if maxValue < minValue then minValue = maxValue end
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function compute()
    local screen = ui.screenSize()
    local shortSide = math.min(screen.x, screen.y)
    local margin = clamp(shortSide * LAYOUT.windowMarginFraction, 12, 48)
    local maxWidth = math.min(LAYOUT.windowMaxSize.x, screen.x - margin * 2)
    local maxHeight = math.min(LAYOUT.windowMaxSize.y, screen.y - margin * 2)
    local windowSize = v2(
        math.floor(clamp(screen.x * LAYOUT.windowWidthFraction, LAYOUT.windowMinSize.x, maxWidth)),
        math.floor(clamp(screen.y * LAYOUT.windowHeightFraction, LAYOUT.windowMinSize.y, maxHeight))
    )
    local position = v2(
        math.floor(margin),
        math.floor(clamp(screen.y * LAYOUT.windowTopFraction, margin, screen.y - windowSize.y - margin))
    )
    local toolbarHeight = math.floor(clamp(windowSize.y * LAYOUT.toolbarHeightFraction, LAYOUT.toolbarMinHeight, LAYOUT.toolbarMaxHeight))
    local controlButtonSize = math.floor(clamp(toolbarHeight * LAYOUT.controlButtonSizeFraction, LAYOUT.controlButtonMinSize, LAYOUT.controlButtonMaxSize))
    local viewButtonSize = math.floor(clamp(toolbarHeight * LAYOUT.viewButtonSizeFraction, LAYOUT.controlButtonMinSize, LAYOUT.controlButtonMaxSize))
    local railWidth = math.floor(clamp(windowSize.x * LAYOUT.categoryRailWidthFraction, LAYOUT.categoryRailMinWidth, LAYOUT.categoryRailMaxWidth))
    local viewSize = v2(math.max(windowSize.x - railWidth, 1), math.max(windowSize.y - toolbarHeight, 1))
    local gridColumns = math.floor(clamp(math.floor(viewSize.x / LAYOUT.gridMinCellSize.x), LAYOUT.gridMinColumns, LAYOUT.gridMaxColumns))
    local gridRows = math.floor(clamp(math.floor(viewSize.y / LAYOUT.gridMinCellSize.y), LAYOUT.gridMinRows, LAYOUT.gridMaxRows))
    local listRows = math.floor(clamp(math.floor(viewSize.y / LAYOUT.listMinRowHeight), LAYOUT.listMinRows, LAYOUT.listMaxRows))
    local tooltipWidth = math.floor(clamp(screen.x * LAYOUT.tooltipWidthFraction, LAYOUT.tooltipMinWidth, math.min(LAYOUT.tooltipMaxWidth, screen.x - margin * 2)))
    local tooltipFieldRowHeight = math.floor(clamp(shortSide * LAYOUT.tooltipFieldRowHeightFraction, LAYOUT.tooltipFieldRowMinHeight, LAYOUT.tooltipFieldRowMaxHeight))
    local tooltipHeaderHeight = math.floor(tooltipFieldRowHeight * LAYOUT.tooltipHeaderRowMultiplier)
    local tooltipPadding = math.floor(clamp(shortSide * LAYOUT.tooltipPaddingFraction, LAYOUT.tooltipMinPadding, LAYOUT.tooltipMaxPadding))
    local tooltipMargin = clamp(shortSide * LAYOUT.tooltipMarginFraction, LAYOUT.tooltipMinMargin, LAYOUT.tooltipMaxMargin)
    local tooltipHeaderIconSize = math.floor(clamp(tooltipHeaderHeight * LAYOUT.tooltipHeaderIconFraction, 32, 56))
    local tooltipFieldIconSize = math.floor(clamp(tooltipFieldRowHeight * LAYOUT.tooltipFieldIconFraction, 18, 30))
    local tooltipValueTextSize = math.floor(clamp(shortSide * LAYOUT.tooltipTextSizeFraction, LAYOUT.tooltipValueTextMinSize, LAYOUT.tooltipValueTextMaxSize))

    return {
        screen = screen,
        margin = margin,
        windowPosition = position,
        windowSize = windowSize,
        viewSize = viewSize,
        toolbarRelativeSize = v2(1, toolbarHeight / windowSize.y),
        categoryRailSize = v2(railWidth, 0),
        controlButtonSize = v2(controlButtonSize, controlButtonSize),
        viewButtonSize = v2(viewButtonSize, viewButtonSize),
        gridColumns = gridColumns,
        gridRows = gridRows,
        listRows = listRows,
        tooltipWidth = tooltipWidth,
        tooltipFieldRowHeight = tooltipFieldRowHeight,
        tooltipHeaderHeight = tooltipHeaderHeight,
        tooltipPadding = tooltipPadding,
        tooltipMargin = v2(tooltipMargin, tooltipMargin),
        tooltipHeaderIconSize = v2(tooltipHeaderIconSize, tooltipHeaderIconSize),
        tooltipFieldIconSize = v2(tooltipFieldIconSize, tooltipFieldIconSize),
        tooltipValueTextSize = tooltipValueTextSize,
        tooltipHeaderTextSize = math.floor(tooltipValueTextSize * 1.3),
        tooltipCountTextSize = math.floor(tooltipValueTextSize * 1.12),
    }
end

return {
    compute = compute,
}
