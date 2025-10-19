-- [[
-- Figure out blocks for other weapons
--]]

local anim = require 'openmw.animation'
local async = require 'openmw.async'
local core = require 'openmw.core'
local input = require 'openmw.input'
local self = require 'openmw.self'
local time = require 'openmw_aux.time'
local types = require 'openmw.types'
local util = require 'openmw.util'
local ui = require 'openmw.ui'

local BLOCK_ANIM = 'activeblock'
local HUGE = math.huge

local I = require 'openmw.interfaces'

-- Store references to stop functions here so they can be self-referential
-- Mostly used to restore block after being hit, while holding Mouse 3
local stopFns = {}

-- Attributes
local Attributes = self.type.stats.attributes
local Strength = Attributes.strength(self)
local Agility = Attributes.agility(self)
local Luck = Attributes.luck(self)

-- Skills
local Skills = self.type.stats.skills
local Block = Skills.block(self)

-- Dynamic Stats
local DynamicStats = self.type.stats.dynamic
local health = DynamicStats.health(self)
local Fatigue = DynamicStats.fatigue(self)

-- Extra frames to not take melee damage after blocking
-- This should maybe scale based on block skill?
-- or some value related to the shield itself, like weight and speed
-- State
local hasIFrames = false
local IFramesDuration = 2 * time.second
local ActiveEffects = self.type.activeEffects(self)
local SanctuaryStrength = 1000

-- Can probably remove this now with onHit
local prevHealth = 0

-- Values for timed block bonus
-- Right now it uses lightning shield but maybe could be better?
local hasTimedBonus = false
local LightningShieldStrength = 0
local BlockButton = 3

local weaponTypes = types.Weapon.TYPE
local oneHandedTypes = {
    [weaponTypes.AxeOneHand] = true,
    [weaponTypes.ShortBladeOneHand] = true,
    [weaponTypes.LongBladeOneHand] = true,
    [weaponTypes.BluntOneHand] = true,
}

local function isBlocking()
    return anim.getActiveGroup(self, anim.BONE_GROUP.LeftArm) == BLOCK_ANIM
end

--- Checks if the actor is currently playing any one-handed attack animation.
--- Slightly weak, since we're not accounting for the possibility of empty or two-handed blocks
--- but since we have no relevant animations it probably doesn't matter at the moment.
local function isAttacking()
    return anim.getActiveGroup(self, anim.BONE_GROUP.RightArm):find('weapononehand')
end

local function inWeaponStance()
    return self.type.getStance(self) == types.Actor.STANCE.Weapon
end

local function normalizedFatigue()
    return util.clamp(Fatigue.current / Fatigue.base, 0.0, 1.0)
end

local function blockIsPressed()
    return input.isMouseButtonPressed(BlockButton)
end

local function playingHitstun()
    return anim.isPlaying(self, 'hitstun')
end

local function usingOneHanded()
    local weapon = types.Actor.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then return false end

    local weaponRecord = types.Weapon.records[weapon.recordId]
    if not weaponRecord then return false end

    return oneHandedTypes[weaponRecord.type]
end

local function usingShield()
    local carriedLeft = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedLeft)
    if not carriedLeft then return false end

    local shieldRecord = types.Armor.records[carriedLeft.recordId]
    if not shieldRecord then return false end

    return true
end

--- Get the weight of the shield
local function getBlockingWeight()
    local equipment = self.type.getEquipment(self)
    local shield = equipment[self.type.EQUIPMENT_SLOT.CarriedLeft]
    local weapon = equipment[self.type.EQUIPMENT_SLOT.CarriedRight]

    local shieldWeight = shield and types.Armor.records[shield.recordId].weight or 0
    local weaponWeight = weapon and types.Weapon.records[weapon.recordId].weight or 0

    return shield and shieldWeight or weaponWeight
end

local function canBlock()
    return
        inWeaponStance()
        and usingOneHanded()
        and usingShield()
        and not isBlocking()
        and not I.UI.getMode()
        and not playingHitstun()
        and not isAttacking()
        and self.type.isOnGround(self)
end

local blockSpeedConfig = {
    LuckWeight = 0.15,
    AgilityWeight = 0.3,
    BaseSpeed = 0.75,
}

--- Determine how fast the block animation should play, based on a combinatino of luck, agility, and randomness.
--- The modifier is also multiplied by normalized fatigue, so more tired characters will block more slowly.
---@return number blockSpeed the speed at which the blocking animation should play.
local function getBlockSpeed()
    local normalizedAgility = math.min(Agility.modified, 100) / 100.0
    local normalizedLuck = math.min(Luck.modified, 100) / 100.0

    local randomFactor = (math.random(25) - 5) / 100.0

    local speedModifier = (normalizedLuck * blockSpeedConfig.LuckWeight)
        + (normalizedAgility * blockSpeedConfig.AgilityWeight)
        + randomFactor

    return blockSpeedConfig.BaseSpeed
        + (speedModifier * normalizedFatigue())
end

local blockAnimData = {
    startKey = 'start',
    stopKey = 'stop',
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
    },
    autoDisable = false,
    blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
    speed = getBlockSpeed(),
}
local function playBlockAnimation()
    I.AnimationController.playBlendedAnimation(BLOCK_ANIM, blockAnimData)
end

local idleAnimData = {
    startKey = 'loop start',
    stopKey = 'loop stop',
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
    },
    autoDisable = true,
}
local function playIdleAnimation()
    I.AnimationController.playBlendedAnimation('idle1', idleAnimData)
end

local function disableTimedBlockBonus()
    if not hasTimedBonus then return end

    ActiveEffects:modify(-LightningShieldStrength, core.magic.EFFECT_TYPE.LightningShield)
    print('Updated lightning shield value:', ActiveEffects:getEffect(core.magic.EFFECT_TYPE.LightningShield).magnitude)
    -- ui.showMessage("Removing lightning shield")
    hasTimedBonus = false
end

local function updateTimedBlockDamage()
    local itemWeight = getBlockingWeight()

    -- Base damage calculation
    local baseDamage = (Block.base * 0.2) + (Strength.modified * 0.1) + (itemWeight * .1)

    -- The shield does 10% magnitude as damage, so multiply intended damage by 10
    LightningShieldStrength = math.min(baseDamage, 50) * 10
end

local function applyTimedBlockBonus()
    updateTimedBlockDamage()

    ActiveEffects:modify(LightningShieldStrength, core.magic.EFFECT_TYPE.LightningShield)
    print('Updated lightning shield value:', LightningShieldStrength)

    -- ui.showMessage("Adding lightning shield")

    hasTimedBonus = true
end

local function timedBlockHandler(group, key)
    -- print(group, key)

    if key == 'stop' then
        -- ui.showMessage("Disabling timed block bonus from handler")
        applyTimedBlockBonus()

        -- disableTimedBlockBonus()

        -- we need some way to calculate the delay!
        async:newUnsavableSimulationTimer(time.second / 2, disableTimedBlockBonus)
        -- playIdleAnimation()
    end
    -- print(groupName, key)
end

I.AnimationController.addTextKeyHandler(BLOCK_ANIM, timedBlockHandler)

local function toggleBlock(enable)
    if isBlocking() == enable then return end

    if enable then
        playBlockAnimation()
    else
        disableTimedBlockBonus()
        playIdleAnimation()
    end
end

local function blockBegin(button)
    if I.UI.getMode() or button ~= BlockButton or not canBlock() then return end
    toggleBlock(true)
end

local function blockEnd(button)
    if button ~= BlockButton or not isBlocking() then return end
    toggleBlock(false)
end

local function beginIFrames(currentLegs)
    if stopFns["iframes"] then return end

    ui.showMessage('Adding iFrames')
    ActiveEffects:modify(SanctuaryStrength, core.magic.EFFECT_TYPE.Sanctuary)
    hasIFrames = true

    stopFns["iframes"] = time.runRepeatedly(function()
        if anim.getCompletion(self, currentLegs) then
            async:newUnsavableSimulationTimer(IFramesDuration, function()
                if not stopFns["iframes"] then return end

                if hasIFrames then
                    ui.showMessage("Removing iFrames")
                    ActiveEffects:modify(-SanctuaryStrength, core.magic.EFFECT_TYPE.Sanctuary)
                    hasIFrames = false
                end

                stopFns["iframes"]()

                stopFns["iframes"] = nil
            end)
        end
    end, 0.1)
end

local function ensureNoBlock()
    if Block.modifier == -HUGE then return end
    Block.modifier = -HUGE
end

local function noBlockInMenus()
    if not I.UI.getMode() then return end
    toggleBlock(false)
    return true
end

--- Restore the block if it was interrupted by something else
local function blockIfPossible()
    if not blockIsPressed() or not canBlock() then return end
    toggleBlock(true)
end

local function interruptBlock()
    if not isBlocking() then return end

    local shouldInterrupt = input.getBooleanActionValue('Use') or
        anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody):find('jump')

    if not shouldInterrupt then return end

    toggleBlock(false)
end

--- Implement logic for determining the parry window, and associated fatigue damage
--- Also consider implementing iFrames. The current mechanic appears to be designed so as to give you a shitton of sanctuary effect 
--- until the hit animation finishes.
return {
    interfaceName = 's3ChimBlock',
    interface = {
        canBlock = canBlock,
        isBlocking = isBlocking,
        toggleBlock = toggleBlock,
    },
    engineHandlers = {
        onMouseButtonPress = blockBegin,
        onMouseButtonRelease = blockEnd,
        onFrame = function(dt)
            ensureNoBlock()
            if noBlockInMenus() then return end

            blockIfPossible()

            interruptBlock()

            -- local currentTorso = anim.getActiveGroup(self, anim.BONE_GROUP.Torso)
            local currentLegs = anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody)
            -- print("Current legs: " .. currentLegs .. " Current torso: " .. currentTorso)

            if (string.find(currentLegs, 'hit') or string.find(currentLegs, 'shield'))
                and isBlocking() then
                if health.current < prevHealth then
                    health.current = prevHealth
                end

                if not hasTimedBonus then
                    beginIFrames(currentLegs)

                    ui.showMessage("Blocking hit")
                else
                    -- CurrentParryDelay = MaxParryDelay
                    -- ui.showMessage("Parry!")
                end
            end

            prevHealth = health.current
        end,
    }
}
