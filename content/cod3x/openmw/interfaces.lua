---@meta

---@class openmw.interfaces: table<string, any>
---@class openmw.interfaces.All: openmw.interfaces
---@field Activation openmw.interfaces.Activation Built-in contexts: global.
---@field AnimationController openmw.interfaces.AnimationController Built-in contexts: local|player.
---@field AI openmw.interfaces.AI Built-in contexts: local.
---@field Camera openmw.interfaces.Camera Built-in contexts: player.
---@field Combat openmw.interfaces.Combat Built-in contexts: global|local|player.
---@field MWUI openmw.interfaces.MWUI Built-in contexts: menu|player.
---@field Settings openmw.interfaces.Settings Built-in contexts: global|menu|player.
---@field UI openmw.interfaces.UI Built-in contexts: player.
---@field ItemUsage openmw.interfaces.ItemUsage Built-in contexts: global.
---@field SkillProgression openmw.interfaces.SkillProgression Built-in contexts: player.
---@field Crimes openmw.interfaces.Crimes Built-in contexts: global.
---@field Controls openmw.interfaces.Controls Built-in contexts: player.
---@field GamepadControls openmw.interfaces.GamepadControls Built-in contexts: player.
---@field Projectiles openmw.interfaces.Projectiles Built-in contexts: global.
---@field SpellCasting openmw.interfaces.SpellCasting Built-in contexts: global|local|player.
local interfaces = {}

---@class openmw.interfaces.Global: openmw.interfaces
---@field Activation openmw.interfaces.Activation
---@field Combat openmw.interfaces.Combat.Global
---@field Settings openmw.interfaces.Settings
---@field ItemUsage openmw.interfaces.ItemUsage
---@field Crimes openmw.interfaces.Crimes
---@field Projectiles openmw.interfaces.Projectiles
---@field SpellCasting openmw.interfaces.SpellCasting

---@class openmw.interfaces.Local: openmw.interfaces
---@field AnimationController openmw.interfaces.AnimationController
---@field AI openmw.interfaces.AI
---@field Combat openmw.interfaces.Combat.Local
---@field SpellCasting openmw.interfaces.SpellCasting

---@class openmw.interfaces.Player: openmw.interfaces
---@field AnimationController openmw.interfaces.AnimationController
---@field Combat openmw.interfaces.Combat.Local
---@field Camera openmw.interfaces.Camera
---@field MWUI openmw.interfaces.MWUI
---@field Settings openmw.interfaces.Settings
---@field UI openmw.interfaces.UI
---@field SkillProgression openmw.interfaces.SkillProgression
---@field Controls openmw.interfaces.Controls
---@field GamepadControls openmw.interfaces.GamepadControls
---@field SpellCasting openmw.interfaces.SpellCasting

---@class openmw.interfaces.Menu: openmw.interfaces
---@field MWUI openmw.interfaces.MWUI
---@field Settings openmw.interfaces.Settings

---@param self openmw.interfaces
---@param key string
---@return any
function interfaces.__index(self, key) end

---@return openmw.interfaces.All
return interfaces
