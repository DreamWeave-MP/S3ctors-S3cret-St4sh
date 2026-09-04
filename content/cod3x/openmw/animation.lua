---@meta
---@omw-context local|player

---Defines functions that allow control of character animations.
---Note that for some methods, such as openmw.animation.playBlended you should use the associated methods on the
---[AnimationController](interface_animation.html) interface rather than invoking this API directly.
---@class openmw.animation
local animation = {}

---`animation.PRIORITY`
---@alias openmw.animation.PriorityDefault 0
---@alias openmw.animation.PriorityWeaponLowerBody 1
---@alias openmw.animation.PrioritySneakIdleLowerBody 2
---@alias openmw.animation.PrioritySwimIdle 3
---@alias openmw.animation.PriorityJump 4
---@alias openmw.animation.PriorityMovement 5
---@alias openmw.animation.PriorityHit 6
---@alias openmw.animation.PriorityWeapon 7
---@alias openmw.animation.PriorityBlock 8
---@alias openmw.animation.PriorityKnockdown 9
---@alias openmw.animation.PriorityTorch 10
---@alias openmw.animation.PriorityStorm 11
---@alias openmw.animation.PriorityDeath 12
---@alias openmw.animation.PriorityScripted 13
---@alias openmw.animation.Priority openmw.animation.PriorityDefault|openmw.animation.PriorityWeaponLowerBody|openmw.animation.PrioritySneakIdleLowerBody|openmw.animation.PrioritySwimIdle|openmw.animation.PriorityJump|openmw.animation.PriorityMovement|openmw.animation.PriorityHit|openmw.animation.PriorityWeapon|openmw.animation.PriorityBlock|openmw.animation.PriorityKnockdown|openmw.animation.PriorityTorch|openmw.animation.PriorityStorm|openmw.animation.PriorityDeath|openmw.animation.PriorityScripted

---@class openmw.animation.PriorityValues
---@field Default openmw.animation.PriorityDefault
---@field WeaponLowerBody openmw.animation.PriorityWeaponLowerBody
---@field SneakIdleLowerBody openmw.animation.PrioritySneakIdleLowerBody
---@field SwimIdle openmw.animation.PrioritySwimIdle
---@field Jump openmw.animation.PriorityJump
---@field Movement openmw.animation.PriorityMovement
---@field Hit openmw.animation.PriorityHit
---@field Weapon openmw.animation.PriorityWeapon
---@field Block openmw.animation.PriorityBlock
---@field Knockdown openmw.animation.PriorityKnockdown
---@field Torch openmw.animation.PriorityTorch
---@field Storm openmw.animation.PriorityStorm
---@field Death openmw.animation.PriorityDeath
---@field Scripted openmw.animation.PriorityScripted Special priority used by scripted animations. When any animation with this priority is present, all animations without this priority are paused.
local Priority = {}

---`animation.BLEND_MASK`
---@alias openmw.animation.BlendMaskLowerBody 1
---@alias openmw.animation.BlendMaskTorso 2
---@alias openmw.animation.BlendMaskLeftArm 4
---@alias openmw.animation.BlendMaskRightArm 8
---@alias openmw.animation.BlendMaskUpperBody 14
---@alias openmw.animation.BlendMaskAll 15
---@alias openmw.animation.BlendMask openmw.animation.BlendMaskLowerBody|openmw.animation.BlendMaskTorso|openmw.animation.BlendMaskLeftArm|openmw.animation.BlendMaskRightArm|openmw.animation.BlendMaskUpperBody|openmw.animation.BlendMaskAll
---@class openmw.animation.BlendMaskValues
---@field LowerBody openmw.animation.BlendMaskLowerBody
---@field Torso openmw.animation.BlendMaskTorso
---@field LeftArm openmw.animation.BlendMaskLeftArm
---@field RightArm openmw.animation.BlendMaskRightArm
---@field UpperBody openmw.animation.BlendMaskUpperBody
---@field All openmw.animation.BlendMaskAll
local BlendMask = {}

---`animation.BONE_GROUP`
---@alias openmw.animation.BoneGroupLowerBody 0
---@alias openmw.animation.BoneGroupTorso 1
---@alias openmw.animation.BoneGroupLeftArm 2
---@alias openmw.animation.BoneGroupRightArm 3
---@alias openmw.animation.BoneGroup openmw.animation.BoneGroupLowerBody|openmw.animation.BoneGroupTorso|openmw.animation.BoneGroupLeftArm|openmw.animation.BoneGroupRightArm
---@class openmw.animation.BoneGroupValues
---@field LowerBody openmw.animation.BoneGroupLowerBody
---@field Torso openmw.animation.BoneGroupTorso
---@field LeftArm openmw.animation.BoneGroupLeftArm
---@field RightArm openmw.animation.BoneGroupRightArm
local BoneGroup = {}

---Possible Priority values
---@type openmw.animation.PriorityValues
animation.PRIORITY = nil

---Possible BlendMask values
---@type openmw.animation.BlendMaskValues
animation.BLEND_MASK = nil

---Possible BoneGroup values
---@type openmw.animation.BoneGroupValues
animation.BONE_GROUP = nil

---Check if the object has an animation object or not
---@param actor openmw.Object
---@return boolean
function animation.hasAnimation(actor) end

---Skips animations for one frame, equivalent to mwscript's SkipAnim.
---Can only be used on self.
---@param actor openmw.SelfObject
function animation.skipAnimationThisFrame(actor) end

---Get the absolute position within the animation track of the given text key
---@param actor openmw.Object
---@param text string key
---@return number|nil
function animation.getTextKeyTime(actor, text) end

---Check if the given animation group is currently playing
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.isPlaying(actor, groupName) end

---Get the current absolute time of the given animation group if it is playing, or -1 if it is not playing.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getCurrentTime(actor, groupName) end

---Check whether the animation is a looping animation or not. This is determined by a combination
---of groupName, some of which are hardcoded to be looping, and the presence of loop start/stop keys.
---The groupNames that are hardcoded as looping are the following, as well as per-weapon-type suffixed variants of each.
---"walkforward", "walkback", "walkleft", "walkright", "swimwalkforward", "swimwalkback", "swimwalkleft", "swimwalkright",
---"runforward", "runback", "runleft", "runright", "swimrunforward", "swimrunback", "swimrunleft", "swimrunright",
---"sneakforward", "sneakback", "sneakleft", "sneakright", "turnleft", "turnright", "swimturnleft", "swimturnright",
---"spellturnleft", "spellturnright", "torch", "idle", "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8",
---"idle9", "idlesneak", "idlestorm", "idleswim", "jump", "inventoryhandtohand", "inventoryweapononehand",
---"inventoryweapontwohand", "inventoryweapontwowide"
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.isLoopingAnimation(actor, groupName) end

---Cancels and removes the animation group from the list of active animations.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
function animation.cancel(actor, groupName) end

---Enables or disables looping for the given animation group. Looping is enabled by default.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param enabled boolean
function animation.setLoopingEnabled(actor, groupName, enabled) end

---Returns the completion of the animation, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getCompletion(actor, groupName) end

---Returns the remaining number of loops, not counting the current loop, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getLoopCount(actor, groupName) end

---Get the current playback speed of an animation group, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getSpeed(actor, groupName) end

---Modifies the playback speed of an animation group.
---Note that this is not sticky and only affects the speed until the currently playing sequence ends.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param speed number The new animation speed, where speed=1 is normal speed.
function animation.setSpeed(actor, groupName, speed) end

---Clears all animations currently in the animation queue. This affects animations played by mwscript, openmw.animation.playQueued, and ai packages, but does not affect animations played using openmw.animation.playBlended.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param clearScripted boolean whether to keep animation with priority Scripted or not.
function animation.clearAnimationQueue(actor, clearScripted) end

---Acts as a slightly extended version of MWScript's LoopGroup. Plays this animation exclusively
---until it ends, or the queue is cleared using #clearAnimationQueue. Use #clearAnimationQueue and the `startkey` option
---to imitate the behavior of LoopGroup's play modes.
---Can only be used on self.
---anim.clearAnimationQueue(self, false)
---anim.playQueued(self, 'death1')
---anim.clearAnimationQueue(self, false)
---anim.playQueued(self, 'spellcast', { startKey = 'self start', stopKey = 'self stop' })
---@param actor openmw.SelfObject
---@param groupName string
---@param options table A table of play options.  Can contain: * `loops` - a number >= 0, the number of times the animation should loop after the first play (default: infinite). * `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1); * `startKey` - the animation key at which the animation should start (default: "start") * `stopKey` - the animation key at which the animation should end (default: "stop") * `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)
function animation.playQueued(actor, groupName, options) end

---Play an animation directly. You probably want to use the [AnimationController](interface_animation.html) interface, which will trigger relevant handlers,
---instead of calling this directly. Note that the still hardcoded character controller may at any time and for any reason alter
---or cancel currently playing animations, so making your own calls to this function either directly or through the [AnimationController](interface_animation.html)
---interface may be of limited utility. For now, use openmw.animation#playQueued to script your own animations.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param options table A table of play options. Can contain: * `loops` - a number >= 0, the number of times the animation should loop after the first play (default: 0). * `priority` - Either a single #Priority value that will be assigned to all bone groups. Or a table mapping bone groups to its priority (default: PRIORITY.Default). * `blendMask` - A mask of which bone groups to include in the animation (Default: BLEND_MASK.All). * `autoDisable` - If true, the animation will be immediately  removed upon finishing, which means information will not be possible to query once completed. (Default: true) * `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1) * `startKey` - the animation key at which the animation should start (default: "start") * `stopKey` - the animation key at which the animation should end (default: "stop") * `startPoint` - a floating point number 0 <= value <= 1, starting completion of the animation (default: 0) * `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)
function animation.playBlended(actor, groupName, options) end

---Adds a spell-cast glow to the actor.
---@param actor openmw.SelfObject
---@param options table Options containing `color` and `duration`.
function animation.addGlow(actor, options) end

---Check if the actor's animation has the given animation group or not.
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.hasGroup(actor, groupName) end

---Check if the actor's skeleton has the given bone or not
---@param actor openmw.Object
---@param boneName string
---@return boolean
function animation.hasBone(actor, boneName) end

---Get the current active animation for a bone group
---@param actor openmw.Object
---@param boneGroup openmw.animation.BoneGroup Bone group enum, see openmw.animation.BONE_GROUP
---@return string
function animation.getActiveGroup(actor, boneGroup) end

---Plays a VFX on the actor.
---Can only be used on self. Can also be evoked by sending an AddVfx event to the target actor.
---anim.addVfx(self, 'VFX_Hands', {boneName = 'Bip01 L Hand', particleTextureOverride = mgef.particle, loop = mgef.continuousVfx, vfxId = mgef.id..'_myuniquenamehere'})
----- later:
---anim.removeVfx(self, mgef.id..'_myuniquenamehere')
---local mgef = core.magic.effects.records[myEffectName]
---target:sendEvent('AddVfx', {
---})
---@param actor openmw.SelfObject
---@param model string path (normally taken from a record such as openmw.types.StaticRecord.model or similar)
---@param options? table optional table of parameters. Can contain: * `loop` - boolean, if true the effect will loop until removed (default: false). * `boneName` - name of the bone to attach the vfx to. (default: "") * `particleTextureOverride` - name of the particle texture to use. (default: "") * `vfxId` - a string ID that can be used to remove the effect later, using #removeVfx, and to avoid duplicate effects. The default value of "" can have duplicates. To avoid interaction with the engine, use unique identifiers unrelated to magic effect IDs. The engine uses this identifier to add and remove magic effects based on what effects are active on the actor. If this is set equal to the openmw.core.MagicEffectId identifier of the magic effect being added, for example core.magic.EFFECT_TYPE.FireDamage, then the engine will remove it once the fire damage effect on the actor reaches 0. (Default: ""). * `useAmbientLight` - boolean, vfx get a white ambient light attached in Morrowind. If false don't attach this. (default: true) * `autoTransform` - boolean, if true, the engine will auto-calculate the transform. (default: true) * `transform` - openmw.util.Transform relative transform applied to the vfx. If autoTransform is true this is applied on top of it.
function animation.addVfx(actor, model, options) end

---Removes a specific VFX.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param vfxId string a string ID that uniquely identifies the VFX to remove
function animation.removeVfx(actor, vfxId) end

---Removes all vfx from the actor.
---Can only be used on self.
---@param actor openmw.SelfObject
function animation.removeAllVfx(actor) end

return animation
