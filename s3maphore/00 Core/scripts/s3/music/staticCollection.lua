local types = require 'openmw.types'
local world = require 'openmw.world'

return {
    interfaceName = 'S3maphoreG',
    interface = {
        findCellMatches = function(pattern)
            local cellStr = ''

            for _, cell in ipairs(world.cells) do
                if cell.name
                    and cell.name ~= ''
                    and cell.name:lower():find(pattern)
                then
                    cellStr = ("%s['%s'] = true,\n"):format(cellStr, cell.name:lower())
                end
            end

            return cellStr
        end,
    },

    eventHandlers = {
        S3maphoreStaticUpdate = function(sender)
            if sender.cell.isExterior then return end

            local addedStatics, addedContentFiles = {}, {}

            local staticsInCell = sender.cell:getAll(types.Static)

            for _, static in ipairs(staticsInCell) do
                if not addedStatics[static.recordId] then
                    addedStatics[#addedStatics + 1] = static.recordId
                end

                if not addedContentFiles[static.contentFile] then
                    if static.contentFile and static.contentFile ~= '' then
                        addedContentFiles[#addedContentFiles + 1] = static.contentFile:lower()
                    end
                end
            end

            sender:sendEvent('S3maphoreStaticCollectionUpdated',
                { contentFiles = addedContentFiles, recordIds = addedStatics, })
        end,
    },

}
