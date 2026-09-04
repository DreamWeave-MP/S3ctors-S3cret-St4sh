---@meta

---@alias openmw.interfaces.ProjectileTypeMagic "Magic"
---@alias openmw.interfaces.ProjectileTypeWeapon "Weapon"
---@alias openmw.interfaces.ProjectileType openmw.interfaces.ProjectileTypeMagic|openmw.interfaces.ProjectileTypeWeapon

---@class openmw.interfaces.ProjectileTypeValues
---@field Magic openmw.interfaces.ProjectileTypeMagic
---@field Weapon openmw.interfaces.ProjectileTypeWeapon

---@class openmw.interfaces.ProjectileInfo
---@field type openmw.interfaces.ProjectileType
---@field userData any

---@class openmw.interfaces.Projectiles
---@field version number
---@field TYPES openmw.interfaces.ProjectileTypeValues
local Projectiles = {}

---@param type openmw.interfaces.ProjectileType
---@param handler fun(projectile: openmw.interfaces.ProjectileInfo, hitResult: openmw.nearby.RayCastingResult): boolean?
function Projectiles.addOnProjectileHitHandler(type, handler) end

return Projectiles
