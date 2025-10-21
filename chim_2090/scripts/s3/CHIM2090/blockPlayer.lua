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

local BLOCK_ANIM = 'activeblock'
local HUGE = math.huge

local I = require 'openmw.interfaces'

-- Store references to stop functions here so they can be self-referential
-- Mostly used to restore block after being hit, while holding Mouse 3
local stopFns = {}

-- Attributes
local Attributes = self.type.stats.attributes
local Agility = Attributes.agility(self)
local Luck = Attributes.luck(self)
local Strength = Attributes.strength(self)

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
    return anim.getActiveGroup(self, anim.BONE_GROUP.RightArm):find('weapon') ~= nil
        or input.getBooleanActionValue('Use')
end

local function isJumping()
    return anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody):find('jump') ~= nil
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

local blockSounds = {
    lightarmor = 'light armor hit',
    mediumarmor = 'medium armor hit',
    heavyarmor = 'heavy armor hit',
}
local function playBlockSound()
    local shield = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedLeft)
    local shieldRecord = types.Armor.records[shield.recordId]
    if not shieldRecord then return false end

    local shieldSkill = I.Combat.getArmorSkill(shield)
    local shieldSound = blockSounds[shieldSkill]
    core.sound.playSound3d(shieldSound, self)
end

local ShieldVFX = types.Static.records['vfx_shieldhit'].model
local function handleBlockHit(blockData)
    --- We also need to handle skill progression and degradation here!
    playBlockSound()
    if blockData.playVfx then
        core.sendGlobalEvent('SpawnVfx', {
            position = blockData.hitPos,
            model = ShieldVFX
        })
    end
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

local function canBlock()
    return
        inWeaponStance()
        and self.type.isOnGround(self)
        and usingOneHanded()
        and usingShield()
        and not isBlocking()
        and not I.UI.getMode()
        and not playingHitstun()
        and not isAttacking()
        and not isJumping()
end

local blockSpeedConfig = {
    LuckWeight = 0.15,
    AgilityWeight = 0.3,
    BaseSpeed = 0.75,
    ShieldWeightPenalty = 0.005,
    MaxShieldWeightSlow = 0.5,
}

--- Determine how fast the block animation should play, based on a combinatino of luck, agility, and randomness.
--- The modifier is also multiplied by normalized fatigue, so more tired characters will block more slowly.
---@return number blockSpeed the speed at which the blocking animation should play.
local function getBlockSpeed()
    local normalizedAgility = math.min(Agility.modified, 100) / 100.0
    local normalizedLuck = math.min(Luck.modified, 100) / 100.0

    local randomFactor = (math.random(5) - 5) / 100.0

    local speedModifier = (normalizedLuck * blockSpeedConfig.LuckWeight)
        + (normalizedAgility * blockSpeedConfig.AgilityWeight)
        + randomFactor

    local shield = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedLeft)
    local shieldWeight = shield and types.Armor.records[shield.recordId].weight or 0
    local weightPenalty = math.min(
        shieldWeight * blockSpeedConfig.ShieldWeightPenalty,
        blockSpeedConfig.MaxShieldWeightSlow
    )

    return (blockSpeedConfig.BaseSpeed - weightPenalty)
        + speedModifier * normalizedFatigue()
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
}

local idleAnimData = {
    startKey = 'loop start',
    stopKey = 'loop stop',
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
    },
}

local function playBlockAnimation()
    blockAnimData.speed = getBlockSpeed()
    I.AnimationController.playBlendedAnimation(BLOCK_ANIM, blockAnimData)
end

local function playIdleAnimation()
    I.AnimationController.playBlendedAnimation('idle1', idleAnimData)
end

local function timedBlockHandler(group, key)
    if key == 'half' then
        I.s3ChimParry.Manager.start()
    end
end

I.AnimationController.addTextKeyHandler(BLOCK_ANIM, timedBlockHandler)

local function toggleBlock(enable)
    if isBlocking() == enable then return end

    (enable and playBlockAnimation or playIdleAnimation)()
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

    ActiveEffects:modify(SanctuaryStrength, core.magic.EFFECT_TYPE.Sanctuary)
    hasIFrames = true

    stopFns["iframes"] = time.runRepeatedly(function()
        if anim.getCompletion(self, currentLegs) then
            async:newUnsavableSimulationTimer(IFramesDuration, function()
                if not stopFns["iframes"] then return end

                if hasIFrames then
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

    local shouldInterrupt = isAttacking()
        or isJumping()
        or I.UI.getMode()
        or not inWeaponStance()

    if not shouldInterrupt then return end

    toggleBlock(false)
end

--- Also consider implementing iFrames. The current mechanic appears to be designed so as to give you a shitton of sanctuary effect
--- until the hit animation finishes.
return {
    interfaceName = 's3ChimBlock',
    interface = {
        canBlock = canBlock,
        getBlockSpeed = getBlockSpeed,
        handleBlockHit = handleBlockHit,
        isBlocking = isBlocking,
        playBlockSound = playBlockSound,
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
        end,
    }
}
