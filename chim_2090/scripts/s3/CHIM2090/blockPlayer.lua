-- [[
-- Figure out blocks for other weapons
--]]

local anim = require('openmw.animation')
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')

local BLOCK_ANIM = 'activeblock'
local HUGE = 9999999

local I = require('openmw.interfaces')
local Controls = I.Controls

local BlockButton = 3
local BlockDelay = 0.
local MaxBlockDelay = 1.5

-- local BulletTimeDuration = 3.0
-- local BulletTimeScale

-- Store references to stop functions here so they can be self-referential
-- Mostly used to restore block after being hit, while holding Mouse 3
local stopFns = {}

-- #JustBlockThings
local isBlocking = false
local myAttributes = self.type.stats.attributes
local mySkills = self.type.stats.skills
local myDynamicStats = self.type.stats.dynamic
local myBlock = mySkills.block(self)

-- Extra frames to not take melee damage after blocking
-- This should maybe scale based on block skill?
-- or some value related to the shield itself, like weight and speed
local blockIsPressed = false
local hasIFrames = false
local IFramesDuration = 2 * time.second
local myEffects = self.type.activeEffects(self)
local SanctuaryStrength = 1000

-- Healing when hit during a block
local prevHealth = 0
local healthObj = self.type.stats.dynamic.health(self)

-- Values for timed block bonus
-- Right now it uses lightning shield but maybe could be better?
local hasTimedBonus = false
local CurrentParryDelay = 0.0
local MaxParryDelay = 6.0
local LightningShieldStrength = 0

local weaponTypes = types.Weapon.TYPE
local oneHandedTypes = {
    [weaponTypes.AxeOneHand] = true,
    [weaponTypes.ShortBladeOneHand] = true,
    [weaponTypes.LongBladeOneHand] = true,
    [weaponTypes.BluntOneHand] = true,
}

local function usingOneHanded()
    local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
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

local function inWeaponStance()
    return types.Actor.getStance(self) == types.Actor.STANCE.Weapon
end

local function getBlockingWeight()
    local equipment = self.type.getEquipment(self)
    local shield = equipment[self.type.EQUIPMENT_SLOT.CarriedLeft]
    local weapon = equipment[self.type.EQUIPMENT_SLOT.CarriedRight]

    local shieldWeight = shield and types.Armor.records[shield.recordId].weight or 0
    local weaponWeight = weapon and types.Weapon.records[weapon.recordId].weight or 0

    return shield and shieldWeight or weaponWeight
end

local function canBlock()
    -- local shield = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)

    return
    -- shield ~= nil
    -- and shield.type == types.Armor
    -- and
        inWeaponStance()
        and usingOneHanded()
        and usingShield()
        and isBlocking == false
        and I.UI.getMode() == nil
        and not anim.isPlaying(self, 'hitstun')
        and BlockDelay <= 0.
end

local function getBlockSpeed()
    -- local baseSpeed = 1
    -- local maxVariation = 0.25
    local agility = myAttributes.agility(self).modified
    local luck = myAttributes.luck(self).modified
    local fatigueObj = myDynamicStats.fatigue(self)

    local normalizedAgility = math.min(agility, 100) / 100.0
    local normalizedLuck = math.min(luck, 100) / 100.0

    local randomFactor = math.random(15) / 100.0

    -- if math.random(2) == 1 then randomFactor = -randomFactor end

    -- Combine random factor with agility influence
    local speedModifier = (normalizedLuck * .15) + (normalizedAgility * .3) + randomFactor
    -- local speedModifier = randomFactor * (1 - normalizedAgility)
    -- + normalizedAgility * 0.5

    -- Apply the modifier within our desired range
    -- local finalSpeed = baseSpeed * speedModifier
    -- local finalSpeed = baseSpeed + (speedModifier * maxVariation)

    -- Normalize fatigue (0 = exhausted, 1 = full fatigue)
    local normalizedFatigue = fatigueObj.current / fatigueObj.base

    -- Apply inverse fatigue influence (lower fatigue = faster animation)
    -- local fatigueMultiplier = 2 - normalizedFatigue -- This will range from 1 (full fatigue) to 2 (no fatigue)
    local finalSpeed = 1 + speedModifier * normalizedFatigue

    -- ui.showMessage("Final speed: " .. finalSpeed
    --                .. " speed modifier: " .. speedModifier
    --                .. " normalized agility: " .. normalizedAgility
    --                .. " random factor: " .. randomFactor)

    return finalSpeed
end

local function playBlockAnimation()
    I.AnimationController.playBlendedAnimation(BLOCK_ANIM, {
        startKey = 'start',
        stopKey = 'stop',
        priority = {
            -- [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Default,
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
            [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
            -- [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Default,
        },
        autoDisable = false,
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
        speed = getBlockSpeed(),
    })
end

local function playIdleAnimation()
    I.AnimationController.playBlendedAnimation('idle1',
        {
            startKey = 'loop start',
            stopKey = 'loop stop',
            -- priority = anim.PRIORITY.Scripted,
            priority = {
                -- [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Default,
                [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
                [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
                -- [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Default,
            },
            autoDisable = true,
        })
end

local function disableTimedBlockBonus()
    if not hasTimedBonus then return end

    myEffects:modify(-LightningShieldStrength, core.magic.EFFECT_TYPE.LightningShield)
    print('Updated lightning shield value:', myEffects:getEffect(core.magic.EFFECT_TYPE.LightningShield).magnitude)
    -- ui.showMessage("Removing lightning shield")
    hasTimedBonus = false
end

local function updateTimedBlockDamage()
    local strength = myAttributes.strength(self).modified
    local itemWeight = getBlockingWeight()

    -- Base damage calculation
    local baseDamage = (myBlock.base * 0.2) + (strength * 0.1) + (itemWeight * .1)

    -- ui.showMessage("Base damage before flattening: " .. baseDamage)

    -- The shield does 10% magnitude as damage, so multiply intended damage by 10
    LightningShieldStrength = math.min(baseDamage, 50) * 10
end

local function applyTimedBlockBonus()
    -- if CurrentParryDelay > 0. then return end

    updateTimedBlockDamage()

    myEffects:modify(LightningShieldStrength, core.magic.EFFECT_TYPE.LightningShield)
    print('Updated lightning shield value:', LightningShieldStrength)

    -- ui.showMessage("Adding lightning shield")

    hasTimedBonus = true
end

local function timedBlockHandler(_, key)
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
    if isBlocking == enable then return end

    myBlock.modifier = myBlock.modifier + (enable and HUGE or -HUGE)
    isBlocking = enable
    Controls.overrideCombatControls(enable)

    if enable then
        -- I'm not sure if I liked the idea of applying the bonus
        -- before the stop key, or after
        -- So we'll preserve this code just in case!
        -- applyTimedBlockBonus()
        playBlockAnimation()
    else
        disableTimedBlockBonus()
        playIdleAnimation()
    end
end

local function blockBegin(button)
    if I.UI.getMode() then return end

    if button == BlockButton and canBlock() then
        toggleBlock(true)
    end
end

local function blockEnd(button)
    -- if I.UI.getMode() then return end

    if button == BlockButton and isBlocking then
        toggleBlock(false)
    end
end

local function updateMouse()
    blockIsPressed = input.isMouseButtonPressed(BlockButton)
    -- print(blockIsPressed)
end

local function blockIfPossible()
    -- Restore the block if it was interrupted by something else
    if blockIsPressed and canBlock() then
        toggleBlock(true)
    end
end

local function beginIFrames(currentLegs)
    if stopFns["iframes"] then return end

    ui.showMessage('Adding iFrames')
    myEffects:modify(SanctuaryStrength, core.magic.EFFECT_TYPE.Sanctuary)
    hasIFrames = true

    stopFns["iframes"] = time.runRepeatedly(function()
        if anim.getCompletion(self, currentLegs) then
            async:newUnsavableSimulationTimer(IFramesDuration, function()
                if not stopFns["iframes"] then return end

                if hasIFrames then
                    ui.showMessage("Removing iFrames")
                    myEffects:modify(-SanctuaryStrength, core.magic.EFFECT_TYPE.Sanctuary)
                    hasIFrames = false
                end

                stopFns["iframes"]()

                stopFns["iframes"] = nil
            end)
        end
    end, 0.1)
end

time.runRepeatedly(blockIfPossible, 1)

return {
    engineHandlers = {
        onMouseButtonPress = blockBegin,
        onMouseButtonRelease = blockEnd,
        -- onUpdate = function()

        -- end,
        onFrame = function(_)
            if I.UI.getMode() then
                toggleBlock(false)
                return
            end

            updateMouse()

            -- print(healthObj.current)

            -- BlockDelay = math.max(0., BlockDelay - dt)

            -- CurrentParryDelay = math.max(0., CurrentParryDelay - dt)

            -- print("Block delay: " .. BlockDelay)

            -- If a block delay got assigned, circle back around
            -- And disable blocking state
            -- if BlockDelay > 0. then
            -- toggleBlock(false)
            -- end

            -- You can attack, but it interrupts the block
            if isBlocking and input.getBooleanActionValue("Use") then
                toggleBlock(false)
            end

            -- local currentTorso = anim.getActiveGroup(self, anim.BONE_GROUP.Torso)
            local currentLegs = anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody)
            -- print("Current legs: " .. currentLegs .. " Current torso: " .. currentTorso)

            if (string.find(currentLegs, 'hit') or string.find(currentLegs, 'shield'))
                -- and BlockDelay <= 0.
                and isBlocking then
                if healthObj.current < prevHealth then
                    healthObj.current = prevHealth
                end

                if not hasTimedBonus then
                    beginIFrames(currentLegs)

                    ui.showMessage("Blocking hit")
                else
                    -- CurrentParryDelay = MaxParryDelay
                    -- ui.showMessage("Parry!")
                end
                -- BlockDelay = MaxBlockDelay
            end

            -- Can't block if you're jumping
            if string.find(currentLegs, 'jump') then
                -- print("Disabling block")
                toggleBlock(false)
            end

            prevHealth = healthObj.current
        end,
        -- onInputAction = onInputAction,
    }
}
