---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'
local controls = require 'scripts.s3ui.inventory.controls'
local equipmentView = require 'scripts.s3ui.inventory.equipment_view'
local icons = require 'scripts.s3ui.inventory.icons'
local views = require 'scripts.s3ui.inventory.views'

local v2 = util.vector2
---@class S3UI.InventoryBuilderModule
local M = {}

local function makeReservedCompactDetail(metrics)
	return {
		name = 's3ui_compact_detail_reserved',
		type = ui.TYPE.Widget,
		props = { relativeSize = metrics.compactDetailRelativeSize },
	}
end

---@param ctx S3UI.InventoryBuilderContext
---@return table layout
function M.make(ctx)
	local metrics = ctx.metrics
	local bodyLayouts = {}
	local mainView
	bodyLayouts[#bodyLayouts + 1] = controls.makeToolbar(ctx.controlsCtx)
	if ctx.state.primaryTab == 'equipment' then
		mainView = equipmentView.make(ctx.equipmentCtx)
	else
		mainView = ctx.state.viewMode == 'list' and views.makeList(ctx.entries, ctx.firstIndex, ctx.viewCtx)
			or views.makeGrid(ctx.entries, ctx.firstIndex, ctx.viewCtx)
	end
	bodyLayouts[#bodyLayouts + 1] = {
		name = 's3ui_main',
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = icons.MAIN_RELATIVE_SIZE, autoSize = false },
		external = { grow = 1 },
		content = ui.content { controls.makeCategoryRail(ctx.controlsCtx), mainView },
	}
	if ctx.state.primaryTab == 'inventory' and metrics.detailMode == 'compact' then
		bodyLayouts[#bodyLayouts + 1] = ctx.details.makeCompactDetailBar()
	elseif ctx.state.primaryTab == 'equipment' and metrics.detailMode == 'compact' then
		bodyLayouts[#bodyLayouts + 1] = makeReservedCompactDetail(metrics)
	end

	local inset = chrome.frameInset(chrome.FRAME_SIZE_PANEL)
	local content = ui.content {
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = chrome.backgroundAlpha(),
				relativeSize = v2(1, 1),
			},
		},
		{
			name = 's3ui_body',
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				position = v2(inset, inset),
				size = v2(-inset * 2, -inset * 2),
				relativeSize = v2(1, 1),
				autoSize = false,
			},
			content = ui.content(bodyLayouts),
		},
	}
	chrome.addOrnateFrame(content, 's3ui_inventory', chrome.FRAME_SIZE_PANEL, 1, chrome.FRAME_CORNER_SCALE_PANEL)
	return {
		type = ui.TYPE.Widget,
		layer = ctx.rootLayer,
		props = {
			anchor = metrics.windowAnchor,
			relativePosition = ctx.windowRelativePosition or metrics.windowRelativePosition,
			size = metrics.windowSize,
		},
		content = content,
	}
end

return M
