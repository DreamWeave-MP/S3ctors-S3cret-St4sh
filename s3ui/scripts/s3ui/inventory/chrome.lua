---@omw-context player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v2 = util.vector2

---@class S3UI.InventoryChromeModule
local M = {}

M.WHITE_TEXTURE = ui.texture { path = 'white' }
M.BACKGROUND_COLOR = util.color.rgb(0, 0, 0)
local SIMPLE_BORDER_COLOR = util.color.rgb(0, 0, 0)

M.FRAME_SIZE_PANEL = 34
M.FRAME_SIZE_MEDIUM = 22
M.FRAME_CORNER_SCALE_PANEL = (M.FRAME_SIZE_MEDIUM - 1) / M.FRAME_SIZE_PANEL
M.SIMPLE_BORDER_THICKNESS = 2

local ORNATE_FRAME_TEXTURES = {
	-- Clean center strips; the ornate accents live in the corner atlas.
	edgeH = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/edge_h.dds' },
	edgeV = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/edge_v.dds' },
	topLeft = ui.texture {
		path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/corners.dds',
		offset = v2(0, 0),
		size = v2(64, 64),
	},
	topRight = ui.texture {
		path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/corners.dds',
		offset = v2(64, 0),
		size = v2(64, 64),
	},
	bottomLeft = ui.texture {
		path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/corners.dds',
		offset = v2(0, 64),
		size = v2(64, 64),
	},
	bottomRight = ui.texture {
		path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/borders/ornate/corners.dds',
		offset = v2(64, 64),
		size = v2(64, 64),
	},
}

---@param text string
---@param props table|nil
---@return table
function M.textProps(text, props)
	local result = {}
	if props then
		for key, value in pairs(props) do
			if key ~= 'name' then
				result[key] = value
			end
		end
	end
	result.text = text
	return result
end

---@param text string
---@param template table|nil
---@param props table|nil
---@return table
function M.textLine(text, template, props)
	local name = props and props.name or nil
	return {
		name = name,
		template = template or I.MWUI.templates.textNormal,
		props = M.textProps(text, props),
	}
end

---@return number
function M.backgroundAlpha()
	return ui._getMenuTransparency()
end

---@param frameSize number
---@return integer
local function frameThickness(frameSize)
	local thickness = math.floor(frameSize * 0.14)
	if thickness < 2 then
		return 2
	end
	return thickness
end

---@param frameSize number
---@return integer
function M.frameInset(frameSize)
	return frameThickness(frameSize) + 2
end

---@param content openmw.ui.Content
---@param prefix string
---@param frameSize number
---@param alpha number|nil
---@param cornerScale number|nil
function M.addOrnateFrame(content, prefix, frameSize, alpha, cornerScale)
	local thickness = frameThickness(frameSize)
	cornerScale = cornerScale or 1
	local cornerPixelSize = math.floor(frameSize * cornerScale + 0.5)
	if cornerPixelSize < thickness then
		cornerPixelSize = thickness
	end
	local halfFrame = math.floor(cornerPixelSize * 0.5)
	local cornerOverhang = math.floor(4 * cornerScale + 0.5)
	local cornerSize = v2(cornerPixelSize, cornerPixelSize)
	alpha = alpha or 1

	content:add {
		name = prefix .. '_frame_top',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.edgeH,
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
			position = v2(halfFrame, 0),
			size = v2(-halfFrame * 2, thickness),
			relativeSize = v2(1, 0),
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_bottom',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.edgeH,
			anchor = v2(0, 1),
			relativePosition = v2(0, 1),
			position = v2(halfFrame, -thickness),
			size = v2(-halfFrame * 2, thickness),
			relativeSize = v2(1, 0),
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_left',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.edgeV,
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
			position = v2(0, halfFrame),
			size = v2(thickness, -halfFrame * 2),
			relativeSize = v2(0, 1),
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_right',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.edgeV,
			anchor = v2(1, 0),
			relativePosition = v2(1, 0),
			position = v2(-thickness, halfFrame),
			size = v2(thickness, -halfFrame * 2),
			relativeSize = v2(0, 1),
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_top_left',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.topLeft,
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
			position = v2(-cornerOverhang, -cornerOverhang),
			size = cornerSize,
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_top_right',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.topRight,
			anchor = v2(1, 0),
			relativePosition = v2(1, 0),
			position = v2(cornerOverhang, -cornerOverhang),
			size = cornerSize,
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_bottom_left',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.bottomLeft,
			anchor = v2(0, 1),
			relativePosition = v2(0, 1),
			position = v2(-cornerOverhang, cornerOverhang),
			size = cornerSize,
			alpha = alpha,
		},
	}
	content:add {
		name = prefix .. '_frame_bottom_right',
		type = ui.TYPE.Image,
		props = {
			resource = ORNATE_FRAME_TEXTURES.bottomRight,
			anchor = v2(1, 1),
			relativePosition = v2(1, 1),
			position = v2(cornerOverhang, cornerOverhang),
			size = cornerSize,
			alpha = alpha,
		},
	}
end

---@param content openmw.ui.Content
---@param prefix string
---@param alpha number|nil
---@param insertIndex integer|nil
function M.addSimpleBorder(content, prefix, alpha, insertIndex)
	alpha = alpha or 0.78

	local function addBorderPart(layout)
		if insertIndex then
			content:insert(insertIndex, layout)
			insertIndex = insertIndex + 1
		else
			content:add(layout)
		end
	end

	addBorderPart {
		name = prefix .. '_simple_border_top',
		type = ui.TYPE.Image,
		props = {
			resource = M.WHITE_TEXTURE,
			color = SIMPLE_BORDER_COLOR,
			alpha = alpha,
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
			size = v2(0, M.SIMPLE_BORDER_THICKNESS),
			relativeSize = v2(1, 0),
		},
	}
	addBorderPart {
		name = prefix .. '_simple_border_bottom',
		type = ui.TYPE.Image,
		props = {
			resource = M.WHITE_TEXTURE,
			color = SIMPLE_BORDER_COLOR,
			alpha = alpha,
			relativePosition = v2(0, 1),
			position = v2(0, -M.SIMPLE_BORDER_THICKNESS),
			size = v2(0, M.SIMPLE_BORDER_THICKNESS),
			relativeSize = v2(1, 0),
		},
	}
	addBorderPart {
		name = prefix .. '_simple_border_left',
		type = ui.TYPE.Image,
		props = {
			resource = M.WHITE_TEXTURE,
			color = SIMPLE_BORDER_COLOR,
			alpha = alpha,
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
			size = v2(M.SIMPLE_BORDER_THICKNESS, 0),
			relativeSize = v2(0, 1),
		},
	}
	addBorderPart {
		name = prefix .. '_simple_border_right',
		type = ui.TYPE.Image,
		props = {
			resource = M.WHITE_TEXTURE,
			color = SIMPLE_BORDER_COLOR,
			alpha = alpha,
			relativePosition = v2(1, 0),
			position = v2(-M.SIMPLE_BORDER_THICKNESS, 0),
			size = v2(M.SIMPLE_BORDER_THICKNESS, 0),
			relativeSize = v2(0, 1),
		},
	}
end

return M
