---@omw-context local

local I = require 'openmw.interfaces'
local types = require 'openmw.types'
local s3lf = I.s3.lf

return {
  engineHandlers = {
    onActivated = function(actor)
      if actor.type == types.Player then
        actor:sendEvent(
          's3Chim_objectActivated',
          { owner = s3lf.owner.recordId, origin = s3lf.recordId }
        )
      end
    end,
  },
}
