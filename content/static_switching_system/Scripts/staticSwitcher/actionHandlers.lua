---@omw-context global

local world = require 'openmw.world'

local randomGen = require 'scripts.s3.randomgen'

local pairs, pcall = pairs, pcall

local actionHandlers = {
  ['replace'] = function(_, replaceActionData)
    for replaceId, replaceChance in pairs(replaceActionData) do
      if randomGen.float() <= replaceChance then
        local result, replacement = pcall(world.createObject, replaceId)

        if result then return replacement end
      end
    end
  end,
}

return actionHandlers
