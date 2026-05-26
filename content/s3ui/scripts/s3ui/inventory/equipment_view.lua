---@omw-context player

local ui = require("openmw.ui")
local util = require("openmw.util")
local detailPanel = require("scripts.s3ui.inventory.equipment_detail_panel")
local leftPanel = require("scripts.s3ui.inventory.equipment_left_panel")

local v2 = util.vector2

local M = {}

local LEFT_WIDTH = 1
local DETAIL_X = 0.68
local DETAIL_WIDTH = 0.32
local DETAIL_HEIGHT = 0.86
local DETAIL_Y = (1 - DETAIL_HEIGHT) * 0.5

function M.createLeftPanel(ctx)
	return leftPanel.create(ctx, LEFT_WIDTH)
end

function M.updateLeftPanel(element, ctx)
	return leftPanel.update(element, ctx, LEFT_WIDTH)
end

function M.createDetailPanel(ctx)
	return detailPanel.create(ctx, DETAIL_WIDTH, DETAIL_X, DETAIL_HEIGHT, DETAIL_Y)
end

function M.updateDetailPanel(element, ctx)
	return detailPanel.update(element, ctx, DETAIL_WIDTH, DETAIL_X, DETAIL_HEIGHT, DETAIL_Y)
end

function M.content(ctx)
	return ui.content({
		ctx.leftElement or leftPanel.layout(ctx, LEFT_WIDTH),
		ctx.detailElement or detailPanel.layout(ctx, DETAIL_WIDTH, DETAIL_X, DETAIL_HEIGHT, DETAIL_Y),
	})
end

function M.make(ctx)
	return {
		name = "s3ui_equipment_view",
		type = ui.TYPE.Widget,
		props = { size = v2(0, 0), relativeSize = v2(0, 1), autoSize = false },
		external = { grow = 1, stretch = 1 },
		content = M.content(ctx),
	}
end

return M
