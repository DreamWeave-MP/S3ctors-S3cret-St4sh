local anim = require 'openmw.animation'
local async = require 'openmw.async'
local core = require 'openmw.core'
local input
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local util = require 'openmw.util'

--- We also need to make sure we early-out of the entire script for creatures which are not bipedal
local HUGE = math.huge

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)
if isPlayer then
    input = require 'openmw.input'
end

local attackGroups = {
    ['weapontwohand'] = true,
    ['weapontwowide'] = true,
    ['weapononehand'] = true,
    ['crossbow'] = true,
    ['bowandarrow'] = true,
    ['throwweapon'] = true,
}

local attackSignalKeys = {
    --- Attack Start Keys
    ['chop start'] = true,
    ['shoot start'] = true,
    ['slash start'] = true,
    ['thrust start'] = true,

    --- Min Hit Keys
    -- ['slash min hit'] = true,
    -- ['thrust min hit'] = true,
    -- ['chop min hit'] = true,
    -- ['shoot min hit'] = true,

    --- Min Attack Keys
    ['slash min attack'] = true,
    ['thrust min attack'] = true,
    ['chop min attack'] = true,
    ['shoot min attack'] = true,
}

--- Checks if the actor is currently playing any one-handed attack animation.
--- Slightly weak, since we're not accounting for the possibility of empty or two-handed blocks
--- but since we have no relevant animations it probably doesn't matter at the moment.
local function isAttacking()
    local attackPlaying = s3lf.getActiveGroup(anim.BONE_GROUP.RightArm):find('weapon') ~= nil

    if isPlayer then
        attackPlaying = attackPlaying or input.getBooleanActionValue('Use')
    end

    return attackPlaying
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
    if isPlayer then
        return input.getBooleanActionValue('CHIMBlockAction')
    else
        -- Maybe we should... throw here or something?
        return false
    end
end

local function playingHitstun()
    local activeLegs = s3lf.getActiveGroup(anim.BONE_GROUP.LowerBody)

    return activeLegs ~= 'knockdown'
        and activeLegs ~= 'knockout'
        and activeLegs:match('^hit') ~= nil
end

---@param vec1 util.vector3
---@param vec2 util.vector3
---@param normal util.vector3
local function signedAngleRadians(vec1, vec2, normal)
    return math.atan2(
        normal * (vec1 ^ vec2),
        vec1 * vec2
    )
end

local blockHitLegsData = {
    priority = {
        [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Scripted,
    },
    blendMask = anim.BLEND_MASK.LowerBody
}

local shieldBlockData = {
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
    },
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
---@field BlockLeftAngle number
---@field BlockRightAngle number
local Block = ProtectedTable.new {
    inputGroupName = groupName,
    logPrefix = '[CHIMBlock]:\n',
}
Block.state = {
    blockingItem = nil,
    isBlocking = nil,
    isParrying = false,
}

---@class AIBlockManager: ProtectedTable
---@field NoBlockThreshold number
---@field FatigueLossPercent number
---@field BaseMaxBlockCount integer
---@field BaseBlockTime number
---@field ActorFatigueBlockTime number
---@field ActorMinBlockTime number
---@field ActorMaxBlockTime number
---@field ActorEnduranceBlockTime number
---@field ActorSkillBlockTime number
local BlockActor = ProtectedTable.new {
    inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'BlockActor',
    logPrefix = '[CHIMAI]:\n',
}
BlockActor.state = {
    blockTimer = 0.0,
    doTurtle = false,
    repeatedBlocks = 0,
}

function BlockActor:tick(dt)
    if isPlayer or self.state.blockTimer <= 0 then return end

    self.state.blockTimer = math.max(0.0, self.state.blockTimer - dt)

    if self.state.blockTimer ~= 0 then
        if self.state.doTurtle then
            s3lf.controls.movement = 0
            s3lf.controls.sideMovement = 0
        end

        if not Block.isBlocking() then
            Block.toggleBlock(true)
        end

        return
    end

    Block.toggleBlock(false)
end

function BlockActor:blockTimer()
    if isPlayer then return end

    local block, endurance = math.min(100, s3lf.block.base) / 100, math.min(100, s3lf.endurance.modified) / 100

    -- Skill reduces block time (faster recovery)
    local skillBonus = block * self.ActorSkillBlockTime

    -- Endurance helps with stamina recovery for longer blocks
    local enduranceBonus = endurance * self.ActorEnduranceBlockTime

    -- Fatigue penalty - tired characters can't maintain blocks long
    local fatiguePenalty = (1 - normalizedFatigue()) * self.ActorFatigueBlockTime

    local totalTime = self.BaseBlockTime
        + skillBonus
        + enduranceBonus
        - fatiguePenalty

    return util.clamp(totalTime, self.ActorMinBlockTime, self.ActorMaxBlockTime)
end

function BlockActor:getMaxConsecutiveBlocks()
    if isPlayer then return end
    return self.BaseMaxBlockCount + util.round((s3lf.block.base * 0.02) + (s3lf.endurance.modified * 0.01))
end

function BlockActor:resetBlockTimer()
    if isPlayer then return end
    self.state.blockTimer = self:blockTimer()
end

function BlockActor:reset()
    if isPlayer then return end
    self.state.blockTimer = 0.0
    self.state.doTurtle = false
    self.state.repeatedBlocks = 0
end

---@return boolean? interruptBlock
function BlockActor:AIBlockResponse()
    if isPlayer then return end
    local normalizedHealth = s3lf.health.current / s3lf.health.base

    if normalizedHealth < 0.1 or not self:hasBlockFatigue() then
        return true
    end

    local roll = math.random(100)
    local skillBonus = math.min(100, s3lf.block.base * 0.5)
    local result = roll + skillBonus

    if result >= 120 then
        if self.state.repeatedBlocks >= self:getMaxConsecutiveBlocks() then
            return
        end

        self.state.repeatedBlocks = self.state.repeatedBlocks + 1
        self:resetBlockTimer()
    else
        self.state.repeatedBlocks = 0

        if result < 60 then
            return true
        end
    end
end

function BlockActor:shouldTurtle()
    if isPlayer then return end
    local encumbrance = I.s3ChimCore.getEquipmentEncumbrance()

    -- Base chance increases with encumbrance (heavy armor = more turtling)
    local baseChance = util.remap(encumbrance, 0, 1, 0.2, 0.8)

    -- Block skill makes turtling more strategic (skilled blockers turtle smarter)
    local skillBonus = (s3lf.block.base / 100) * 0.2

    -- Low stamina discourages turtling (can't maintain it)
    local staminaPenalty = (1 - normalizedFatigue()) * 0.3

    -- Health situation affects willingness to turtle
    local healthRatio = s3lf.health.current / s3lf.health.base
    local healthModifier = healthRatio < 0.7 and 0.1 or -0.2

    local finalChance = baseChance
        + skillBonus
        + healthModifier
        - staminaPenalty

    return math.random() < util.clamp(finalChance, 0.1, 0.9)
end

function BlockActor:hasBlockFatigue()
    if isPlayer then return true end
    return normalizedFatigue() >= self.NoBlockThreshold
end

function BlockActor:shouldAttemptBlock()
    if not self:hasBlockFatigue() or math.random() <= 0.05 then return false end

    -- Base random chance - 50/50 most of the time
    local baseChance = 0.5

    local encumbranceBonus = I.s3ChimCore.getEquipmentEncumbrance() * 0.3

    local healthPenalty = (1 - (s3lf.health.current / s3lf.health.base)) * 0.2 -- Low health = -20%

    local finalChance = baseChance + encumbranceBonus - healthPenalty

    return math.random() < util.clamp(finalChance, 0.2, 0.8)
end

---@param enable boolean
function Block.playBlockAnimation(enable)
    local blockAnim
    local usingShield = Block.usingShield()

    local autoDisable, startKey, stopKey
    if enable then
        startKey = 'block start'
        stopKey = 'block stop'
        autoDisable = false
        blockAnim = Block.getBlockType()

        local equipmentSlot = (usingShield and s3lf.EQUIPMENT_SLOT.CarriedLeft or s3lf.EQUIPMENT_SLOT.CarriedRight)
        Block.state.blockingItem = s3lf.getEquipment(equipmentSlot)
    else
        startKey = 'release start'
        stopKey = 'release stop'
        autoDisable = true

        blockAnim = Block.getBlockType(Block.state.blockingItem)
        Block.state.blockingItem = nil

        s3lf.cancel(blockAnim)
    end

    if not usingShield then
        shieldBlockData.priority[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted
        shieldBlockData.blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.RightArm
    else
        shieldBlockData.priority[anim.BONE_GROUP.RightArm] = nil
        shieldBlockData.blendMask = anim.BLEND_MASK.LeftArm
    end

    shieldBlockData.startKey = startKey
    shieldBlockData.stopKey = stopKey
    shieldBlockData.autoDisable = autoDisable

    shieldBlockData.speed = Block.getSpeed()
    I.AnimationController.playBlendedAnimation(blockAnim, shieldBlockData)
end

function Block.playIdleAnimation()
    if not Block.isBlocking() then return end
    I.AnimationController.playBlendedAnimation('idle1', idleAnimData)
end

function Block.playBlockHitLegs()
    local randomGroup = I.s3ChimCore.getRandomHitGroup()
    if s3lf.getActiveGroup(anim.BONE_GROUP.LowerBody) == randomGroup then return end
    I.AnimationController.playBlendedAnimation(randomGroup, blockHitLegsData)
end

function Block.isBlocking()
    return Block.state.isBlocking
end

function Block.getShieldAttribute(shield)
    local shieldType

    if types.Armor.objectIsInstance(shield) then
        shieldType = I.Combat.getArmorSkill(shield)
    elseif types.Weapon.objectIsInstance(shield) then
        shieldType = I.s3ChimCore.getWeaponSkillName(shield)
    else
        error('getShieldAttribute passed invalid object type: ' .. shield)
    end

    local shieldAttribute = core.stats.Skill.records[shieldType].attribute
    return s3lf[shieldAttribute].modified
end

function Block.usingOneHanded()
    local Core = I.s3ChimCore

    return Core.getWeaponHandedness() == Core.Handedness.ONE
end

function Block.usingShield()
    if I.s3ChimCore.getWeaponHandedness() ~= I.s3ChimCore.Handedness.ONE then return false end

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
    blunt = 'heavy armor hit',
    longblade = 'medium armor hit',
    shortblade = 'medium armor hit',
    spear = 'heavy armor hit'
}

function Block.playBlockSound()
    local blockingItem, blockSkill = Block.getBlockingItem()

    if
        I.s3ChimCore.getWeaponHandedness() == I.s3ChimCore.Handedness.ONE
        and Block.usingShield()
    then
        blockSkill = I.Combat.getArmorSkill(blockingItem)
    else
        blockSkill = I.s3ChimCore.getWeaponSkillName(blockingItem)
    end

    core.sound.playSound3d(blockSounds[blockSkill], s3lf.object)
end

function Block.getShieldBaseEffectiveness(armor, weight)
    local armorComponent = util.remap(armor, 0, 75, 0.1, Block.MaxArmorBonus)
    local weightComponent = util.remap(weight, 0, 50, 0.05, Block.MaxWeightBonus)
    return armorComponent + weightComponent
end

--- When calculating mitigation for weapons, they don't have an armor value, so we double the max weight bonus
function Block.getWeaponBaseEffectiveness(weight)
    return util.remap(weight, 0, 60, 0.3, Block.MaxWeightBonus * 2)
end

---@return number damageMitigation Multiplier on damage based on shield skill, governing attribute, and shield quality
function Block.calculateMitigation()
    local shield = Block.getBlockingItem()
    if not shield then return 0 end

    local shieldRecord = shield.type.records[shield.recordId]
    local shieldArmor = shieldRecord.baseArmor or 0
    local shieldWeight = shieldRecord.weight

    -- Base mitigation from shield quality
    local baseMitigation
    if types.Weapon.objectIsInstance(shield) then
        baseMitigation = Block.getWeaponBaseEffectiveness(shieldWeight)
    else
        baseMitigation = Block.getShieldBaseEffectiveness(shieldArmor, shieldWeight)
    end

    -- Skill contribution (more skilled = better at angling shield)
    local blockSkill
    if types.NPC.objectIsInstance(s3lf.gameObject) then
        blockSkill = s3lf.block.base
    else
        blockSkill = s3lf.combatSkill
    end

    local skillMultiplier = 0.5 + (blockSkill * Block.SkillMitigationFactor)

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
    local Dynamic = I.s3ChimDynamic.Manager

    local fatigueLoss = Dynamic.FatigueBlockBase + normalizedEncumbrance() * Dynamic.FatigueBlockMult

    if weapon then
        local weaponWeight = weapon.type.records[weapon.recordId].weight
        fatigueLoss = fatigueLoss + (weaponWeight * attackStrength * Dynamic.WeaponFatigueBlockMult)
    end

    if not isPlayer then
        fatigueLoss = fatigueLoss * BlockActor.FatigueLossPercent
    end

    s3lf.fatigue.current = s3lf.fatigue.current - fatigueLoss
end

local Forward, Up = util.vector3(0, 1, 0), util.vector3(0, 0, 1)
--- Replicates Morrowind's internal blocking formula in lua
--- Returns whether or not the target can block their opponent based on their respective orientations
---@param attacker GameObject
---@param defender GameObject
---@return boolean canBlock, number closenessToBack Number between 0 and 1, representing how close the attacker is to the defender's back, with 1 meaning directly behind.
function Block.canBlockAtAngle(attacker, defender)
    if types.Creature.objectIsInstance(defender) then
        local isBiped
        if defender.From then -- the presence or lack of a .From field indicates a s3lfObject
            isBiped = defender.isBiped
        else
            isBiped = defender.type.records[defender.recordId].isBiped
        end

        if not isBiped then return false, 0.0 end
    end

    local diffVec = attacker.position - defender.position
    local blockerForward = defender.rotation * Forward
    local radianDiff = signedAngleRadians(diffVec, blockerForward, Up)
    local degreeDiff = math.deg(radianDiff)

    Block.debugLog('Angle Diff on Block:', degreeDiff, 'Attacker:', attacker.recordId, 'Defender:', defender.recordId)

    local normalizedDegreeDiff = util.clamp(math.abs(degreeDiff), 0, 180)
    normalizedDegreeDiff = util.remap(normalizedDegreeDiff, 0, 180, 0.0, 1.0)

    return degreeDiff > Block.BlockLeftAngle and degreeDiff < Block.BlockRightAngle, normalizedDegreeDiff
end

---@class CHIMBlockResult
---@field damageMult number

---@param blockData CHIMBlockData
---@return CHIMBlockResult
function Block.handleHit(blockData)
    Block.playBlockSound()
    Block.playBlockHitLegs()
    Block.consumeFatigue(blockData.weapon, blockData.attackStrength)

    if isPlayer then
        I.SkillProgression.skillUsed(core.stats.Skill.records.Block.id,
            {
                -- From testing successful blocks in-game, 2.5 seems to be the value used, but it's way too damn high
                skillGain = .33333,
                useType = I.SkillProgression.SKILL_USE_TYPES.Block_Success,

            })
    end

    local damageMitigation = Block.calculateMitigation()

    -- Parries do not consume durability
    if blockData.applyDurabilityDamage then
        -- From the OpenMW Wiki:
        -- if a hit is blocked, the shield durability is reduced by incoming damage, no damage mitigation is applied
        -- (We apply mtigation)
        core.sendGlobalEvent('ModifyItemCondition', {
            actor = s3lf.object,
            item = Block.getBlockingItem(),
            amount = -(blockData.damage * damageMitigation),
        })
    end

    if blockData.hitPos then
        core.sendGlobalEvent('SpawnVfx', {
            position = blockData.hitPos,
            model = 'meshes/e/impact/parryspark.nif'
        })
    end

    if BlockActor:AIBlockResponse() then
        Block.toggleBlock(false)
        Block.debugLog('Interrupted block', s3lf.recordId)
    end

    return {
        damageMult = damageMitigation,
    }
end

local function hasBlockingWeapon()
    local Core = I.s3ChimCore
    local handedness = Core.getWeaponHandedness()
    return handedness == Core.Handedness.TWO or handedness == Core.Handedness.ONE
end

local function isParrying()
    return Block.state.isParrying
end

function Block.canBlock()
    local canBlock = inWeaponStance()
        and s3lf.isOnGround()
        and hasBlockingWeapon()
        and s3lf.canMove()
        and Block.getBlockingItem() ~= nil
        and not Block.isBlocking()
        and not I.s3ChimPoise.isBroken()
        and not playingHitstun()
        and not isJumping()
        and not isParrying()

    if isPlayer then
        canBlock = canBlock
            and not I.UI.getMode()
            and not isAttacking()
    end

    return canBlock
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

local function timedBlockHandler(_, key)
    if key == 'block start' then
        Block.state.isParrying = false
        Block.state.isBlocking = false
    elseif key == 'block stop' then
        Block.state.isBlocking = true
    elseif key == 'release start' then
        Block.state.isBlocking = false
    elseif key == 'parry start' then
        Block.state.isParrying = true
        Block.state.isBlocking = false
    elseif key == 'parry stop' then
        Block.state.isParrying = false
    elseif key == 'half' then
        I.s3ChimParry.Manager.start()
    end
end

for _, animGroup in ipairs { 'activeblockshield', 'activeblock1h', 'activeblock2h', } do
    I.AnimationController.addTextKeyHandler(animGroup, timedBlockHandler)
end

function Block.toggleBlock(enable)
    if Block.isBlocking() == enable then return end

    Block.playBlockAnimation(enable)

    if not enable then
        BlockActor:reset()
    end
end

---@param weapon GameObject?
function Block.getBlockType(weapon)
    if I.s3ChimCore.getWeaponHandedness(weapon) == I.s3ChimCore.Handedness.TWO then
        return 'activeblock2h'
    elseif Block.usingShield() then
        return 'activeblockshield'
    else
        return 'activeblock1h'
    end
end

function Block.getBlockingItem()
    local Core = I.s3ChimCore
    local handedness = Core.getWeaponHandedness()
    if handedness == Core.Handedness.THROWN or handedness == Core.Handedness.RANGED then return end

    local slot = Block.usingShield() and s3lf.EQUIPMENT_SLOT.CarriedLeft or s3lf.EQUIPMENT_SLOT.CarriedRight
    return s3lf.getEquipment(slot)
end

local function blockBegin()
    if
        (isPlayer and I.UI.getMode())
        or not Block.canBlock()
    then
        return
    end

    Block.toggleBlock(true)
end

local function blockEnd()
    if not Block.isBlocking() then return end
    Block.toggleBlock(false)
end

local function noBlockInMenus()
    if not isPlayer or not I.UI.getMode() then return end
    Block.toggleBlock(false)
    return true
end

--- Restore the block if it was interrupted by something else
local function blockIfPossible()
    local isBlocking = Block.isBlocking()
    if isBlocking then
        local blockType = Block.getBlockType(Block.state.blockingItem)
        local isActuallyBlocking = s3lf.getActiveGroup(anim.BONE_GROUP.LeftArm) == blockType

        if isBlocking and not isActuallyBlocking then
            Block.state.isBlocking = false
            return Block.toggleBlock(true)
        end
    end

    if
        not isPlayer
        or not blockIsPressed()
        or not Block.canBlock()
        or I.s3ChimRoll.isRolling()
    then
        return
    end

    Block.toggleBlock(true)
end

local function interruptBlock()
    if not Block.isBlocking() then return end

    local shouldInterrupt = isAttacking()
        or isJumping()
        or not inWeaponStance()
        or I.s3ChimPoise.isBroken()
        or (I.s3ChimRoll and I.s3ChimRoll.isRolling())

    if isPlayer then
        shouldInterrupt = shouldInterrupt
            or I.UI.getMode()
            or not blockIsPressed()
    end

    if not shouldInterrupt then return end

    Block.toggleBlock(false)
end

local keyHandlers = {
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
        Block.playBlockAnimation(true)
        return ''
    end,
    playBlockHitLegs = function()
        Block.playBlockHitLegs()
        return ''
    end,
    playIdle = function()
        Block.playBlockAnimation(false)
        return ''
    end,
    usingOneHanded = function()
        return Block.usingOneHanded()
    end,
    usingShield = function()
        return Block.usingShield()
    end,
}

local function handleBlockInput(state)
    (state and blockBegin or blockEnd)()
end

local function blockUpdate(dt)
    if noBlockInMenus() or s3lf.getStance() == s3lf.STANCE.Nothing then return end

    blockIfPossible()

    interruptBlock()
    BlockActor:tick(dt)
end

local function signalAttack()
    for _, actor in ipairs(nearby.actors) do
        if
            actor.type.isDead(actor)
            or actor.id == s3lf.id
            or types.Player.objectIsInstance(actor)
            or actor.type.getStance(actor) == s3lf.STANCE.Nothing
            or not Block.canBlockAtAngle(s3lf.gameObject, actor)
        then
            goto CONTINUE
        end

        actor:sendEvent('CHIMBlockSignal', s3lf.gameObject)
        ::CONTINUE::
    end
end

local function attackSignalHandler(group, key)
    if not attackSignalKeys[key] then return end

    Block.debugLog(('%s-%s emitting attack signal %s: %s'):format(s3lf.id, s3lf.recordId, group, key))
    signalAttack()
end

for attackGroup in pairs(attackGroups) do
    I.AnimationController.addTextKeyHandler(attackGroup, attackSignalHandler)
end

local engineHandlers, eventHandlers = {}, {}
if isPlayer then
    input.registerActionHandler('CHIMBlockAction', async:callback(handleBlockInput))
    engineHandlers.onFrame = blockUpdate
else
    engineHandlers.onUpdate = blockUpdate
    eventHandlers.CHIMBlockSignal = function(attacker)
        if not Block.canBlock() or not BlockActor:shouldAttemptBlock() then return end

        Block.toggleBlock(true)
        BlockActor:resetBlockTimer()
        BlockActor.state.doTurtle = BlockActor:shouldTurtle()
    end
end


--- Also consider implementing iFrames. The current mechanic appears to be designed so as to give you a shitton of sanctuary effect
--- until the hit animation finishes.
return {
    interfaceName = 's3ChimBlock',
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                local keyHandler = keyHandlers[key]
                local managerKey = Block[key]

                if keyHandler then
                    assert(type(keyHandler) == 'function')
                    return keyHandler()
                elseif managerKey then
                    return managerKey
                elseif key == 'Manager' then
                    return Block
                elseif key == 'Actor' and not isPlayer then
                    return BlockActor
                end
            end,
        }
    ),
    engineHandlers = engineHandlers,
    eventHandlers = eventHandlers,
}
