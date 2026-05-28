local isOpenMW = require 'scripts.s3.isOpenMW'
local I, core, self, types, nearby, AI

if isOpenMW then
    I = require("openmw.interfaces")
    core = require 'openmw.core'
    self = require("openmw.self")
    types = require("openmw.types")
    nearby = require("openmw.nearby")
    AI = I.AI
end

if isOpenMW and core.API_REVISION >= 91 then
    local Combat = I.Combat
    Combat.addOnHitHandler(
        function(attack)
            if not attack.successful then return end

            for _, player in ipairs(nearby.players) do
                player:sendEvent('S3maphoreClearTargetCache', self.id)
            end
        end
    )
end

local targets = {}

local function emitTargetsChangedOMW()
    for _, actor in ipairs(nearby.players) do
        actor:sendEvent("OMWMusicCombatTargetsChanged", { actor = self, targets = targets })
    end
end

--- @param e referenceDeactivatedEventData|damagedEventData
local function emitTargetsChangedMWSE(e)
    event.trigger("OMWMusicCombatTargetsChanged", { actor = e.reference, targets = targets })
end

--- @param e combatStartedEventData|combatStoppedEventData
--- @param eventType tes3.event
local function emitTargetsAddRemove(e, eventType)
    if eventType == tes3.event.combatStarted then
        event.trigger("S3maphoreCombatStarted", { actor = e.actor })
    elseif eventType == tes3.event.combatStopped then
        event.trigger("S3maphoreCombatStopped", { actor = e.actor })
    end
end

local function onUpdate(dt)
    if types.Actor.isDeathFinished(self) or not types.Actor.isInActorsProcessingRange(self) then
        if next(targets) ~= nil then
            targets = {}
            emitTargetsChangedOMW()
        end

        return
    end

    -- Early-out for actors without targets and without combat state when the game is not paused
    -- TODO: use events or engine handlers to detect when targets change
    local isStanceNothing = types.Actor.getStance(self) == types.Actor.STANCE.Nothing
    if isStanceNothing and next(targets) == nil and not AI.isFleeing() and dt > 0 then
        return
    end

    local newTargets = AI.getTargets("Combat")

    local changed = false
    if #newTargets ~= #targets then
        changed = true
    else
        for i, target in ipairs(targets) do
            if target ~= newTargets[i] then
                changed = true
                break
            end
        end
    end

    targets = newTargets
    if changed then
        emitTargetsChangedOMW()
    end
end

local function onInactiveOMW()
    if next(targets) ~= nil then
        targets = {}
        emitTargetsChangedOMW()
    end
end

--- @param e referenceDeactivatedEventData
local function onInactiveMWSE(e)
    if e.reference ~= tes3.player and (e.reference.objectType == tes3.objectType.npc or e.reference.objectType == tes3.objectType.creature) then
        if next(targets) ~= nil then
            targets = {}
            emitTargetsChangedMWSE(e)
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = isOpenMW and onInactiveOMW or onInactiveMWSE
    },

    mwse = {
        --- @param e damageEventData
        onDamage = function(e)
            if e.reference ~= tes3.player then
                event.trigger('S3maphoreClearTargetCache')
            end
        end,

        --- @param e damagedEventData
        onDeath = function(e)
            if e.reference ~= tes3.player and e.killingBlow and next(targets) ~= nil then
                targets = {}
                emitTargetsChangedMWSE(e)
            end
        end,

        --- @param e combatStartedEventData
        combatStarted = function(e)
            if e.actor ~= tes3.player.mobile then
                local changed = false
                if e.target ~= targets then
                    changed = true
                    targets = e.target
                end

                if changed then
                    emitTargetsAddRemove(e, tes3.event.combatStarted)
                end
            end
        end,

        --- @param e combatStoppedEventData
        combatStopped = function(e)
            if e.actor ~= tes3.player.mobile then
                local changed = false
                if targets ~= nil then
                    changed = true
                    targets = nil
                end

                if changed then
                    emitTargetsAddRemove(e, tes3.event.combatStopped)
                end
            end
        end
    }
}
