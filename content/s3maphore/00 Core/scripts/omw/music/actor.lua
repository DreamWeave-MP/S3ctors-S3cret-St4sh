---@omw-context local

local next, pairs, require = next, pairs, require

local self = require 'openmw.self'
local Players

local Targets = {}
local TargetChangeData = { actor = self, targets = Targets }

---@diagnostic disable-next-line: undefined-field
local clearImpl = table.clear or function(t) for k in pairs(t) do t[k] = nil end end
local function clear()
    clearImpl(Targets)
end

local IsDeathFinished, IsInActorsProcessingRange, GetStance, GetTargets, IsFleeing, UnarmedStance

---@param eventId string
---@param eventData any
local function emitToPlayers(eventId, eventData)
    for i = 1, #Players do
        Players[i]:sendEvent(eventId, eventData)
    end
end

do
    local I = require 'openmw.interfaces'
    local AI = I.AI
    GetTargets, IsFleeing = AI.getTargets, AI.isFleeing

    local types = require 'openmw.types'
    IsDeathFinished, IsInActorsProcessingRange = types.Actor.isDeathFinished, types.Actor.isInActorsProcessingRange
    GetStance, UnarmedStance = types.Actor.getStance, types.Actor.STANCE.Nothing

    Players = require 'openmw.nearby'.players

    ---@param attack openmw.interfaces.Combat.AttackInfo
    local function s3maphoreAttackHandler(attack)
        if not attack.successful then return end
        emitToPlayers('S3maphoreClearTargetCache', self.id)
    end

    I.Combat.addOnHitHandler(s3maphoreAttackHandler)
end

local function emitTargetsChanged()
    emitToPlayers('OMWMusicCombatTargetsChanged', TargetChangeData)
end

local function onUpdate(dt)
    local startedWithTargets = next(Targets) ~= nil
    local isDead = IsDeathFinished(self) or not IsInActorsProcessingRange(self)

    local shouldClear = isDead and startedWithTargets
    local shouldSkipFetch = isDead

    if not shouldSkipFetch then
        shouldSkipFetch = (GetStance(self) == UnarmedStance)
            and not startedWithTargets
            and not IsFleeing()
            and dt > 0
    end

    if shouldClear then
        clear()
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

        clear()

        for i = 1, numNewTargets do Targets[i] = newTargets[i] end
    end

    if changed then
        emitTargetsChanged()
    end
end

local function onInactive()
    if not next(Targets) then return end
    clear()
    emitTargetsChanged()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
    },
}
