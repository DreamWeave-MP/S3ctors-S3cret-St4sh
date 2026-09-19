---@omw-context menu|player

local dialog = require 'scripts.h3.ui.recipes.dialog'
local itemGrid = require 'scripts.h3.ui.recipes.itemGrid'
local searchableList = require 'scripts.h3.ui.recipes.searchableList'
local section = require 'scripts.h3.ui.recipes.section'
local settings = require 'scripts.h3.ui.recipes.settings'
local tabbedWindow = require 'scripts.h3.ui.recipes.tabbedWindow'

return {
  dialog = dialog.basic,
  confirmDialog = dialog.confirm,
  itemGrid = itemGrid,
  searchableList = searchableList,
  section = section,
  settings = settings,
  tabbedWindow = tabbedWindow,
}
