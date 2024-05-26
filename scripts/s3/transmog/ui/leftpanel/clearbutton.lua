local async = require('openmw.async')

local common = require('scripts.s3.transmog.ui.common')
local I = require('openmw.interfaces')

return function()
  local button = common.createButton("Clear")
  button.events.mousePress = async:callback(function()
      local Aliases = I.transmogActions.MenuAliases()
      if not Aliases['confirm screen'] or not Aliases['confirm screen input']
      then error('Confirm screen or text missing') end
      I.transmogActions.MogMenuEvent({targetName = 'confirm screen input', action = 'clear'})
      end)
  return button
end
