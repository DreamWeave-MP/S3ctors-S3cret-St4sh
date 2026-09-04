---@meta
---@omw-context local|player

---Provides full access to the object the script is attached to.
---All fields and function of `openmw.SelfObject` are also available for `openmw.self`.
---local types = require('openmw.types')
---if self.type == types.Player then  -- All fields and functions of `openmw.SelfObject` are available.
---end
---@class openmw.self: openmw.SelfObject
---@field object openmw.LObject The object the script is attached to (readonly)
---@field controls openmw.self.ActorControls Movement controls (only for actors)
---@field ATTACK_TYPE openmw.self.AttackTypeConstants Attack type constants. Use with `controls.use`.
local self = {}

---@alias openmw.self.AttackTypeNoAttack 0
---@alias openmw.self.AttackTypeAny 1
---@alias openmw.self.AttackTypeChop 2
---@alias openmw.self.AttackTypeSlash 3
---@alias openmw.self.AttackTypeThrust 4
---@alias openmw.self.ATTACK_TYPE openmw.self.AttackTypeNoAttack|openmw.self.AttackTypeAny|openmw.self.AttackTypeChop|openmw.self.AttackTypeSlash|openmw.self.AttackTypeThrust

---@class openmw.self.AttackTypeConstants
---@field NoAttack openmw.self.AttackTypeNoAttack
---@field Any openmw.self.AttackTypeAny
---@field Chop openmw.self.AttackTypeChop
---@field Slash openmw.self.AttackTypeSlash
---@field Thrust openmw.self.AttackTypeThrust
local ATTACK_TYPE = {}

---Allows to view and/or modify controls of an actor. All fields are mutable.
---@class openmw.self.ActorControls
---@field movement number +1 - move forward, -1 - move backward
---@field sideMovement number +1 - move right, -1 - move left
---@field yawChange number Turn right (radians); if negative - turn left
---@field pitchChange number Look down (radians); if negative - look up
---@field run boolean true - run, false - walk
---@field sneak boolean If true - sneak
---@field jump boolean If true - initiate a jump
---@field use openmw.self.ATTACK_TYPE Activates the readied weapon/spell according to a provided value. For weapons, keeping this value modified will charge the attack until set to ATTACK_TYPE.NoAttack. If an ATTACK_TYPE not appropriate for a currently equipped weapon provided - an appropriate ATTACK_TYPE will be used instead.
local ActorControls = {}

---Returns true if the script isActive (the object it is attached to is in an active cell).
---If it is not active, then `openmw.nearby` can not be used.
---@return boolean
function self.isActive() end

---The object the script is attached to (readonly)
---@type openmw.LObject
self.object = nil

---Movement controls (only for actors)
---@type openmw.self.ActorControls
self.controls = nil

---@type openmw.self.AttackTypeConstants
self.ATTACK_TYPE = nil

---Enables or disables standard AI (enabled by default).
---@param v boolean
function self.enableAI(v) end

return self
