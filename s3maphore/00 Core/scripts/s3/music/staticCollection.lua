local types = require 'openmw.types'
local world = require 'openmw.world'

local NPCFightThreshold = 90
local CreatureFightThreshold = 83

local function cellHasCombatTargets(senderCell)
    local objects = senderCell:getAll()
    local foundLiveHostiles = 0

    for _, object in ipairs(objects) do
        local isNPC = types.NPC.objectIsInstance(object)
        local isCreature = types.Creature.objectIsInstance(object)

        if not isNPC and not isCreature then goto continue end

        local fightStat = object.type.stats.ai.fight(object)
        local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold

        if fightStat.modified >= fightLimit and not object.type.isDead(object) then
            foundLiveHostiles = foundLiveHostiles + 1
        end

        ::continue::
    end

    return foundLiveHostiles > 0
end

local function getStaticsInActorCell(actor)
    local addedStatics, addedContentFiles = {}, {}

    local staticsInCell = actor.cell:getAll(types.Static)

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

    return addedStatics, addedContentFiles
end

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
                    cellStr = ("%s['%s'] = true,\n"):format(cellStr, cell.name:lower():gsub("'", "\\'"))
                end
            end

            return cellStr
        end,

        cellHasCombatTargets = cellHasCombatTargets,

        getStaticsInActorCell = getStaticsInActorCell,
    },

    eventHandlers = {
        S3maphoreCellChanged = function(sender)
            local staticContentFiles, staticRecordIds = getStaticsInActorCell(sender)

            sender:sendEvent('S3maphoreCellDataUpdated', {
                contentFiles = staticContentFiles,
                recordIds = staticRecordIds,
                hasCombatTargets = cellHasCombatTargets(sender.cell)
            })
        end,

        S3maphoreUpdateCellHasCombatTargets = function(sender)
            sender:sendEvent('S3maphoreCombatTargetsUpdated', cellHasCombatTargets(sender.cell))
        end,
    },
}
