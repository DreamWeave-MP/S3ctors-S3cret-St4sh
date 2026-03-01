local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local self = require('openmw.self')

return function()
  local button = common.createButton("Clear", true)
  button.props.name =  "Clear Button"
  button.events.mousePress = async:callback(function()
      self:sendEvent('updateInventoryContainer', {resetPortraits = true})
  end)
  return button
end
