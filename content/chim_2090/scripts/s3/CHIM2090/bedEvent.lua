local s3lf = require('scripts.s3.lf')
local types = require('openmw.types')

return {
  engineHandlers = {
    onActivated = function(actor)
      if actor.type == types.Player then
        actor:sendEvent('s3Chim_objectActivated', { owner = s3lf.owner.recordId, origin = s3lf.recordId })
      end
    end,
  },
}
