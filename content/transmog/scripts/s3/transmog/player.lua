---@omw-context player

local async = require 'openmw.async'
local input = require 'openmw.input'

require 'scripts.s3.transmog.settings'

local menu = require 'scripts.s3.transmog.menu'

input.registerTriggerHandler('transmogOpen', async:callback(menu.toggle))

input.registerTriggerHandler('transmogConfirm', async:callback(menu.confirm))

input.registerActionHandler('transmogPreview', async:callback(menu.preview))
input.registerActionHandler(
  'transmogRotateLeft',
  async:callback(function(active) menu.rotate(active and -0.05 or 0) end)
)
input.registerActionHandler(
  'transmogRotateRight',
  async:callback(function(active) menu.rotate(active and 0.05 or 0) end)
)

return {
  eventHandlers = {
    TransmogCreated = menu.created,
    UiModeChanged = function(data)
      if menu.isOpen() and data.newMode ~= require('openmw.interfaces').UI.MODE.Interface then
        menu.close()
      end
    end,
  },
  engineHandlers = {
    onKeyPress = function(key)
      if menu.isOpen() and key.code == input.KEY.Escape then menu.close() end
    end,
  },
}
