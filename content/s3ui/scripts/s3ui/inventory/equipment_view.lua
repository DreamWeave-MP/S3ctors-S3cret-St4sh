---@omw-context player

local ui = require("openmw.ui")
local util = require("openmw.util")
local detailPanel = require("scripts.s3ui.inventory.equipment_detail_panel")
local leftPanel = require("scripts.s3ui.inventory.equipment_left_panel")

local v2 = util.vector2

local M = {}

local LEFT_WIDTH = 1 - detailPanel.WIDTH

function M.content(ctx)
	return ui.content({
		leftPanel.layout(ctx, LEFT_WIDTH),
		detailPanel.layout(ctx.state),
	})
end

function M.make(ctx)
	return {
		name = "s3ui_equipment_view",
		type = ui.TYPE.Flex,
		props = { horizontal = true, size = v2(0, 0), relativeSize = v2(0, 1), autoSize = false },
		external = { grow = 1, stretch = 1 },
		content = M.content(ctx),
	}
end

return M
