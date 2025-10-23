local anim = require 'openmw.animation'
local core = require 'openmw.core'
local input = require 'openmw.input'
local types = require 'openmw.types'
local util = require 'openmw.util'

local BLOCK_ANIM = 'activeblock'
local HUGE = math.huge

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local BlockButton = 3

local weaponTypes = types.Weapon.TYPE
local oneHandedTypes = {
    [weaponTypes.AxeOneHand] = true,
    [weaponTypes.ShortBladeOneHand] = true,
    [weaponTypes.LongBladeOneHand] = true,
    [weaponTypes.BluntOneHand] = true,
}

--- Checks if the actor is currently playing any one-handed attack animation.
--- Slightly weak, since we're not accounting for the possibility of empty or two-handed blocks
--- but since we have no relevant animations it probably doesn't matter at the moment.
local function isAttacking()
    return s3lf.getActiveGroup(anim.BONE_GROUP.RightArm):find('weapon') ~= nil
        or input.getBooleanActionValue('Use')
end

local function isJumping()
    return s3lf.getActiveGroup(anim.BONE_GROUP.LowerBody):find('jump') ~= nil
end

local function inWeaponStance()
    return s3lf.getStance() == types.Actor.STANCE.Weapon
end

local function normalizedFatigue()
    return util.clamp(s3lf.fatigue.current / s3lf.fatigue.base, 0.0, 1.0)
end

local function normalizedEncumbrance()
    return s3lf.getEncumbrance() / s3lf.getCapacity()
end

local function blockIsPressed()
    return input.isMouseButtonPressed(BlockButton)
end

local function playingHitstun()
    return s3lf.isPlaying('hitstun')
end

local blockHitLegsData = {
    priority = {
        [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Scripted,
    },
    blendMask = anim.BLEND_MASK.LowerBody
}

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

local groupName = 'SettingsGlobal' .. modInfo.name .. 'Block'
---@type ProtectedTableInterface
local ProtectedTable = I.S3ProtectedTable

--- CHIM System for handling block activation, animation, and damage mitigation
---@class BlockManager: ProtectedTable
---@field BaseBlockMitigation number
---@field SkillMitigationFactor number
---@field AttributeMitigationFactor number
---@field MinimumMitigation number
---@field MaximumMitigation number
---@field MaxArmorBonus number
---@field MaxWeightBonus number
---@field BlockSpeedLuckWeight number
---@field BlockSpeedAgilityWeight number
---@field ShieldWeightPenalty number
---@field ShieldWeightPenaltyLimit number
---@field BlockSpeedBase number
---@field StandingStillBonus number
local Block = ProtectedTable.new {
    inputGroupName = groupName,
    logPrefix = '[CHIMBlock]:\n',
}

function Block.getRandomHitGroup()
    local formatString, range

    if s3lf.isSwimming() then
        formatString, range = 'swimhit%d', 3
    else
        formatString, range = 'hit%d', 5
    end

    return formatString:format(math.random(1, range))
end

function Block.playBlockAnimation()
    blockAnimData.speed = Block.getSpeed()
    I.AnimationController.playBlendedAnimation(BLOCK_ANIM, blockAnimData)
end

function Block.playIdleAnimation()
    I.AnimationController.playBlendedAnimation('idle1', idleAnimData)
end

function Block.playBlockHitLegs()
    local randomGroup = Block.getRandomHitGroup()
    if s3lf.getActiveGroup(anim.BONE_GROUP.LowerBody) == randomGroup then return end
    I.AnimationController.playBlendedAnimation(randomGroup, blockHitLegsData)
end

function Block.isBlocking()
    return s3lf.getActiveGroup(anim.BONE_GROUP.LeftArm) == BLOCK_ANIM
end

function Block.getShieldAttribute(shield)
    local shieldType = I.Combat.getArmorSkill(shield)
    local shieldAttribute = core.stats.Skill.records[shieldType].attribute
    return s3lf[shieldAttribute].modified
end

function Block.usingOneHanded()
    local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then return false end

    local weaponRecord = types.Weapon.records[weapon.recordId]
    if not weaponRecord then return false end

    return oneHandedTypes[weaponRecord.type]
end

function Block.usingShield()
    local carriedLeft = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    if not carriedLeft then return false end

    local shieldRecord = types.Armor.records[carriedLeft.recordId]
    if not shieldRecord then return false end

    return true
end

local blockSounds = {
    lightarmor = 'light armor hit',
    mediumarmor = 'medium armor hit',
    heavyarmor = 'heavy armor hit',
}

function Block.playBlockSound()
    local shield = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    local shieldRecord = types.Armor.records[shield.recordId]
    if not shieldRecord then return end

    local shieldSkill = I.Combat.getArmorSkill(shield)
    core.sound.playSound3d(blockSounds[shieldSkill], s3lf.object)
end

function Block.getShieldBaseEffectiveness(armor, weight)
    local armorComponent = util.remap(armor, 0, 75, 0.1, Block.MaxArmorBonus)
    local weightComponent = util.remap(weight, 0, 50, 0.05, Block.MaxWeightBonus)
    return armorComponent + weightComponent
end

---@return number damageMitigation Multiplier on damage based on shield skill, governing attribute, and shield quality
function Block.calculateMitigation()
    local shield = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    if not shield then return 0 end

    local shieldRecord = types.Armor.records[shield.recordId]
    if not shieldRecord then return 0 end

    local shieldArmor = shieldRecord.baseArmor
    local shieldWeight = shieldRecord.weight

    -- Base mitigation from shield quality
    local baseMitigation = Block.getShieldBaseEffectiveness(shieldArmor, shieldWeight)

    -- Skill contribution (more skilled = better at angling shield)
    local skillMultiplier = 0.5 + (s3lf.block.base * Block.SkillMitigationFactor)

    local attributeBonus = Block.getShieldAttribute(shield) * Block.AttributeMitigationFactor

    local totalMitigation = baseMitigation * skillMultiplier * normalizedFatigue()
        + (attributeBonus + Block.BaseBlockMitigation)

    if s3lf.controls.movement == 0 and s3lf.controls.sideMovement == 0 then
        totalMitigation = totalMitigation * Block.StandingStillBonus
    end

    -- Clamp to reasonable bounds
    totalMitigation = util.clamp(
        totalMitigation,
        Block.MinimumMitigation,
        Block.MaximumMitigation
    )

    Block.debugLog(
        ([[Normalized fatigue: %.5f
            Total Mitigation: %.5f
            Base Mitigation: %.5f
            Armor Rating: %d
            Block Skill Multiplier: %.5f
            Attribute Bonus: %.5f
            Standing Still Bonus: %.2f]])
        :format(
            normalizedFatigue(),
            totalMitigation,
            baseMitigation,
            shieldArmor,
            skillMultiplier,
            attributeBonus,
            Block.StandingStillBonus
        )
    )

    return (1.0 - totalMitigation)
end

---@param weapon GameObject
---@param attackStrength number
function Block.consumeFatigue(weapon, attackStrength)
    local fatigueLoss = I.s3ChimDynamic.Manager.FatigueBlockBase
        + normalizedEncumbrance() * I.s3ChimDynamic.Manager.FatigueBlockMult
    if weapon then
        local weaponWeight = weapon.type.records[weapon.recordId].weight
        fatigueLoss = fatigueLoss
            + (weaponWeight * attackStrength * I.s3ChimDynamic.Manager.WeaponFatigueBlockMult)
    end

    s3lf.fatigue.current = s3lf.fatigue.current - fatigueLoss
end

---@class CHIMBlockResult
---@field damageMult number

---@param blockData CHIMBlockData
---@return CHIMBlockResult
function Block.handleHit(blockData)
    Block.playBlockSound()
    Block.playBlockHitLegs()
    Block.consumeFatigue(blockData.weapon, blockData.attackStrength)
    I.SkillProgression.skillUsed(core.stats.Skill.records.Block.id,
        {
            skillGain = 2.5, -- From testing successful blocks in-game, this seems to be the value used
            useType = I.SkillProgression.SKILL_USE_TYPES.Block_Success,

        })
    local damageMitigation = Block.calculateMitigation()

    -- Parries do not consume durability
    if blockData.applyDurabilityDamage then
        -- From the OpenMW Wiki:
        -- if a hit is blocked, the shield durability is reduced by incoming damage, no damage mitigation is applied
        -- (We apply mtigation)
        core.sendGlobalEvent('ModifyItemCondition', {
            actor = s3lf.object,
            item = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft),
            amount = -(blockData.damage * damageMitigation),
        })
    end

    if blockData.playVfx and blockData.hitPos then
        core.sendGlobalEvent('SpawnVfx', {
            position = blockData.hitPos,
            model = 'meshes/e/impact/parryspark.nif'
        })
    end

    return {
        damageMult = damageMitigation,
    }
end

function Block.canBlock()
    return
        inWeaponStance()
        and s3lf.isOnGround()
        and Block.usingOneHanded()
        and Block.usingShield()
        and not Block.isBlocking()
        and not I.UI.getMode()
        and not I.s3ChimPoise.isBroken()
        and not playingHitstun()
        and not isAttacking()
        and not isJumping()
end

--- Determine how fast the block animation should play, based on a combinatino of luck, agility, and randomness.
--- The modifier is also multiplied by normalized fatigue, so more tired characters will block more slowly.
---@return number blockSpeed the speed at which the blocking animation should play.
function Block.getSpeed()
    local normalizedAgility = math.min(s3lf.agility.modified, 100) / 100.0
    local normalizedLuck = math.min(s3lf.luck.modified, 100) / 100.0

    local randomFactor = (math.random(5) - 5) / 100.0

    local speedModifier = (normalizedLuck * Block.BlockSpeedLuckWeight)
        + (normalizedAgility * Block.BlockSpeedAgilityWeight)
        + randomFactor

    local shield = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    local shieldWeight = shield and types.Armor.records[shield.recordId].weight or 0
    local weightPenalty = math.min(
        shieldWeight * Block.ShieldWeightPenalty,
        Block.ShieldWeightPenaltyLimit
    )

    return (Block.BlockSpeedBase - weightPenalty)
        + speedModifier * normalizedFatigue()
end

local function timedBlockHandler(group, key)
    if key == 'half' then
        I.s3ChimParry.Manager.start()
    end
end

I.AnimationController.addTextKeyHandler(BLOCK_ANIM, timedBlockHandler)

function Block.toggleBlock(enable)
    if Block.isBlocking() == enable then return end

    Block[(enable and 'playBlockAnimation' or 'playIdleAnimation')]()
end

local function blockBegin(button)
    if I.UI.getMode() or button ~= BlockButton or not Block.canBlock() then return end
    Block.toggleBlock(true)
end

local function blockEnd(button)
    if button ~= BlockButton or not Block.isBlocking() then return end
    Block.toggleBlock(false)
end

local function ensureNoBlock()
    if s3lf.block.modifier == -HUGE then return end
    s3lf.block.modifier = -HUGE
end

local function noBlockInMenus()
    if not I.UI.getMode() then return end
    Block.toggleBlock(false)
    return true
end

--- Restore the block if it was interrupted by something else
local function blockIfPossible()
    if not blockIsPressed() or not Block.canBlock() then return end
    Block.toggleBlock(true)
end

local function interruptBlock()
    if not Block.isBlocking() then return end

    local shouldInterrupt = isAttacking()
        or isJumping()
        or I.UI.getMode()
        or not inWeaponStance()
        or I.s3ChimPoise.isBroken()

    if not shouldInterrupt then return end

    Block.toggleBlock(false)
end

local keyHanders = {
    blockSpeed = function()
        return Block.getSpeed()
    end,
    canBlock = function()
        return Block.canBlock()
    end,
    help = function()
        return
        [[The block interface exposes functions related to damage mitigation, animation speed and playback,  and parry handling.
        To reach into all exposed functions, use the `Manager` field. Shorthand functions available directly through the interface include:
        blockSpeed, canBlock, help, isBlocking, mitigation, playBlock, playBlockHitLegs, playIdle, usingOneHanded, and usingShield.]]
    end,
    isBlocking = function()
        return Block.isBlocking()
    end,
    mitigation = function()
        return Block.calculateMitigation()
    end,
    playBlock = function()
        Block.playBlockAnimation()
        return ''
    end,
    playBlockHitLegs = function()
        Block.playBlockHitLegs()
        return ''
    end,
    playIdle = function()
        Block.playIdleAnimation()
        return ''
    end,
    usingOneHanded = function()
        return Block.usingOneHanded()
    end,
    usingShield = function()
        return Block.usingShield()
    end,
}

--- Also consider implementing iFrames. The current mechanic appears to be designed so as to give you a shitton of sanctuary effect
--- until the hit animation finishes.
return {
    interfaceName = 's3ChimBlock',
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                if keyHanders[key] then
                    assert(type(keyHanders[key]) == 'function')
                    return keyHanders[key]()
                elseif key == 'Manager' then
                    return Block
                end
            end,
        }
    ),
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
