---@omw-context local

local next, require = next, require

local gameSelf = require 'openmw.self'

local clear = require 'scripts.s3.music.clear'

local Players
local Targets = {}
local TargetChangeData = { actor = gameSelf, targets = Targets }

local IsDeathFinished, IsInActorsProcessingRange, IsWorldPaused, GetStance, GetTargets, IsFleeing, SendGlobalEvent, UnarmedStance
local SendEvent = gameSelf.sendEvent

do
    local core = require 'openmw.core'
    IsWorldPaused = core.isWorldPaused

    local I = require 'openmw.interfaces'
    local AI = I.AI
    GetTargets, IsFleeing = AI.getTargets, AI.isFleeing

    local types = require 'openmw.types'
    IsDeathFinished, IsInActorsProcessingRange = types.Actor.isDeathFinished, types.Actor.isInActorsProcessingRange
    GetStance, UnarmedStance = types.Actor.getStance, types.Actor.STANCE.Nothing

    Players = require 'openmw.nearby'.players

    ---@param attack openmw.interfaces.Combat.AttackInfo
    local function s3maphoreAttackHandler(attack)
        if not attack.successful or not next(Targets) then return end
        for i = 1, #Players do
            SendEvent(Players[i], 'S3maphoreClearTargetCache', gameSelf.object)
        end
    end

    I.Combat.addOnHitHandler(s3maphoreAttackHandler)
end

local function updateCombatState()
    local startedWithTargets = next(Targets) ~= nil
    local isDead = IsDeathFinished(gameSelf) or not IsInActorsProcessingRange(gameSelf)

    local shouldClear = isDead and startedWithTargets
    local shouldSkipFetch = isDead

    if not shouldSkipFetch then
        shouldSkipFetch = (GetStance(gameSelf) == UnarmedStance)
            and not startedWithTargets
            and not IsFleeing()
            and not IsWorldPaused()
    end

    if shouldClear then
        clear(Targets)
    end

    -- TODO: use events or engine handlers to detect when targets change

    local changed = shouldClear

    if not shouldSkipFetch then
        local newTargets = GetTargets 'Combat'
        local numOldTargets, numNewTargets = #Targets, #newTargets

        if numNewTargets ~= numOldTargets then
            changed = true
        else
            for i = 1, numOldTargets do
                if Targets[i] ~= newTargets[i] then
                    changed = true
                    break
                end
            end
        end

        clear(Targets)

        for i = 1, numNewTargets do Targets[i] = newTargets[i] end
    end

    if changed then
        for i = 1, #Players do
            SendEvent(Players[i], 'OMWMusicCombatTargetsChanged', TargetChangeData)
        end
    end
end
local function onInactive()
    if not next(Targets) then return end
    clear(Targets)

    for i = 1, #Players do
        SendEvent(Players[i], 'OMWMusicCombatTargetsChanged', TargetChangeData)
    end
end

return {
    engineHandlers = {
        onInactive = onInactive,
    },
    eventHandlers = {
        Died = function()
            for i = 1, #Players do
                SendEvent(Players[i], 'S3maphoreClearTargetCache', gameSelf.object)
            end
        end,
        S3maphoreCheckCombat = updateCombatState,
    },
}
