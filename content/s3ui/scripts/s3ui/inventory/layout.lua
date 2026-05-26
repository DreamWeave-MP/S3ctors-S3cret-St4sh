---@omw-context player

local ui = require("openmw.ui")
local util = require("openmw.util")

local v2 = util.vector2

---@alias S3UI.InventoryDetailMode 'compact'|'side'

---@class S3UI.InventoryMetrics
---@field screen openmw.util.Vector2
---@field margin number
---@field windowAnchor openmw.util.Vector2
---@field windowPosition openmw.util.Vector2
---@field windowRelativePosition openmw.util.Vector2
---@field windowSize openmw.util.Vector2
---@field viewSize openmw.util.Vector2
---@field toolbarRelativeSize openmw.util.Vector2
---@field detailMode S3UI.InventoryDetailMode
---@field compactDetailRelativeSize openmw.util.Vector2
---@field compactDetailHeaderRelativeSize openmw.util.Vector2
---@field compactDetailFieldsRelativeSize openmw.util.Vector2
---@field compactDetailIconSize openmw.util.Vector2
---@field compactDetailHeaderTextSize integer
---@field compactDetailFieldTextSize integer
---@field compactDetailFieldIconSize openmw.util.Vector2
---@field categoryRailSize openmw.util.Vector2
---@field controlButtonSize openmw.util.Vector2
---@field viewButtonSize openmw.util.Vector2
---@field gridColumns integer
---@field gridRows integer
---@field listRows integer
---@field listIconSize openmw.util.Vector2
---@field tooltipWidth integer
---@field tooltipFieldRowHeight integer
---@field tooltipHeaderHeight integer
---@field tooltipPadding integer
---@field tooltipMargin openmw.util.Vector2
---@field tooltipHeaderIconSize openmw.util.Vector2
---@field tooltipFieldIconSize openmw.util.Vector2
---@field tooltipValueTextSize integer
---@field tooltipHeaderTextSize integer

local LAYOUT = {
	windowWidthFraction = 0.52,
	windowHeightFraction = 0.80,
	windowMinSize = v2(560, 400),
	windowMaxSize = v2(960, 820),
	windowAnchor = v2(0, 0.5),
	windowRelativePosition = v2(0.02, 0.5),
	windowMarginFraction = 0.03,
	gridMinColumns = 3,
	gridMaxColumns = 10,
	gridMinRows = 3,
	gridMaxRows = 8,
	gridMinCellSize = v2(92, 76),
	listMinRows = 5,
	listMaxRows = 18,
	listMinRowHeight = 48,
	listIconSizeFraction = 0.72,
	listIconMinSize = 28,
	listIconMaxSize = 44,
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
	compactDetailMaxScreenWidth = 936,
	compactDetailHeightFraction = 0.24,
	compactDetailMinHeight = 112,
	compactDetailMaxHeight = 148,
	compactDetailHeaderWidthFraction = 0.34,
	compactDetailIconFraction = 0.66,
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

---@param value number
---@param minValue number
---@param maxValue number
---@return number
local function clamp(value, minValue, maxValue)
	if maxValue < minValue then
		minValue = maxValue
	end
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

---@return S3UI.InventoryMetrics
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
		math.floor(screen.x * LAYOUT.windowRelativePosition.x - windowSize.x * LAYOUT.windowAnchor.x),
		math.floor(screen.y * LAYOUT.windowRelativePosition.y - windowSize.y * LAYOUT.windowAnchor.y)
	)
	local toolbarHeight =
		math.floor(clamp(windowSize.y * LAYOUT.toolbarHeightFraction, LAYOUT.toolbarMinHeight, LAYOUT.toolbarMaxHeight))
	local detailMode = screen.x <= LAYOUT.compactDetailMaxScreenWidth and "compact" or "side"
	local compactDetailHeight = detailMode == "compact"
			and math.floor(
				clamp(
					shortSide * LAYOUT.compactDetailHeightFraction,
					LAYOUT.compactDetailMinHeight,
					LAYOUT.compactDetailMaxHeight
				)
			)
		or 0
	local controlButtonSize = math.floor(
		clamp(
			toolbarHeight * LAYOUT.controlButtonSizeFraction,
			LAYOUT.controlButtonMinSize,
			LAYOUT.controlButtonMaxSize
		)
	)
	local viewButtonSize = math.floor(
		clamp(toolbarHeight * LAYOUT.viewButtonSizeFraction, LAYOUT.controlButtonMinSize, LAYOUT.controlButtonMaxSize)
	)
	local railWidth = math.floor(
		clamp(windowSize.x * LAYOUT.categoryRailWidthFraction, LAYOUT.categoryRailMinWidth, LAYOUT.categoryRailMaxWidth)
	)
	local viewSize =
		v2(math.max(windowSize.x - railWidth, 1), math.max(windowSize.y - toolbarHeight - compactDetailHeight, 1))
	local gridColumns = math.floor(
		clamp(math.floor(viewSize.x / LAYOUT.gridMinCellSize.x), LAYOUT.gridMinColumns, LAYOUT.gridMaxColumns)
	)
	local gridRows =
		math.floor(clamp(math.floor(viewSize.y / LAYOUT.gridMinCellSize.y), LAYOUT.gridMinRows, LAYOUT.gridMaxRows))
	local listRows =
		math.floor(clamp(math.floor(viewSize.y / LAYOUT.listMinRowHeight), LAYOUT.listMinRows, LAYOUT.listMaxRows))
	local listRowHeight = viewSize.y / listRows
	local listIconSize =
		math.floor(clamp(listRowHeight * LAYOUT.listIconSizeFraction, LAYOUT.listIconMinSize, LAYOUT.listIconMaxSize))
	local tooltipWidth = math.floor(
		clamp(
			screen.x * LAYOUT.tooltipWidthFraction,
			LAYOUT.tooltipMinWidth,
			math.min(LAYOUT.tooltipMaxWidth, screen.x - margin * 2)
		)
	)
	local tooltipFieldRowHeight = math.floor(
		clamp(
			shortSide * LAYOUT.tooltipFieldRowHeightFraction,
			LAYOUT.tooltipFieldRowMinHeight,
			LAYOUT.tooltipFieldRowMaxHeight
		)
	)
	local tooltipHeaderHeight = math.floor(tooltipFieldRowHeight * LAYOUT.tooltipHeaderRowMultiplier)
	local tooltipPadding =
		math.floor(clamp(shortSide * LAYOUT.tooltipPaddingFraction, LAYOUT.tooltipMinPadding, LAYOUT.tooltipMaxPadding))
	local tooltipMargin =
		clamp(shortSide * LAYOUT.tooltipMarginFraction, LAYOUT.tooltipMinMargin, LAYOUT.tooltipMaxMargin)
	local tooltipHeaderIconSize = math.floor(clamp(tooltipHeaderHeight * LAYOUT.tooltipHeaderIconFraction, 32, 56))
	local tooltipFieldIconSize = math.floor(clamp(tooltipFieldRowHeight * LAYOUT.tooltipFieldIconFraction, 18, 30))
	local tooltipValueTextSize = math.floor(
		clamp(
			shortSide * LAYOUT.tooltipTextSizeFraction,
			LAYOUT.tooltipValueTextMinSize,
			LAYOUT.tooltipValueTextMaxSize
		)
	)

	return {
		screen = screen,
		margin = margin,
		windowAnchor = LAYOUT.windowAnchor,
		windowPosition = position,
		windowRelativePosition = LAYOUT.windowRelativePosition,
		windowSize = windowSize,
		viewSize = viewSize,
		toolbarRelativeSize = v2(1, toolbarHeight / windowSize.y),
		detailMode = detailMode,
		compactDetailRelativeSize = v2(1, compactDetailHeight / windowSize.y),
		compactDetailHeaderRelativeSize = v2(LAYOUT.compactDetailHeaderWidthFraction, 1),
		compactDetailFieldsRelativeSize = v2(1 - LAYOUT.compactDetailHeaderWidthFraction, 1),
		compactDetailIconSize = v2(
			math.floor(compactDetailHeight * LAYOUT.compactDetailIconFraction),
			math.floor(compactDetailHeight * LAYOUT.compactDetailIconFraction)
		),
		compactDetailHeaderTextSize = math.floor(clamp(shortSide * 0.03, 14, 20)),
		compactDetailFieldTextSize = math.floor(clamp(shortSide * 0.025, 12, 16)),
		compactDetailFieldIconSize = v2(
			math.floor(clamp(compactDetailHeight * 0.18, 18, 28)),
			math.floor(clamp(compactDetailHeight * 0.18, 18, 28))
		),
		categoryRailSize = v2(railWidth, 0),
		controlButtonSize = v2(controlButtonSize, controlButtonSize),
		viewButtonSize = v2(viewButtonSize, viewButtonSize),
		gridColumns = gridColumns,
		gridRows = gridRows,
		listRows = listRows,
		listIconSize = v2(listIconSize, listIconSize),
		tooltipWidth = tooltipWidth,
		tooltipFieldRowHeight = tooltipFieldRowHeight,
		tooltipHeaderHeight = tooltipHeaderHeight,
		tooltipPadding = tooltipPadding,
		tooltipMargin = v2(tooltipMargin, tooltipMargin),
		tooltipHeaderIconSize = v2(tooltipHeaderIconSize, tooltipHeaderIconSize),
		tooltipFieldIconSize = v2(tooltipFieldIconSize, tooltipFieldIconSize),
		tooltipValueTextSize = tooltipValueTextSize,
		tooltipHeaderTextSize = math.floor(tooltipValueTextSize * 1.3),
	}
end

return {
	compute = compute,
}
