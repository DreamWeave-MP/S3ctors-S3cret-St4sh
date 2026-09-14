---@omw-context menu|player

local dialog = require 'scripts.s3.ui.recipes.dialog'

return {
  dialog = dialog.basic,
  ['dialog.confirm'] = dialog.confirm,
  settings = require 'scripts.s3.ui.recipes.settings',
  itemGrid = require 'scripts.s3.ui.recipes.itemGrid',
  tabbedWindow = require 'scripts.s3.ui.recipes.tabbedWindow',
  searchableList = require 'scripts.s3.ui.recipes.searchableList',
}
