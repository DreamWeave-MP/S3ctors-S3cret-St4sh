local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
-- local self = require('openmw.self')

local tearDownTransmog = require('scripts.s3.transmog.lib.teardowntransmog')

return function()
  local button = common.createButton("Close", true)
  button.props.name =  "Close Button"
  button.events.mousePress = async:callback(function()
      tearDownTransmog()
      -- self:sendEvent('updateInventoryContainer', {resetPortraits = true})
  end)
  return button
end
