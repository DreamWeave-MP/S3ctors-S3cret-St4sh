local types = require 'openmw.types'

return {
    eventHandlers = {
        S3maphoreStaticUpdate = function(sender)
            if sender.cell.isExterior then return end

            local statics, addedStatics = {}, {}
            local staticsInCell = sender.cell:getAll(types.Static)

            for _, static in ipairs(staticsInCell) do
                if not addedStatics[static.recordId] then
                    addedStatics[static.recordId] = true

                    statics[#statics + 1] = static
                end
            end

            sender:sendEvent('S3maphoreStaticCollectionUpdated', statics)
        end,
    }
}
