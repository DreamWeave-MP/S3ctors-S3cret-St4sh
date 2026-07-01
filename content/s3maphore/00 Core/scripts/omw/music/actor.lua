---@omw-context local

local next, pairs, require = next, pairs, require

local self = require 'openmw.self'
local Players

local Targets = {}
local TargetChangeData = { actor = self, targets = Targets }

---@diagnostic disable-next-line: undefined-field
local clear = table.clear or function(t) for k in pairs(t) do t[k] = nil end end

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
    --- If the actor is dead, or simply out of processing range, we can handoff to the next actor in the chain immediately
    if IsDeathFinished(self) or not IsInActorsProcessingRange(self) then
        if next(Targets) then
            clear(Targets)
            emitTargetsChanged()
        end

        return
    end

    -- Early-out for actors without targets and without combat state when the game is not paused
    -- TODO: use events or engine handlers to detect when targets change
    if (GetStance(self) == UnarmedStance) and not next(Targets) and not IsFleeing() and dt > 0 then
        return
    end

    local newTargets = GetTargets 'Combat'

    local changed, numTargets = false, #Targets
    if #newTargets ~= numTargets then
        changed = true
    else
        for i = 1, numTargets do
            local target = Targets[i]

            if target ~= newTargets[i] then
                changed = true
                break
            end
        end
    end

    Targets = newTargets

    if not changed then return end

    emitTargetsChanged()
end

local function onInactive()
    if not next(Targets) then return end
    clear(Targets)
    emitTargetsChanged()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
    },
}
