local anim = require 'openmw.animation'
local async = require 'openmw.async'
local core = require 'openmw.core'
local input
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local util = require 'openmw.util'

--- We also need to make sure we early-out of the entire script for creatures which are not bipedal
local BLOCK_ANIM = 'activeblock'
local HUGE = math.huge

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)
if isPlayer then
    input = require 'openmw.input'
end

local weaponTypes = types.Weapon.TYPE
local oneHandedTypes = {
    [weaponTypes.AxeOneHand] = true,
    [weaponTypes.ShortBladeOneHand] = true,
    [weaponTypes.LongBladeOneHand] = true,
    [weaponTypes.BluntOneHand] = true,
}

local attackGroups = {
    ['weapontwohand'] = true,
    ['weapontwowide'] = true,
    ['weapononehand'] = true,
    ['crossbow'] = true,
    ['bowandarrow'] = true,
    ['throwweapon'] = true,
}

local attackSignalKeys = {
    ['min hit'] = true,
    ['start'] = true,
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

local blockAnimData = {
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
---@field BlockLeftAngle number
---@field BlockRightAngle number
local Block = ProtectedTable.new {
    inputGroupName = groupName,
    logPrefix = '[CHIMBlock]:\n',
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

function Block.playBlockAnimation()
    if Block.isBlocking() then return end
    blockAnimData.speed = Block.getSpeed()
    I.AnimationController.playBlendedAnimation(BLOCK_ANIM, blockAnimData)
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
    local skillMultiplier
    if types.NPC.objectIsInstance(s3lf.gameObject) then
        skillMultiplier = 0.5 + (s3lf.block.base * Block.SkillMitigationFactor)
    else
        skillMultiplier = 0.5 + (s3lf.combatSkill * Block.SkillMitigationFactor)
    end

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
---@return boolean canBlock
function Block.canBlockAtAngle(attacker, defender)
    if types.Creature.objectIsInstance(defender) and not s3lf.From(defender).isBiped then return false end

    local diffVec = attacker.position - defender.position
    local blockerForward = defender.rotation * Forward
    local radianDiff = signedAngleRadians(diffVec, blockerForward, Up)
    local degreeDiff = math.deg(radianDiff)

    Block.debugLog('Angle Diff on Block:', degreeDiff, 'Attacker:', attacker.recordId, 'Defender:', defender.recordId)

    return degreeDiff > Block.BlockLeftAngle and degreeDiff < Block.BlockRightAngle
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

    if BlockActor:AIBlockResponse() then
        Block.toggleBlock(false)
        Block.debugLog('Interrupted block', s3lf.recordId)
    end

    return {
        damageMult = damageMitigation,
    }
end

function Block.canBlock()
    local canBlock = inWeaponStance()
        and s3lf.isOnGround()
        and Block.usingOneHanded()
        and Block.usingShield()
        and s3lf.canMove()
        and not Block.isBlocking()
        and not I.s3ChimPoise.isBroken()
        and not playingHitstun()
        and not isJumping()

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

local function timedBlockHandler(group, key)
    if key == 'half' then
        I.s3ChimParry.Manager.start()
    end
end

I.AnimationController.addTextKeyHandler(BLOCK_ANIM, timedBlockHandler)

function Block.toggleBlock(enable)
    if Block.isBlocking() == enable then return end

    Block[(enable and 'playBlockAnimation' or 'playIdleAnimation')]()

    if not enable then
        BlockActor:reset()
    end
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

local function ensureNoBlock()
    if not types.NPC.objectIsInstance(s3lf.gameObject) then return end
    if s3lf.block.modifier == -HUGE then return end
    s3lf.block.modifier = -HUGE
end

local function noBlockInMenus()
    if not isPlayer or not I.UI.getMode() then return end
    Block.toggleBlock(false)
    return true
end

--- Restore the block if it was interrupted by something else
local function blockIfPossible()
    if
        (isPlayer and not blockIsPressed())
        or not isPlayer
        or not Block.canBlock()
    then
        return
    end

    Block.toggleBlock(true)
end

local function interruptBlock()
    if not Block.isBlocking() then return end

    local shouldInterrupt = isAttacking()
        or isJumping()
        or (isPlayer and I.UI.getMode())
        or I.s3ChimPoise.isBroken()
        or not inWeaponStance()
        or (isPlayer and not blockIsPressed())

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

local function handleBlockInput(state)
    (state and blockBegin or blockEnd)()
end

local function blockUpdate(dt)
    ensureNoBlock()
    if noBlockInMenus() then return end

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

--- Takes a string like "chop min attack" and returns everything after the first space -> "min attack"
local function removeFirstWord(string)
    local firstSpace = string:find(" ")

    if firstSpace then
        return string:sub(firstSpace + 1)
    end

    return string
end

I.AnimationController.addTextKeyHandler('',
    function(group, key)
        key = removeFirstWord(key)
        if not attackGroups[group] or not attackSignalKeys[key] then return end

        Block.debugLog(('%s-%s emitting attack signal %s: %s'):format(s3lf.id, s3lf.recordId, group, key))
        signalAttack()
    end
)

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

                if keyHandler then
                    assert(type(keyHandler) == 'function')
                    return keyHandler()
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
