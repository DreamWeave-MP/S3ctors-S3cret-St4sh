---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v2 = util.vector2

local CATEGORY_ICON_ATLAS = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/category_icons.dds'
local CATEGORY_SMALL_ICON_ATLAS = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/small_icons.dds'

---@class S3UI.InventoryIconsModule
local M = {
	ICON_RELATIVE_SIZE = v2(0.58, 0.58),
	COUNT_RELATIVE_SIZE = v2(0.28, 0.22),
	ITEM_STATE_BADGE_RELATIVE_SIZE = v2(0.22, 0.22),
	LIST_STATE_BADGE_ICON_FRACTION = 0.36,
	CATEGORY_ICON_COUNT_SIZE = v2(0.34, 0.24),
	CATEGORY_ICON_TOGGLE_SIZE = v2(0.24, 0.24),
	MAIN_RELATIVE_SIZE = v2(1, 0),
	VIEW_TOGGLE_ICON_SIZE = v2(0.74, 0.74),
	SORT_ICON_RELATIVE_SIZE = v2(0.68, 0.68),
	SORT_DIRECTION_RELATIVE_SIZE = v2(0.34, 0.34),
	CATEGORY_HEADER_COLOR = util.color.rgb(0.18, 0.36, 0.68),
	CATEGORY_ACTIVE_COLOR = util.color.rgb(0.24, 0.47, 0.86),
	CATEGORY_COLLAPSED_COLOR = util.color.rgb(0.12, 0.18, 0.28),
	VIEW_GLYPH_COLOR = util.color.rgb(0.9, 0.84, 0.62),
}

M.TOOLTIP = {
	typeGeneric = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_generic.dds' },
	typeWeapon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_weapon.dds' },
	typeRangedWeapon = ui.texture {
		path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_ranged_weapon.dds',
	},
	typeArmor = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_armor.dds' },
	typeBook = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_book.dds' },
	value = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/value.dds' },
	weight = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weight.dds' },
	goldPerWeight = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/value.dds' },
	condition = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/durability.dds' },
	reach = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_reach.dds' },
	speed = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_speed.dds' },
	damage = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_damage.dds' },
	damageSpeed = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_damage_speed.dds' },
	armorRating = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/armor_rating.dds' },
}

M.SORT = {
	value = M.TOOLTIP.value,
	weight = M.TOOLTIP.weight,
	effectiveness = M.TOOLTIP.damageSpeed,
	condition = M.TOOLTIP.condition,
}

M.SORT_DIRECTION = {
	ascending = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/sort/ascending.dds' },
	descending = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/sort/descending.dds' },
}

M.CATEGORY = {
	all = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(25, 29), size = v2(206, 204) },
	weapons = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(284, 3), size = v2(224, 225) },
	armor = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(555, 0), size = v2(169, 256) },
	apparel = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(17, 536), size = v2(222, 226) },
	alchemy = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(802, 25), size = v2(194, 212) },
	books = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(4, 260), size = v2(247, 241) },
	tools = ui.texture { path = CATEGORY_SMALL_ICON_ATLAS, offset = v2(786, 2), size = v2(86, 124) },
	misc = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(1074, 29), size = v2(153, 207) },
}

M.CATEGORY_RELATIVE_SIZES = {
	all = v2(0.62, 0.58),
	weapons = v2(0.7, 0.6),
	armor = v2(0.48, 0.66),
	apparel = v2(0.58, 0.58),
	alchemy = v2(0.6, 0.62),
	books = v2(0.66, 0.6),
	tools = v2(0.44, 0.6),
	misc = v2(0.46, 0.58),
}

M.VIEW_TOGGLE = ui.texture { path = CATEGORY_SMALL_ICON_ATLAS, offset = v2(385, 1), size = v2(126, 126) }

M.ITEM_STATE = {
	equipped = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/equipped.dds' },
	enchanted = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/enchanted.dds' },
	broken = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/broken.dds' },
}

M.MENU = {
	inventory = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/inventory.dds' },
	magic = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/magic.dds' },
	journal = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/journal.dds' },
	character = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/character.dds' },
	equipment = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/equipment.dds' },
}

M.MAIN_MENU_BUTTONS = {
	{
		key = 'inventory',
		tab = 'inventory',
		icon = M.MENU.inventory,
	},
	{ key = 'magic', icon = M.MENU.magic },
	{ key = 'journal', icon = M.MENU.journal },
	{
		key = 'character',
		icon = M.MENU.character,
	},
}

return M
