---@meta

---@class openmw.interfaces.ProjectileType
---@field Magic string
---@field Weapon string

---@class openmw.interfaces.ProjectileInfo
---@field type openmw.interfaces.ProjectileType
---@field userData any

---@class openmw.interfaces.Projectiles
---@field version number
---@field TYPES openmw.interfaces.ProjectileType
local Projectiles = {}

---@param type string
---@param handler fun(projectile: openmw.interfaces.ProjectileInfo, hitResult: openmw.nearby.RayCastingResult): boolean?
function Projectiles.addOnProjectileHitHandler(type, handler) end

return Projectiles
